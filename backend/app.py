import ast
import io
import os
from datetime import datetime, timedelta
from PIL import Image

import numpy as np
from settings import get_config
from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_jwt_extended import (
    JWTManager,
    create_access_token,
    create_refresh_token,
    get_jwt_identity,
    jwt_required,
)
from services.cluster_service import ClusterService
from services.db_service import DatabaseService
from services.face_service import FaceService
from services.password_service import PasswordServive
from firebase_admin import messaging

app = Flask(__name__)
CORS(app)
# FLASK SETUP
config = get_config()
app.config.from_object(config)
jwt = JWTManager(app)

cluster_service = ClusterService(config)
database_service = DatabaseService(config)
face_service = FaceService(config)
password_service = PasswordServive()


# ROUTES
@app.route("/api/v1/login", methods=["POST"])
def login():
    username = request.json.get("username", None)
    password = request.json.get("password", None)

    enc_password = database_service.get_pwd_hash(username)
    if not password_service.verify_password(password, enc_password):
        return jsonify({"msg": "Bad username or password"}), 401

    uid = str(database_service.get_uid(username))
    access_token = create_access_token(identity=uid)
    refresh_token = create_refresh_token(identity=uid)
    return jsonify(access_token=access_token, refresh_token=refresh_token)


@app.route("/api/v1/register", methods=["POST"])
def register():
    username = request.json.get("username", None)
    password = request.json.get("password", None)
    firebase_token = request.json.get("firebaes_token", None)

    if database_service.check_user_taken(username):
        return jsonify({"msg": "Username already taken"}), 401

    uid = database_service.create_user(
        username, password_service.hash_password(password), firebase_token
    )
    access_token = create_access_token(identity=uid)
    refresh_token = create_refresh_token(identity=uid)
    return jsonify(access_token=access_token, refresh_token=refresh_token)


# TODO: Rename to refresh JWT token or something
@app.route("/api/v1/refresh", methods=["POST"])
@jwt_required(refresh=True)
def refresh():
    identity = get_jwt_identity()
    access_token = create_access_token(identity=identity)
    return jsonify(access_token=access_token)


@app.route("/api/v1/test_upload", methods=["POST"])
def test_upload_image():
    """
    Let's user submit an image. This is NOT for production, and is just
    for testing the bluetooth device and seeing if it works.
    """
    img_data = request.data
    upload_folder = "test_img_folder"
    filename = f"test_upload_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"

    os.makedirs(upload_folder, exist_ok=True)
    file_path = os.path.join(upload_folder, filename)
    with open(file_path, "wb") as f:
        f.write(img_data)

    return jsonify({"message": "File uploaded successfully", "filename": filename}), 200


@app.route("/api/v1/upload_image", methods=["POST"])
@jwt_required()
def upload_image():
    """
    Submits an image for the AI people to do their thing
    NOTE: Whatever gets sent back doesn't matter since ESP32 isn't taking

    TODO: This also needs to send notifs if long enough time has elapsed

    1. Get all face embeddings
    2. Check against contacts & make see if any are known
        2.1 Notify any that aren't on cooldown
        2.2 Update last_seen time for all contacts
    3. For all unknown, add to the temp_embed table
    """
    user_id = get_jwt_identity()

    # We should use stream for less overhead & make it easier
    img_data = io.BytesIO(request.data)

    try:
        img = Image.open(img_data)
    except Exception as e:
        return jsonify({"error": "Invalid image stream"}), 400

    img = img.convert("RGB")
    frame = np.array(img)

    face_embeds = face_service.get_face_embeds(frame)
    user_fb_token = database_service.get_firebase_token(user_id)
    print(user_fb_token)

    # NOTE: Change this to just notify of the person in the middle of the frame
    # TODO: cid becomes a useless thing to save
    for embed in face_embeds:
        # Check against all contacts
        closest_match = database_service.pull_closest_contact(user_id, embed.tolist())
        if not closest_match:
            # For all unknown, add to loose embeds
            database_service.add_loose_embedding(user_id, embed.tolist())
            continue

        # print(closest_match)
        # print(f"Found contact {closest_match['name']}, {closest_match['last_seen']}")

        time_since_last_seen = datetime.now().astimezone() - closest_match["last_seen"]
        # print(time_since_last_seen)
        if user_fb_token is not None and time_since_last_seen > config.NOTIF_COOLDOWN:
            # print(f"hi, should send notif for {closest_match['name']}")
            # Notify with cloudflare
            msg = messaging.Message(
                notification=messaging.Notification(
                    title="Contact found!",
                    body=f"You have just looked at {closest_match['name']}",
                ),
                token=user_fb_token,
            )
            response = messaging.send(msg)
            print("Successfully sent msg:", response)

        # Always set last seen
        database_service.update_last_seen(user_id, closest_match["cid"])

    return jsonify({"message": "Image uploaded successfully"}), 200


@app.route("/api/v1/pull_contacts", methods=["GET"])
@jwt_required()
def pull_contacts():
    uid = get_jwt_identity()
    print(f"Currently logged in as {uid}")

    contacts = database_service.get_contacts(uid)
    print(f"Got contacts {contacts}")

    return jsonify(contacts), 200


# TIM'S WORKSHOP
@app.route("/api/v1/test_notify", methods=["GET"])
def test_notify():
    msg = messaging.Message(
        notification=messaging.Notification(
            title="Test Notification", body="You have successfully pinged the server!"
        ),
        token="<device_token>",
    )
    response = messaging.send(msg)
    print("Successfully sent msg:", response)


# Not sure which is more technically correct... Ivy?
@app.route("/api/v1/test_notify_v2", methods=["GET"])
def test_notify_v2():
    message = messaging.Message(
        data={
            "status": "1",
        },
        token="registration_token",
    )
    response = messaging.send(message)
    print("Succesffuly sent message:", response)


# END OF TIM'S WORKSHOP


# TODO: Maybe change name
@app.route("/api/v1/create_contact", methods=["POST"])
@jwt_required()
def create_contact():
    """
    1. Get the cluster ID
    2. Pull all embeds with ID
    3. Average them
    4. Store in contact with name (this should also be passed)
    5. Remove embeds from the temp table
    """
    user_id = get_jwt_identity()
    req_data = request.get_json()

    if not req_data or "cluster_id" not in req_data or "contact_name" not in req_data:
        return jsonify({"error": "Missing required parameters"}), 400

    cluster_id = req_data["cluster_id"]
    contact_name = req_data["contact_name"]
    cluster_embeds = database_service.pull_single_cluster(user_id, cluster_id)
    cluster_embeds = [ast.literal_eval(embed_str) for embed_str in cluster_embeds]

    if not cluster_embeds:
        return jsonify({"error": "Cluster not found"}), 404
    avg_embed = np.mean(cluster_embeds, axis=0)
    # Store new contact with name
    success = database_service.create_contact(
        uid=user_id, name=contact_name, embedding=avg_embed.tolist()
    )

    # Fail if db failed
    if not success:
        return jsonify({"error": "Failed to create contact"}), 500

    # Clean up, remove the cluster, and return
    if not database_service.remove_single_cluster(user_id, cluster_id):
        return jsonify({"error": "Contact created but failed to clean up cluster"}), 500

    return (
        jsonify(
            {"message": "Contact created successfully", "contact_name": contact_name}
        ),
        200,
    )


@app.route("/api/v1/pull_timeline", methods=["GET"])
@jwt_required()
def pull_timeline():
    """
    1. Clean up temps (anything older than some config value)
    2. Go through temp embeds for user & run DBSCAN on vectors
    3. Store cluster IDs for each embed
    4. Return valid clusters to user

    returns: {
        {
            id1: [TIMESTAMPS],
            id2: [TIMESTAMPS],
        {
    }
    """
    user_id = get_jwt_identity()

    database_service.cleanup_old_embeddings(user_id)
    temp_embeds = database_service.pull_temp_embeds(user_id)
    # TODO: MOVE THIS TO DB SERVICE
    embeds = [ast.literal_eval(embed_str) for embed_str in temp_embeds]
    embeds_array = np.array(embeds)
    cluster_ids = cluster_service.get_clusters(embeds_array)
    database_service.save_cluster_ids(user_id, cluster_ids.tolist())

    res = database_service.pull_clusters(user_id)
    return res


@app.route("/api/v1/edit_contact", methods=["PATCH"])
@jwt_required()
def edit_contact():
    uid = get_jwt_identity()
    req_params = request.get_json()

    res = database_service.update_contact(uid, req_params)
    if res:
        return jsonify({"message": "Updated successfully"}), 200
    return jsonify({"error": "Contact not updated successfully"}), 404


@app.route("/api/v1/delete_contact/<cid>", methods=["DELETE"])
@jwt_required()
def delete_contact(cid):
    uid = get_jwt_identity()
    res = database_service.delete_contact(uid, cid)
    if res:
        return jsonify({"message": "Contact deleted successfully"}), 200

    return jsonify({"error": "Contact not found or could not be deleted"}), 404


@app.route("/")
def hello():
    return "<h1 style='color:blue'>Visionbuzz!</h1>"


if __name__ == "__main__":
    app.run(host="0.0.0.0")

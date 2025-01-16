import io
import os
from datetime import datetime, timedelta
from PIL import Image

import cv2
import numpy as np
from settings import get_config
from flask import Flask, jsonify, request
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

    uid = database_service.get_uid(username)
    access_token = create_access_token(identity=uid)
    refresh_token = create_refresh_token(identity=uid)
    return jsonify(access_token=access_token, refresh_token=refresh_token)


@app.route("/api/v1/register", methods=["POST"])
def register():
    username = request.json.get("username", None)
    password = request.json.get("password", None)

    if database_service.check_user_taken(username):
        return jsonify({"msg": "Username already taken"}), 401

    uid = database_service.create_user(
        username, password_service.hash_password(password)
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


# TODO: THIS DOESN"T WORK THE IMAGES ARE WONK FIX THIS PLEASSE IVY
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


# TODO: Should move almost all this logic into face_service
# TODO: Should fully take the image and do all the things (IVY: taking a break, work for later)
@app.route("/api/v1/upload_image", methods=["POST"])
@jwt_required()
def upload_image():
    """
    Submits an image for the AI people to do their thing
    NOTE: Whatever gets sent back doesn't matter since ESP32 isn't taking

    TODO: NEW FLOW

    1. Get all face embeddings
    2. Check against contacts & make see if any are known
        2.1 Notify any that aren't on cooldown
        2.2 Update last_seen time for all contacts
    3. For all unknown, add to the temp_embed table
    NOTE: DONT NEED CLUSTERSERVICE HERE JUST ADD IT TO THE DABATABTE
    """
    user_id = get_jwt_identity()
    # user_id = "test_user_id"

    # TODO: WE SHOULD USE STREAM FOR LESS OVERHEAD & MAKE IT EASIER
    img_data = io.BytesIO(request.data)

    if "image" not in request.files:
        return jsonify({"error": "No image file provided"}), 400

    file = request.files["image"]
    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    try:
        img = Image.open(file.stream)
    except Exception as e:
        return jsonify({"error": "Invalid image file"}), 400

    if img.mode != "RGB":
        img = img.convert("RGB")

    np_image = np.array(img)
    frame = cv2.cvtColor(np_image, cv2.COLOR_RGB2BGR)
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    known_face_encodings, known_face_names = face_service.get_user_face_data(user_id)
    name = request.form.get("name", "")

    if name:
        face_encoding, error = face_service.detect_and_encode_face(rgb_frame)
        if error:
            return jsonify({"error": error}), 400

        known_face_encodings.append(face_encoding)
        known_face_names.append(name)
        face_service.set_user_face_data(user_id, known_face_encodings, known_face_names)
        return jsonify({"message": f"Face encoding for {name} saved."}), 200
    else:
        labels = face_service.recognize_faces_per_user(
            rgb_frame, known_face_encodings, known_face_names
        )
        response = ", ".join(labels) if labels else "No faces detected."
        return jsonify({"message": response}), 200


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
    cluster_id = None  # TODO
    contact_name = None  # TODO, get from request
    cluster_embeds = database_service.pull_single_cluster(user_id, cluster_id)
    avg_embed = None  # TODO
    res = database_service.remove_single_cluster(user_id, cluster_id)
    # TODO: Store new contact with name
    # TODO: fail if db failed
    # TODO: Return success


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
    temp_embeds = database_service.pull_temp_embeds(user_id)
    cluster_ids = cluster_service.get_clusters(temp_embeds)
    database_service.save_cluster_ids(user_id, cluster_ids)

    # TODO: hadnwayvd magic to get nice return format
    res = None
    # IVY NOTE: USE A GROUP BY WITH MINIMIM SIZE REQUIREMENT AND THEN JUST AUTOMATICALLY ASSIGN IT TO BE ID TO LAST SEEN TIMES
    # IVY NOTE: Pull all groups, filter by group size, return id: [timestamps]
    # IVY NOTE: IGNORE -1
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

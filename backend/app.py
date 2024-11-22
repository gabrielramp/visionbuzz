import hashlib
import hmac
import io
import os
import pickle
from datetime import datetime, timedelta
from PIL import Image

import cv2
import dlib
import numpy as np
from argon2 import PasswordHasher
from dotenv import load_dotenv  # Added import for dotenv
from flask import Flask, jsonify, request
from flask_jwt_extended import (JWTManager, create_access_token,
                                create_refresh_token, get_jwt_identity,
                                jwt_required)

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)

# FLASK SETUP
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
if not JWT_SECRET_KEY:
    raise ValueError("No JWT_SECRET_KEY set for Flask application")  # Error handling

app.config["JWT_SECRET_KEY"] = JWT_SECRET_KEY
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = timedelta(hours=1)
app.config["JWT_REFRESH_TOKEN_EXPIRES"] = timedelta(days=30)
jwt = JWTManager(app)

ph = PasswordHasher()

# Facial recognition initialization
# Paths to the model files
shape_predictor_path = os.getenv("SHAPE_PREDICTOR_PATH", "shape_predictor_68_face_landmarks.dat")
face_rec_model_path = os.getenv("FACE_REC_MODEL_PATH", "dlib_face_recognition_resnet_model_v1.dat")

detector = dlib.get_frontal_face_detector()
sp = dlib.shape_predictor(shape_predictor_path)
facerec = dlib.face_recognition_model_v1(face_rec_model_path)

# Data directory and file
data_path = 'facialdata'
if not os.path.exists(data_path):
    os.makedirs(data_path)
data_file = os.path.join(data_path, 'face_encodings.pkl')

# Load known faces per user
if os.path.isfile(data_file):
    with open(data_file, 'rb') as f:
        user_face_data = pickle.load(f)
else:
    user_face_data = {}

# Helper functions for face data
def save_faces():
    with open(data_file, 'wb') as f:
        pickle.dump(user_face_data, f)

def get_user_face_data(user_id):
    if user_id not in user_face_data:
        user_face_data[user_id] = ([], [])
    return user_face_data[user_id]

def set_user_face_data(user_id, encodings, names):
    user_face_data[user_id] = (encodings, names)
    save_faces()

def recognize_faces_per_user(rgb_frame, known_face_encodings, known_face_names):
    labels = []
    faces = detector(rgb_frame, 0)
    for face in faces:
        shape = sp(rgb_frame, face)
        face_descriptor = facerec.compute_face_descriptor(rgb_frame, shape)
        current_face_encoding = np.array(face_descriptor)

        # Attempt to match face with known faces
        if known_face_encodings:
            distances = np.linalg.norm(known_face_encodings - current_face_encoding, axis=1)
            min_distance = np.min(distances)
            if min_distance < 0.6:
                index = np.argmin(distances)
                labels.append(known_face_names[index])
            else:
                labels.append("Unknown")
        else:
            labels.append("Unknown")
    return labels

# HELPER FUNCTIONS
def secure_password(pwd: str) -> str:
    enc_pwd = ph.hash(pwd)
    return enc_pwd

def check_password(pwd: str, enc_pwd: str) -> bool:
    try:
        return ph.verify(enc_pwd, pwd)
    except Exception:
        return False

# ROUTES
@app.route("/api/v1/login", methods=["POST"])
def login():
    username = request.json.get("username", None)
    password = request.json.get("password", None)

    enc_password = db_get_pwd_hash(username)
    if not check_password(password, enc_password):
        return jsonify({"msg": "Bad username or password"}), 401

    uid = db_get_uid(username)
    access_token = create_access_token(identity=uid)
    refresh_token = create_refresh_token(identity=uid)
    return jsonify(access_token=access_token, refresh_token=refresh_token)

@app.route("/api/v1/register", methods=["POST"])
def register():
    username = request.json.get("username", None)
    password = request.json.get("password", None)

    if db_check_user_taken(username):
        return jsonify({"msg": "Username already taken"}), 401

    uid = db_create_user(username, secure_password(password))
    access_token = create_access_token(identity=uid)
    refresh_token = create_refresh_token(identity=uid)
    return jsonify(access_token=access_token, refresh_token=refresh_token)

@app.route("/api/v1/refresh", methods=["POST"])
@jwt_required(refresh=True)
def refresh():
    identity = get_jwt_identity()
    access_token = create_access_token(identity=identity)
    return jsonify(access_token=access_token)

@app.route("/api/v1/test_upload", methods=["POST"])
def test_upload_image():
    img_data = request.data
    upload_folder = "test_img_folder"
    filename = f"test_upload_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"

    os.makedirs(upload_folder, exist_ok=True)
    file_path = os.path.join(upload_folder, filename)
    with open(file_path, "wb") as f:
        f.write(img_data)

    return jsonify({"message": "File uploaded successfully", "filename": filename}), 200

@app.route("/api/v1/upload_image", methods=["POST"])
# @jwt_required()
def upload_image():
    # TODO: Use arbitrary user
    # user_id = get_jwt_identity()
    user_id = 'test_user_id'
    known_face_encodings, known_face_names = get_user_face_data(user_id)

    if 'image' not in request.files:
        return jsonify({"error": "No image file provided"}), 400

    file = request.files['image']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    try:
        img = Image.open(file.stream)
    except Exception as e:
        return jsonify({"error": "Invalid image file"}), 400

    if img.mode != 'RGB':
        img = img.convert('RGB')

    np_image = np.array(img)

    frame = cv2.cvtColor(np_image, cv2.COLOR_RGB2BGR)
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    name = request.form.get('name', '')

    if name:
        # The client wants to save this face with the given name
        faces = detector(rgb_frame, 0)
        if len(faces) == 0:
            return jsonify({"error": "No face detected in the image"}), 400
        elif len(faces) > 1:
            return jsonify({"error": "Multiple faces detected. Please upload an image with a single face"}), 400

        face = faces[0]
        shape = sp(rgb_frame, face)
        face_descriptor = facerec.compute_face_descriptor(rgb_frame, shape)
        current_face_encoding = np.array(face_descriptor)
        known_face_encodings.append(current_face_encoding)
        known_face_names.append(name)
        set_user_face_data(user_id, known_face_encodings, known_face_names)
        response = f"Face encoding for {name} saved."
        return jsonify({"message": response}), 200

    else:
        labels = recognize_faces_per_user(rgb_frame, known_face_encodings, known_face_names)
        if labels:
            response = ", ".join(labels)
        else:
            response = "No faces detected."
        return jsonify({"message": response}), 200

@app.route("/api/v1/pull_contacts", methods=["GET"])
@jwt_required()
def pull_contacts():
    uid = get_jwt_identity()
    print(f"Currently logged in as {uid}")

    contacts = db_get_contacts(uid)
    print(f"Got contacts {contacts}")

    return jsonify(contacts), 200

@app.route("/api/v1/edit_contact", methods=["PATCH"])
@jwt_required()
def edit_contact():
    uid = get_jwt_identity()
    req_params = request.get_json()

    res = db_update_contact(uid, req_params)
    if res:
        return jsonify({"message": "Updated successfully"}), 200
    return jsonify({"error": "Contact not updated successfully"}), 404

@app.route("/api/v1/delete_contact/<cid>", methods=["DELETE"])
@jwt_required()
def delete_contact(cid):
    uid = get_jwt_identity()
    res = db_delete_contact(uid, cid)
    if res:
        return jsonify({"message": "Contact deleted successfully"}), 200

    return jsonify({"error": "Contact not found or could not be deleted"}), 404

@app.route("/")
def hello():
    return "<h1 style='color:blue'>Visionbuzz!</h1>"

if __name__ == "__main__":
    app.run(host='0.0.0.0')

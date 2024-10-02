import hashlib
import hmac
import os

from datetime import datetime, timedelta
from argon2 import PasswordHasher

from flask import Flask
from flask import request
from flask import jsonify

from flask_jwt_extended import create_access_token
from flask_jwt_extended import create_refresh_token
from flask_jwt_extended import get_jwt_identity
from flask_jwt_extended import jwt_required
from flask_jwt_extended import JWTManager

from config import JWT_SECRET_KEY, PASSWORD_PEPPER

from utils.db import db_check_user_taken, db_create_user, db_get_pwd_hash

app = Flask(__name__)

### FLASK SETUP ###
app.config["JWT_SECRET_KEY"] = JWT_SECRET_KEY
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = timedelta(hours=1)
app.config["JWT_REFRESH_TOKEN_EXPIRES"] = timedelta(days=30)
jwt = JWTManager(app)

ph = PasswordHasher()


### HELPER FUNCTIONS ###


def secure_password(pwd: str) -> str:
    enc_pwd = ph.hash(pwd)
    return enc_pwd


def check_password(pwd: str, enc_pwd: str) -> str:
    try:
        return ph.verify(enc_pwd, pwd)
    except Exception:
        return False


### ROUTES ###


@app.route("/api/v1/login", methods=["POST"])
def login():
    username = request.json.get("username", None)
    password = request.json.get("password", None)

    enc_password = db_get_pwd_hash(username)
    print(password, enc_password)
    if not check_password(password, enc_password):
        return jsonify({"msg": "Bad username or password"}), 401

    access_token = create_access_token(identity=username)
    refresh_token = create_refresh_token(identity=username)
    return jsonify(access_token=access_token, refresh_token=refresh_token)


@app.route("/api/v1/register", methods=["POST"])
def register():
    username = request.json.get("username", None)
    password = request.json.get("password", None)

    if db_check_user_taken(username):
        return jsonify({"msg": "Username already taken"}), 401

    db_create_user(username, secure_password(password))
    access_token = create_access_token(identity=username)
    refresh_token = create_refresh_token(identity=username)
    return jsonify(access_token=access_token, refresh_token=refresh_token)


@app.route("/api/v1/refresh", methods=["POST"])
@jwt_required(refresh=True)
def refresh():
    identity = get_jwt_identity()
    access_token = create_access_token(identity=identity)
    return jsonify(access_token=access_token)


@app.route("/api/v1/pull_contacts", methods=["GET"])
@jwt_required()
def pull_contacts():
    # Access the identity of the current user with get_jwt_identity
    # TODO: Finish this with real database
    current_user = get_jwt_identity()
    print(f"Currently logged in as {current_user}")
    return jsonify(users={"a": "a"}), 200


@app.route("/api/v1/test_upload", methods=["POST"])
def test_upload_image():
    """
    Let's user submit an image. This is NOT for production, and is just
    for testing the bluetooth device and seeing if it works.
    """
    file = request.files["image"].read()
    upload_folder = "test_img_folder"
    filename = f"test_upload_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"

    os.makedirs(upload_folder, exist_ok=True)
    file_path = os.path.join(upload_folder, filename)
    with open(file_path, "wb") as f:
        f.write(file)

    return jsonify({"message": "File uploaded successfully", "filename": filename}), 200


@app.route("/api/v1/upload_image", methods=["POST"])
def upload_image():
    """
    Submits an image for the AI people to do their thing
    TODO: Don't send request number cause this is just gonna bounce back from
          the mini hardware device
    """
    file = request.files["image"].read()

    # NOTE: file is in raw byte form, but sould be JPG
    return jsonify({"message": "Image sent successfully"}), 200


@app.route("/api/v1/edit_contact", methods=["PATCH"])
def edit_contact():
    return


@app.route("/api/v1/delete_contact", methods=["DELETE"])
def delete_contact():
    return


# TODO: Testing code to run server locally

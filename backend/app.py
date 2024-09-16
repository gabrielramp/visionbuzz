from flask import Flask
from flask import request
from flask import jsonify

from flask_jwt_extended import create_access_token
from flask_jwt_extended import get_jwt_identity
from flask_jwt_extended import jwt_required
from flask_jwt_extended import JWTManager

from config import JWT_SECRET_KEY

app = Flask(__name__)

# App setup
app.config["JWT_SECRET_KEY"] = JWT_SECRET_KEY
jwt = JWTManager(app)


@app.route('/api/v1/login', methods=['POST'])
def login():
    username = request.json.get('username', None)
    password = request.json.get('password', None)

    # TODO: Obviously you need to replace this with datbase stuff
    if username != 'test' or password != 'test':
        return jsonify({'msg': 'Bad username or password'}), 401
    access_token = create_access_token(identity=username)
    return jsonify(access_token=access_token)


@app.route('/api/v1/register', methods=['POST'])
def register():
    username = request.json.get('username', None)
    password = request.json.get('password', None)

    # TODO: Obviously you need to replace this check with real DB check
    if username == 'test':
        return jsonify({'msg': 'Username already taken'}), 401

    # TODO: Save user to database here with hashed password
    access_token = create_access_token(identity=username)
    return jsonify(access_token=access_token)


@app.route('/api/v1/pull_contacts', methods=['GET'])
def pull_contacts():
    return


@app.route('/api/v1/upload_image', methods=['POST'])
def upload_image():
    return


@app.route('/api/v1/edit_contact', methods=['PATCH'])
def edit_contact():
    return


@app.route('/api/v1/delete_contact', methods=['DELETE'])
def delete_contact():
    return
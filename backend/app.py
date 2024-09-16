from flask import Flask

app = Flask(__name__)


@app.route('/api/v1/login', methods=['POST'])
def login():
    return


@app.route('/api/v1/register', methods=['POST'])
def register():
    return


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
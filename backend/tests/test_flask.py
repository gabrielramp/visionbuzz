import pytest
from flask import json
from app import app

# Mocked data
mock_username = "testuser"
mock_password = "password123"
mock_hashed_password = "hashed_password"
mock_uid = "user-uid-123"


@pytest.fixture
def client():
    app.testing = True
    with app.test_client() as client:
        yield client


def test_login_success(mocker, client):
    # Mock the db_get_pwd_hash, check_password, and db_get_uid functions
    mocker.patch("app.db_get_pwd_hash", return_value=mock_hashed_password)
    mocker.patch("app.check_password", return_value=True)
    mocker.patch("app.db_get_uid", return_value=mock_uid)

    # Simulate a login request
    response = client.post("/api/v1/login", json={
        "username": mock_username,
        "password": mock_password
    })

    # Check if the response status code is 200 (OK)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert "access_token" in data
    assert "refresh_token" in data


def test_login_failure(mocker, client):
    # Mock the db_get_pwd_hash and check_password functions for a failed login
    mocker.patch("app.db_get_pwd_hash", return_value=mock_hashed_password)
    mocker.patch("app.check_password", return_value=False)

    # Simulate a login request with incorrect credentials
    response = client.post("/api/v1/login", json={
        "username": mock_username,
        "password": "wrong_password"
    })

    # Check if the response status code is 401 (Unauthorized)
    assert response.status_code == 401
    data = json.loads(response.data)
    assert data["msg"] == "Bad username or password"
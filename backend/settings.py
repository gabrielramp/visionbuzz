import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()


class Config:
    """Base configuration."""

    # JWT Settings
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
    if not JWT_SECRET_KEY:
        raise ValueError("No JWT_SECRET_KEY set for Flask application")

    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=1)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)

    NOTIF_COOLDOWN = timedelta(minutes=1)
    TEMP_EMBED_TIME_TO_LIVE = timedelta(days=1)

    # DBSCAN HYPERPARAMETESR
    CLUSTER_RADIUS = float(os.getenv("CLUSTER_RADIUS", "0.483"))
    CLUSTER_POINTS = int(os.getenv("CLUSTER_POINTS", "3"))
    MINIMUM_CLUSTER_SIZE = int(
        os.getenv("MINIMUM_CLUSTER_SIZE", "10")
    )  # minimum points before we allow registration

    # Database Settings
    DB_NAME = os.getenv("DB_NAME", "vision_draft")
    SCHEMA_PATH = os.getenv("SCHEMA_PATH", "db.sql")

    # Face Recognition Settings
    USE_QUANTIZED = bool(os.getenv("USE_QUANTIZED", "true"))

    YUNET_PATH = os.getenv("YUNET_PATH", "../models/face_detection_yunet_2023mar.onnx")
    ARCFACE_PATH = os.getenv("ARCFACE_PATH", "../models/arcface_full.onnx")
    ARCFACE_INT8_PATH = os.getenv("ARCFACE_INT8_PATH", "../models/arcface_int8.onnx")

    

    FACE_MATCH_THRESHOLD = float(os.getenv("FACE_MATCH_THRESHOLD", "0.483"))


class DevelopmentConfig(Config):
    """Development configuration."""

    DB_NAME = os.getenv("TEST_DB_NAME", "vision_test")
    DEBUG = True


class ProductionConfig(Config):
    """Production configuration."""

    DB_NAME = os.getenv("DB_NAME", "vision_db")
    # NOTE TODO: Production might use different paths for face recognition models


def get_config():
    debug = os.getenv("FLASK_DEBUG", "0") == "1"
    return DevelopmentConfig if debug else ProductionConfig

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

    # TODO: Implement
    # TODO: In the future, maybe let user set
    NOTIF_COOLDOWN = timedelta(minutes=1)
    TEMP_EMBED_TIME_TO_LIVE = timedelta(days=1)

    # Database Settings
    DB_NAME = os.getenv("DB_NAME", "vision_draft")

    # Face Recognition Settings
    SHAPE_PREDICTOR_PATH = os.getenv(
        "SHAPE_PREDICTOR_PATH", "shape_predictor_68_face_landmarks.dat"
    )
    FACE_REC_MODEL_PATH = os.getenv(
        "FACE_REC_MODEL_PATH", "dlib_face_recognition_resnet_model_v1.dat"
    )
    FACE_DATA_PATH = os.getenv("FACE_DATA_PATH", "facialdata")
    FACE_MATCH_THRESHOLD = float(os.getenv("FACE_MATCH_THRESHOLD", "0.6"))


class DevelopmentConfig(Config):
    """Development configuration."""

    DB_NAME = os.getenv("TEST_DB_NAME", "vision_test")
    DEBUG = True


class ProductionConfig(Config):
    """Production configuration."""

    pass
    # NOTE: Production might use different paths for face recognition models


def get_config():
    debug = os.getenv("FLASK_DEBUG", "0") == "1"
    return DevelopmentConfig if debug else ProductionConfig

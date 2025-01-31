from firebase_admin import credentials, initialize_app
# Initialize Firebase
def initialize_firebase():
    try:
        # Path to your Firebase service account key file
        cred = credentials.Certificate("fbc.json")
        initialize_app(cred)
        print("Firebase has been initialized.")
    except Exception as e:
        print(f"Error initializing Firebase: {e}")
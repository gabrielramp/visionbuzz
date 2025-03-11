"""
NOTES FOR USAGE:
- Have a login with an account (I'm using test6 with password test6)

CONTROLS:
- c: cluster loose embeddings
- r: refresh connection
- 0-9: add contact for cluster
- q: quit

Every 0.5 seconds, the image is uploaded to the server. Press the buttons
while the camera is running to test the functionality.
"""

import cv2
import numpy as np
import requests
from PIL import Image
import io
import time
import sys
import os
import warnings

# Suppress OpenCV and macOS warnings
warnings.filterwarnings("ignore")
os.environ["PYTHONWARNINGS"] = "ignore"

# Server configuration
# SERVER_URL = "http://127.0.0.1:5000"  # Local server
SERVER_URL = "http://159.223.99.186"  # Online server


def authenticate_with_test_user():
    response = requests.post(
        f"{SERVER_URL}/api/v1/login",
        json={"username": "newAccountTest", "password": "newAccountTest"},
    )
    if response.status_code != 200:
        raise Exception(
            f"Authentication failed: {response.json().get('msg', 'Unknown error')}"
        )

    # print(response)
    # print(response.json())
    print(f"Status code: {response.status_code}")
    print(f"Response headers: {response.headers}")
    print(f"Response content: {response.text}")
    # Only print a short version of the token to confirm authentication
    token = response.json()["access_token"]
    print(f"Authenticated successfully (token: ...{token[-10:]})")
    return token


def init_camera():
    """Initialize camera with error handling and platform-specific settings"""
    try:
        # Try different camera indices if the default doesn't work
        for camera_index in [0, 2]:
            cap = cv2.VideoCapture(camera_index)
            if cap.isOpened():
                # Set frame dimensions
                cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
                cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

                # Verify camera is working by reading a test frame
                ret, frame = cap.read()
                print("Frame shape:", frame.shape if frame is not None else None)
                print(
                    "Frame min/max values:",
                    frame.min() if frame is not None else None,
                    frame.max() if frame is not None else None,
                )
                if ret:
                    print(f"Successfully initialized camera with index {camera_index}")
                    return cap
                cap.release()

        raise Exception("Could not initialize any camera")
    except Exception as e:
        print(f"Error initializing camera: {str(e)}")
        sys.exit(1)


def add_contact_for_cluster(cluster_id, access_token):
    contact_name = input(f"Enter name for cluster {cluster_id}: ")

    response = requests.post(
        f"{SERVER_URL}/api/v1/create_contact",
        headers={"Authorization": f"Bearer {access_token}"},
        json={"cluster_id": cluster_id, "contact_name": contact_name},
    )

    if response.status_code == 200:
        print(f"Successfully added contact: {contact_name}")
    else:
        print(f"Failed to add contact. Status code: {response.status_code}")
        print(f"Response: {response.json()}")


# Login first
access_token = authenticate_with_test_user()

# Initialize video capture with error handling
cap = init_camera()
last_upload_time = time.time()
clusters = {}

try:
    while True:
        ret, frame = cap.read()
        if not ret:
            print("Error: Can't receive frame. Exiting...")
            break

        # Display the original frame
        cv2.imshow("Video Test", frame)

        # Upload every 1.0 seconds
        current_time = time.time()
        if current_time - last_upload_time >= 1.0:
            last_upload_time = current_time

            try:
                # Time each step of the process
                t_start = time.time()

                # Convert BGR to RGB and then to JPEG bytes
                rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                t_convert = time.time()

                pil_img = Image.fromarray(rgb_frame)
                img_byte_arr = io.BytesIO()
                pil_img.save(img_byte_arr, format="JPEG")
                img_byte_arr = img_byte_arr.getvalue()
                t_encode = time.time()

                # Send request to server
                response = requests.post(
                    f"{SERVER_URL}/api/v1/upload_image",
                    data=img_byte_arr,
                    headers={
                        "Content-Type": "application/octet-stream",
                        "Authorization": f"Bearer {access_token}",
                    },
                )
                t_upload = time.time()

                # Print timing breakdown
                print(f"\nTiming breakdown:")
                print(f"Color conversion: {(t_convert - t_start)*1000:.1f}ms")
                print(f"JPEG encoding: {(t_encode - t_convert)*1000:.1f}ms")
                print(f"Network upload: {(t_upload - t_encode)*1000:.1f}ms")
                print(f"Total time: {(t_upload - t_start)*1000:.1f}ms")
                print(f"Image size: {len(img_byte_arr)/1024:.1f}KB")

                # Only print errors, not successful responses
                if response.status_code != 200:
                    print(
                        f"Error {response.status_code}: {response.json().get('msg', 'Unknown error')}"
                    )
                    break  # Exit on error

            except requests.exceptions.RequestException as e:
                print(f"Connection error: {e}")
                break

        # Check for keyboard input
        key = cv2.waitKey(1) & 0xFF
        if key == ord("q"):
            print("Quitting...")
            break
        if key == ord("c"):
            # Cluster loose embeddings
            response = requests.get(
                f"{SERVER_URL}/api/v1/pull_timeline",
                headers={"Authorization": f"Bearer {access_token}"},
            )
            clusters = response.json()
            print(f"Pulled {len(clusters)} clusters")
            for cluster_id, timestamps in clusters.items():
                print(f"Cluster {cluster_id}: {len(timestamps)}")
        if key == ord("o"):
            # Pull contacts
            response = requests.get(
                f"{SERVER_URL}/api/v1/pull_contacts",
                headers={"Authorization": f"Bearer {access_token}"},
            )
            contacts = response.json()
            print(contacts)
            # print(f"Pulled {len(clusters)} clusters")
            # for cluster_id, timestamps in clusters.items():
            #     print(f"Cluster {cluster_id}: {len(timestamps)}")
        elif key == ord("r"):
            print("Refreshing connection...")
            try:
                access_token = authenticate_with_test_user()
            except Exception as e:
                print(f"Failed to refresh token: {e}")
                break
        # Handle number keys 0-9
        elif ord("0") <= key <= ord("9"):
            cluster_num = key - ord("0")  # Convert key code to number 0-9
            if str(cluster_num) in clusters:  # Check if cluster exists
                add_contact_for_cluster(str(cluster_num), access_token)

except KeyboardInterrupt:
    pass  # Exit silently on Ctrl+C
except Exception as e:
    print(f"Error: {str(e)}")
finally:
    cap.release()
    cv2.destroyAllWindows()

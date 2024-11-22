import requests

SERVER_URL = 'http://localhost:5000/api/v1/upload_image'
JWT_TOKEN = 'super-secret-key'
IMAGE_PATH = 'C:\\GitHub\\visionbuzz\\backend\\validface.jpg'
NAME = ''

headers = {
    'Authorization': f'Bearer {JWT_TOKEN}',
}

files = {
    'image': ('validface.jpg', open(IMAGE_PATH, 'rb'), 'image/jpeg')
}

# Include the 'name' field if you are adding a new face encoding
data = {}
if NAME:
    data['name'] = NAME

try:
    response = requests.post(SERVER_URL, headers=headers, files=files, data=data)
    print('Status Code:', response.status_code)
    print('Response JSON:', response.json())
except Exception as e:
    print('An error occurred:', str(e))
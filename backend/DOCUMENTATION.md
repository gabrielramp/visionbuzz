## API Documentation

### Login

`POST /api/v1/login`

Autenticates a user and returns JWT tokens.

*Request Body:*

```json
{
    "username": "string",
    "password:": "string"
}
```

*Responses:*

**Success Response (200):**

```json
{
    "access_token": "string",
    "refresh_token": "string"
}
```

**Error Response (401):**
```json
{
    "msg": "Bad username or password"
}
```

#### Register
`POST /api/v1/register`

Creates a new user account and returns JWT tokens.

**Request Body:**

```json
{
    "username": "string",
    "password": "string"
}
```

**Success Response (200):**
```json
{
    "access_token": "string",
    "refresh_token": "string"
}
```

**Error Response (401):**
```json
{
    "msg": "Username already taken"
}
```

#### Refresh Token
`POST /api/v1/refresh`

Refreshes an expired access token using a valid refresh token.

**Headers:**
- Authorization: Bearer {refresh_token}

**Success Response (200):**

```json
{
    "access_token": "string"
}
```

**Error Response (401):**
- Invalid/expired refresh token

### Contact Management

#### Pull Contacts
`GET /api/v1/pull_contacts`

Retrieves all contacts for the authenticated user.

**Headers:**
- Authorization: Bearer {access_token}

**Success Response (200):**

```json
[
    {
        "cid": "integer",
        "name": "string",
        "last_seen": "timestamp",
        "vib_pattern": "integer"
    }
]
```

#### Create Contact
`POST /api/v1/create_contact`

Creates a new contact from a cluster of face embeddings.

**Headers:**
- Authorization: Bearer {access_token}

**Request Body:**
```json
{
    "cluster_id": "string",
    "contact_name": "string"
}
```

**Success Response (200):**
```json
{
    "message": "Contact created successfully",
    "contact_name": "string"
}
```

**Error Responses:**
- 400: Missing required parameters
- 404: Cluster not found
- 500: Failed to create contact
- 500: Contact created but failed to clean up cluster

#### Edit Contact
`PATCH /api/v1/edit_contact`

Updates contact information.

**Headers:**
- Authorization: Bearer {access_token}

**Request Body:**
```json
{
    "cid": "integer",
    "name": "string",
    "vib_pattern": "integer"
}
```

**Success Response (200):**
```json
{
    "message": "Updated successfully"
}
```

**Error Response (404):**
```json
{
    "error": "Contact not updated successfully"
}
```

#### Delete Contact
`DELETE /api/v1/delete_contact/<cid>`

Deletes a contact.

**Headers:**
- Authorization: Bearer {access_token}

**Success Response (200):**
```json
{
    "message": "Contact deleted successfully"
}
```

**Error Response (404):**
```json
{
    "error": "Contact not found or could not be deleted"
}
```

### Image Processing

#### Upload Image
`POST /api/v1/upload_image`

Processes an uploaded image for face recognition. Detects faces, matches against known contacts, and stores unknown faces as loose embeddings.

**Headers:**
- Authorization: Bearer {access_token}
- Content-Type: application/octet-stream

**Request Body:**
- Raw image data in bytes

**Success Response (200):**
```json
{
    "message": "Image uploaded successfully"
}
```

**Error Response (400):**
```json
{
    "error": "Invalid image stream"
}
```

#### Pull Timeline
`GET /api/v1/pull_timeline`

Retrieves clusters of face detections over time. Cleans up old embeddings and runs clustering on temporary embeddings.

The cluster ID's are what you'll need to pass to create a new contact.

**Headers:**
- Authorization: Bearer {access_token}

**Success Response (200):**
```json
{
    "cluster_id": ["timestamp1", "timestamp2", ...],
    "cluster_id": ["timestamp1", "timestamp2", ...],
    ...
}
```
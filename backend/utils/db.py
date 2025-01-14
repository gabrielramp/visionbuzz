import psycopg
from settings import get_config

"""
- create a user
- add contact
- modify contact? (maybe need to split)
- delete a user
- delete a contact
- TODO: Figure out if we need something to do w/ embeddings
- TODO: store embeddings (WILL NEED UID AND CID)
- TODO: Change the connect from test db
- TODO: Find cleaner way to do this from config
"""


def db_check_user_taken(username: str) -> bool:
    """
    Returns whether a username is taken
    """
    with psycopg.connect(f"dbname={get_config().DB_NAME}") as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT COUNT(*)
                FROM users
                WHERE username = %s;
                """,
                (username,),
            )

            # cur.execute("SELECT * FROM test")
            n_rows = cur.fetchone()[0]

            # Make the changes to the database persistent
            conn.commit()
            return n_rows >= 1


def db_get_uid(username: str) -> int:
    """
    Returns UID of username
    """
    with psycopg.connect(f"dbname={get_config().DB_NAME}") as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT uid 
                FROM users
                WHERE username = %s;
                """,
                (username,),
            )

            res = cur.fetchone()
            uid = res[0]

            return uid


def db_create_user(username: str, pwd: str) -> int:
    """
    Returns UID?
    """
    with psycopg.connect(f"dbname={get_config().DB_NAME}") as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO users (username, pwd)
                    VALUES (%s, %s);
                """,
                (
                    username,
                    pwd,
                ),
            )

            cur.execute(
                """
                SELECT *
                FROM users
                WHERE username = %s;
                """,
                (username,),
            )

            res = cur.fetchone()
            uid = res[0]

            # Make the changes to the database persistent
            conn.commit()
            return uid


def db_get_pwd_hash(username: str) -> bool:
    """
    Returns whether login was successful
    """
    with psycopg.connect(f"dbname={get_config().DB_NAME}") as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT pwd 
                FROM users
                WHERE username = %s;
                """,
                (username,),
            )

            res = cur.fetchone()
            enc_pwd = res[0]

            conn.commit()
            return enc_pwd


def db_delete_user(uid: int) -> bool:
    with psycopg.connect(f"dbname={get_config().DB_NAME}") as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                DELETE FROM users
                WHERE uid = %s;
                """,
                (uid,),
            )

            cur.fetchone()
            uid = cur[0]

            conn.commit()
            return True


def db_add_contact(uid: int) -> int:
    """
    NOTE: The user should not have access to this
          At first, this should make temp user and connect embeddings to it
    TODO: This should also insert into the timeline and last seen category
    """
    with psycopg.connect(f"dbname={get_config().DB_NAME}") as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO contacts (uid, temp)
                    DEFAULT VALUES (%s, %s);
                """,
                (
                    uid,
                    True,
                ),
            )

            cur.fetchone()
            cid = cur[0]

            conn.commit()
            return cid


def db_get_contacts(uid: int):
    """
    Returns a list of contacts!
    """
    with psycopg.connect(f"dbname={get_config().DB_NAME}") as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT * FROM contacts
                WHERE uid = %s;
                """,
                (uid,),
            )

            cur.fetchall()
            print(cur)
            cid = cur

            return cid


def db_delete_contact(uid: int, cid: int):
    """
    Deletes a contact from a user
    """
    with psycopg.connect(f"dbname={get_config().DB_NAME}") as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                DELETE FROM contacts
                WHERE uid = %s AND cid = %s;
                """,
                (
                    uid,
                    cid,
                ),
            )

            cur.fetchall()
            print(cur)
            cid = cur

            return True

    return False


def db_update_contact(uid: int, cid: int, update_fields: dict) -> bool:
    """
    Given a contact ID and user ID, this updates the fields specified
    in the request
    """
    if not update_fields:
        return False

    set_fields = ", ".join(f"{key} = %s" for key in update_fields.keys())
    values = list(update_fields.values()) + [uid, cid]
    query = f"""
            UPDATE contacts
            SET {set_fields}
            WHERE uid = %s AND cid = %s;
            """

    with psycopg.connect(f"dbname={get_config().DB_NAME}") as conn:
        with conn.cursor() as cur:
            cur.execute(query, values)

            cur.fetchall()
            print(cur)
            cid = cur

            return True

    return False


"""
PROBLEM: This function way too thicc
SOLUTION: 
    - last_seen is only accessed by backend and should be its own thing
    - name, vib_pattern, temp should all be front-end
"""


# TODO: Change this sometime
def db_change_embedding(uid: int, cid: int):
    return


# Create DB thing to pull timeline of events for an individual
# TODO: Double check this works
def db_pull_contact_timeline(cid: int):
    with psycopg.connect(f"dbname={get_config().DB_NAME}") as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT seen_at
                FROM contact_timeline
                WHERE cid = %s
                ORDER BY seen_at DESC;
                """,
                (cid,),
            )

            cur.fetchall()
            print(cur)
            timeline = cur

            return timeline
    return None


# TODO: Update a user's timeline
def db_update_contact_timeline(cid: int, time: int):
    return


def db_remove_all_temp_contacts(uid: int):
    return

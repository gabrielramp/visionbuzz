import psycopg

"""
- create a user
- add contact
- modify contact? (maybe need to split)
- delete a user
- delete a contact
- TODO: Figure out if we need something to do w/ embeddings
- TODO: store embeddings (WILL NEED UID AND CID)
"""


def db_create_user(username: str, pwd: str) -> int:
    """
    TODO: Returns UID?
    """
    with psycopg.connect("dbname=test user=postgres") as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO users (username, pwd)
                    DEFAULT VALUES (%s, %s)
                """,
                (username, pwd)
            )

            # cur.execute("SELECT * FROM test")
            cur.fetchone()
            uid = cur[0]

            # Make the changes to the database persistent
            conn.commit()
            return uid


def db_delete_user(uid: int) -> bool:
    with psycopg.connect("dbname=test user=postgres") as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                DELETE FROM users
                WHERE uid = %s
                """,
                (uid)
            )

            # cur.execute("SELECT * FROM test")
            cur.fetchone()
            uid = cur[0]

            # Make the changes to the database persistent
            conn.commit()
            return True


def db_add_contact(uid: int) -> int:
    """
    NOTE: The user should not have access to this
          At first, this should make temp user and connect embeddings to it
    """
    with psycopg.connect("dbname=test user=postgres") as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO contacts (uid, temp)
                    DEFAULT VALUES (%s, %s)
                """,
                (uid, True)
            )

            # cur.execute("SELECT * FROM test")
            cur.fetchone()
            cid = cur[0]

            # Make the changes to the database persistent
            conn.commit()
            return cid


def db_delete_contact(uid, cid):
    return


def db_modify_contact(uid, cid, info):
    return

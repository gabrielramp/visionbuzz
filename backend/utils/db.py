import psycopg

"""
- create a user
- add contact
- modify contact? (maybe need to split)
- delete a user
- delete a contact
- TODO: Figure out if we need something to do w/ embeddings
- TODO: store embeddings (WILL NEED UID AND CID)
- TODO: Change the connect from test db
"""


def db_check_user_taken(username: str) -> bool:
    """
    Returns whether a username is taken
    """
    with psycopg.connect("dbname=vision_draft") as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT COUNT(*)
                FROM users
                WHERE username = %s;
                """,
                (username, )
            )

            # cur.execute("SELECT * FROM test")
            n_rows = cur.fetchone()[0]

            # Make the changes to the database persistent
            conn.commit()
            return n_rows >= 1


def db_create_user(username: str, pwd: str) -> int:
    """
    Returns UID?
    """
    with psycopg.connect("dbname=vision_draft") as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO users (username, pwd)
                    VALUES (%s, %s);
                """,
                (username, pwd, )
            )

            cur.execute(
                """
                SELECT *
                FROM users
                WHERE username = %s;
                """,
                (username, )
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
    with psycopg.connect("dbname=vision_draft") as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT pwd 
                FROM users
                WHERE username = %s;
                """,
                (username, )
            )

            res = cur.fetchone()
            enc_pwd = res[0]

            conn.commit()
            return enc_pwd



def db_delete_user(uid: int) -> bool:
    with psycopg.connect("dbname=test user=postgres") as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                DELETE FROM users
                WHERE uid = %s
                """,
                (uid, )
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
                (uid, True, )
            )

            # cur.execute("SELECT * FROM test")
            cur.fetchone()
            cid = cur[0]

            # Make the changes to the database persistent
            conn.commit()
            return cid


def db_delete_contact(uid, cid):
    return


"""
PROBLEM: This function way too thicc
SOLUTION: 
    - last_seen is only accessed by backend and should be its own thing
    - name, vib_pattern, temp should all be front-end
"""


def db_change_embedding(uid: int, cid: int):
    return
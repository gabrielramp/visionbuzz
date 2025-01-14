import psycopg
from contextlib import contextmanager

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


class DatabaseService:
    def __init__(self, config):
        self.db_name = config.DB_NAME
        self.conn_string = f"dbname={self.db_name}"

        # Create database if it doesn't exist
        self._ensure_database_exists()
        # Test connection and verify tables exist
        self._verify_tables()

    def _ensure_database_exists(self):
        pass

    def _verify_tables(self):
        pass

    @contextmanager
    def get_connection(self):
        """Context manager for database connections"""
        conn = psycopg.connect(self.conn_string)
        try:
            yield conn
        finally:
            conn.close()

    def check_user_taken(self, username: str) -> bool:
        """
        Returns whether a username is taken
        """
        with self.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT COUNT(*)
                    FROM users
                    WHERE username = %s;
                    """,
                    (username,),
                )
                n_rows = cur.fetchone()[0]
                return n_rows >= 1

    def get_uid(self, username: str) -> int:
        """
        Returns UID of username
        """
        with self.get_connection() as conn:
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

    def create_user(self, username: str, pwd: str) -> int:
        """
        Returns UID?
        """
        with self.get_connection() as conn:
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

    def get_pwd_hash(self, username: str) -> bool:
        """
        Returns whether login was successful
        """
        with self.get_connection() as conn:
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

    def delete_user(self, id: int) -> bool:
        with self.get_connection() as conn:
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

    def add_contact(self, uid: int) -> int:
        """
        NOTE: The user should not have access to this
            At first, this should make temp user and connect embeddings to it
        TODO: This should also insert into the timeline and last seen category
        """
        with self.get_connection() as conn:
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

    def get_contacts(self, uid: int):
        """
        Returns a list of contacts!
        """
        with self.get_connection() as conn:
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

    def delete_contact(self, uid: int, cid: int):
        """
        Deletes a contact from a user
        """
        with self.get_connection() as conn:
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

    def update_contact(self, uid: int, cid: int, update_fields: dict) -> bool:
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

        with self.get_connection() as conn:
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
    def change_embedding(self, uid: int, cid: int):
        return

    # Create DB thing to pull timeline of events for an individual
    # TODO: Double check this works
    def pull_contact_timeline(self, cid: int):
        with self.get_connection() as conn:
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
    def update_contact_timeline(self, cid: int, time: int):
        return

    # TODO: IMPLEMENT THIS
    def remove_all_temp_contacts(self, uid: int):
        return

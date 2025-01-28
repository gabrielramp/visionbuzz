import psycopg
import numpy as np
from contextlib import contextmanager
from typing import List

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
        self.schema_path = config.SCHEMA_PATH
        self.conn_string = f"dbname={self.db_name}"
        self.min_cluster_size = config.MINIMUM_CLUSTER_SIZE
        self.match_threshold = config.FACE_MATCH_THRESHOLD

        # Create database if it doesn't exist
        self._ensure_database_exists()
        # Test connection and verify tables exist
        self._verify_tables()

    def _ensure_database_exists(self):
        """
        Ensures the required database exists, creating it if necessary.
        """
        # Connect to default postgres database first to check/create our database
        base_conn = psycopg.connect("dbname=postgres")
        base_conn.autocommit = True

        try:
            with base_conn.cursor() as cur:
                # Check if database exists
                cur.execute(
                    """
                    SELECT 1 FROM pg_database 
                    WHERE datname = %s;
                    """,
                    (self.db_name,),
                )

                if not cur.fetchone():
                    # Create database if it doesn't exist
                    cur.execute(f"CREATE DATABASE {self.db_name};")

        finally:
            base_conn.close()

    def _verify_tables(self):
        """
        Verifies all required tables exist by executing the SQL schema file.
        """
        with self.get_connection() as conn:
            with conn.cursor() as cur:
                # Read the SQL file
                with open(self.schema_path, "r") as file:
                    cur.execute(file.read())
                conn.commit()

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

    # Create DB thing to pull timeline of events for an individual
    # TODO: Double check this works
    # TODO: Totally change
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

    def pull_single_cluster(self, uid: int, cluster_id: int):
        """
        Pulls all embeddings for a specific cluster ID for a user.
        Returns list of embeddings or None if cluster not found.
        """
        with self.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT embedding
                    FROM loose_embeddings 
                    WHERE uid = %s AND cluster_id = %s;
                    """,
                    (
                        uid,
                        cluster_id,
                    ),
                )
                results = cur.fetchall()
                if not results:
                    return None
                return [row[0] for row in results]

    def create_contact(self, uid: int, name: str, embedding: list) -> bool:
        """
        Creates a new contact with the given name and averaged embedding.
        Returns True if successful, False otherwise.
        """
        with self.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO contacts (uid, name, embedding, last_seen)
                    VALUES (%s, %s, %s, CURRENT_TIMESTAMP)
                    RETURNING cid;
                    """,
                    (uid, name, str(embedding)),
                )
                conn.commit()
                return True

    def remove_single_cluster(self, user_id: int, cluster_id: str) -> bool:
        """
        Removes all embeddings associated with a specific cluster ID.
        """
        with self.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    DELETE FROM loose_embeddings
                    WHERE uid = %s AND cluster_id = %s;
                    """,
                    (user_id, cluster_id),
                )
                conn.commit()
                return True

    def pull_temp_embeds(self, uid: int) -> list:
        """
        Pulls all temporary embeddings for a user that aren't expired,
        using the TEMP_EMBED_TIME_TO_LIVE config value
        """
        with self.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT embedding
                    FROM loose_embeddings
                    WHERE uid = %s 
                    ORDER BY eid
                    """,
                    (uid,),
                )
                results = cur.fetchall()
                return [row[0] for row in results]

    def save_cluster_ids(self, uid: int, cluster_ids: list[int]) -> bool:
        """
        Updates each embedding's cluster_id to match its corresponding value in cluster_ids.
        The order of cluster_ids matches the embeddings when ordered by id.
        """
        with self.get_connection() as conn:
            with conn.cursor() as cur:
                # Get all embeddings IDs for this user
                cur.execute(
                    "SELECT eid FROM loose_embeddings WHERE uid = %s ORDER BY eid",
                    (uid,),
                )
                embedding_ids = [row[0] for row in cur.fetchall()]

                # Update each embedding with its cluster ID
                # TODO: This is gonna be quite slow I think (maybe fine?)
                for embedding_id, cluster_id in zip(embedding_ids, cluster_ids):
                    cur.execute(
                        """
                        UPDATE loose_embeddings 
                        SET cluster_id = %s 
                        WHERE eid = %s
                    """,
                        (cluster_id, embedding_id),
                    )

                conn.commit()
                return True

    def pull_clusters(self, uid: int) -> dict:
        """
        Pulls valid clusters for a user, returning a mapping of cluster IDs to timestamps.
        Only includes clusters that meet the minimum size requirement and excludes noise points (cluster_id -1).

        Args:
            uid: User ID to pull clusters for

        Returns:
            dict: Mapping of cluster_id to list of timestamps, e.g. {1: ['2024-01-21 10:00:00', ...]}
        """
        with self.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    WITH cluster_sizes AS (
                        SELECT cluster_id, COUNT(*) as size
                        FROM loose_embeddings
                        WHERE uid = %s AND cluster_id != -1
                        GROUP BY cluster_id
                        HAVING COUNT(*) >= %s
                    )
                    SELECT le.cluster_id, array_agg(le.seen_at ORDER BY le.seen_at)
                    FROM loose_embeddings le
                    INNER JOIN cluster_sizes cs ON le.cluster_id = cs.cluster_id
                    WHERE le.uid = %s
                    GROUP BY le.cluster_id;
                    """,
                    (uid, self.min_cluster_size, uid),
                )

                results = cur.fetchall()
                return {
                    str(cluster_id): timestamps for cluster_id, timestamps in results
                }

    def cleanup_old_embeddings(self, uid: int) -> None:
        """Deletes embeddings older than TEMP_EMBED_TIME_TO_LIVE for a specific user"""
        with self.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    DELETE FROM loose_embeddings
                    WHERE uid = %s
                    AND seen_at < CURRENT_TIMESTAMP - interval '1 day';
                    """,
                    (uid,),
                )
                conn.commit()

    def pull_closest_contact(self, uid: int, embedding: list):
        """Pull closest contact to the embedding"""
        with self.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT *
                    FROM contacts
                    WHERE uid = %s AND (embedding <-> %s < %s)
                    ORDER BY embedding <-> %s
                    LIMIT 1
                    """,
                    (uid, str(embedding), self.match_threshold, str(embedding)),
                )

                columns = [desc[0] for desc in cur.description]
                results = cur.fetchone()

                if not results:
                    return None

                return dict(zip(columns, results))

    def update_last_seen(self, uid: int, cid: int):
        """Updates the last_seen time of a contact"""
        with self.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    UPDATE contacts 
                    SET last_seen = CURRENT_TIMESTAMP
                    WHERE uid = %s AND cid = %s;
                    """,
                    (uid, cid),
                )
            conn.commit()
            return True

    def add_loose_embedding(self, uid: int, embedding: list):
        """Adds a loose embedding to the database"""
        with self.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO loose_embeddings (uid, embedding, seen_at)
                    VALUES (%s, %s, CURRENT_TIMESTAMP);
                    """,
                    (uid, embedding),
                )
            conn.commit()
            return True

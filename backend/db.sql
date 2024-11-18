-- TODO: Add email
CREATE TABLE users (
    uid         serial PRIMARY KEY,
    username    varchar NOT NULL,
    pwd         varchar NOT NULL
);

-- TODO: Might have to change from last_seen to somehow have feed?????
CREATE TABLE contacts (
    cid             serial PRIMARY KEY,
    uid             integer REFERENCES users(uid),        -- TODO: Check foreign keys
    name            varchar,
    vib_pattern     integer,           -- TODO: design how this works!
    temp            boolean NOT NULL,
    button_pressed  boolean NOT NULL
);

-- TODO: Figure out if this is a good idea
CREATE TABLE contact_timeline (
    tid           serial PRIMARY KEY,
    cid           integer REFERENCES contacts(cid) ON DELETE CASCADE,
    seen_at       timestamptz NOT NULL,
    FOREIGN KEY (cid) REFERENCES contacts(cid) ON DELETE CASCADE
);

/* TODO: Change this depending on how they finally end up implementing the 
         embeddings*/
CREATE TABLE embeddings (
    cid integer REFERENCES contacts(cid),
    uid integer REFERENCES users(uid),
    embedding int[][],                  -- TODO: We haven't figured out how to store embeddings
    PRIMARY KEY (cid, uid)
)

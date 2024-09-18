CREATE TABLE users (
    uid         serial PRIMARY KEY,
    username    varchar NOT NULL,
    pwd         varchar NOT NULL
);

CREATE TABLE contacts (
    cid         serial PRIMARY KEY,
    uid         integer REFERENCES users(uid),        -- TODO: Check foreign keys
    name        varchar NOT NULL,
    vib_pattern integer,           -- TODO: design how this works!
    temp        integer NOT NULL,
    last_seen   timestamptz
);

/* TODO: Change this depending on how they finally end up implementing the 
         embeddings*/
CREATE TABLE embeddings (
    cid integer REFERENCES contacts(cid),
    uid integer REFERENCES users(uid),
    embedding int[][],                  -- TODO: We haven't figured out how to store embeddings
    PRIMARY KEY (cid, uid)
)

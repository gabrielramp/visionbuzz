CREATE EXTENSION vector;

-- TODO: Add email
-- TIM TODO: Make sure firebase_token is correct type
CREATE TABLE users (
    uid            serial PRIMARY KEY,
    username       varchar NOT NULL,
    pwd            varchar NOT NULL
    firebase_token varchar NOT NULL,
);

-- JOSE TODO: EMBEDDING SIZE MIGHT BE DIFFERENT
CREATE TABLE contacts (
    cid         serial PRIMARY KEY,
    uid         integer REFERENCES users(uid),        -- TODO: Check foreign keys
    name        varchar NOT NULL,
    vib_pattern integer,           -- TODO: design how this works!
    embedding   vector(128) NOT NULL, 
    last_seen   timestamptz NOT NULL,
);

-- NOTE: Maybe add back button and something to support images later
CREATE TABLE loose_embeddings (
    uid         integer REFERENCES users(uid),
    embedding   vector(128) NOT NULL,
    seen_at     timestamptz NOT NULL,
    cluster_label integer DEFAULT -1
)


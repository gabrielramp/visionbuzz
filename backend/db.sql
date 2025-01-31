CREATE EXTENSION IF NOT EXISTS vector;

-- TODO: Add email
-- TIM TODO: Make sure firebase_token is correct type
CREATE TABLE IF NOT EXISTS users (
    uid            serial PRIMARY KEY,
    username       varchar NOT NULL UNIQUE,
    pwd            varchar NOT NULL,
    firebase_token varchar
);

-- JOSE TODO: EMBEDDING SIZE MIGHT BE DIFFERENT
CREATE TABLE IF NOT EXISTS contacts (
    cid         serial PRIMARY KEY,
    uid         integer REFERENCES users(uid) ON DELETE CASCADE ,        -- TODO: Check foreign keys
    name        varchar NOT NULL,
    vib_pattern integer,           -- TODO: design how this works!
    embedding   vector(128) NOT NULL, 
    last_seen   timestamptz NOT NULL
);

-- NOTE: Maybe add back button and something to support images later
CREATE TABLE IF NOT EXISTS loose_embeddings (
    eid          serial PRIMARY KEY,
    uid           integer REFERENCES users(uid) ON DELETE CASCADE,
    embedding     vector(128) NOT NULL,
    seen_at       timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cluster_id    integer DEFAULT '-1'
);


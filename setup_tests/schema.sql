\set ON_ERROR_STOP

CREATE EXTENSION pgcrypto;

BEGIN;
create table items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title varchar(128),
    description text,
    priority integer,
    created_tm timestamp with time zone,
    updated_tm timestamp with time zone
);

grant all privileges on table items to test_user;
COMMIT;

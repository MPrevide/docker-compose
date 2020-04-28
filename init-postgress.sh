#!/usr/bin/env bash

set -e

psql -v ON_ERROR_STOP=1 --dbname postgres --username  postgres  <<-EOSQL
    CREATE database kong;
    CREATE USER kong WITH UNENCRYPTED PASSWORD 'kong';
    GRANT ALL PRIVILEGES ON DATABASE kong TO kong;
    CREATE DATABASE auth;
    CREATE USER auth WITH UNENCRYPTED PASSWORD 'auth';
    ALTER ROLE auth WITH CREATEDB;
    CREATE DATABASE devm;
    CREATE USER devm WITH UNENCRYPTED PASSWORD 'devm';
    ALTER ROLE devm WITH CREATEDB;
EOSQL
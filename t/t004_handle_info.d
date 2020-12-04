#!/usr/bin/env dub
/+ dub.json: { "dependencies": { "zug-tap": "~>0.2.2", "symdbi": { "path": "../" }  } } +/

import std.stdio;
import std.conv;
import std.array;

import symdbi.pg;
import zug.tap;
static import symdbi.util;

import std.stdio: writeln;

void main() {

    auto tap = Tap("Basic tests");
    tap.verbose(true);
    tap.disable_debugging();

    string host;
    string port;
    string db_name;
    string user;
    string password;

    {
        import std.process: environment;
        import std.array: split;
        auto dsn_env = environment.get("TEST_SYMDBI_DSN");
        if (dsn_env is null) {
            tap.skip("No DSN found in environment: set TEST_SYMDBI_DNS to run the tests");
            return;
        }

        auto dsn_parts = dsn_env.split(" ");
        host = dsn_parts[0];
        port = dsn_parts[1];
        db_name = dsn_parts[2];
        user = dsn_parts[3];
        password = dsn_parts[4];
    }

    dsn conn_info = new dsn([
        "host": host,
        "port": port,
        "dbname": db_name,
        "user": user,
        "password": password
    ]);

    DBH dbh  = new DBH(conn_info);

    tap.ok(dbh.effective_host == host, "effective host matches");
    tap.ok(dbh.effective_port == port, "effective port matches");
    tap.ok(dbh.effective_user == user, "effective user matches");
    tap.ok(dbh.effective_pass == password, "effective password matches");
    tap.ok(dbh.effective_options == "" , "no options as expected");
    tap.done_testing();
    tap.report();
}
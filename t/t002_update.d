#!/usr/bin/env dub
/+ dub.json: { "dependencies": { "zug-tap": "~>0.2.2", "symdbi": { "path": "../" }  } } +/

import symdbi.pg;
import zug.tap;
static import symdbi.util;


void main() {

    auto tap = Tap("Basic tests");
    tap.verbose(true);
    tap.disable_debugging();

    auto dsn_env = environment.get("TEST_SYMDBI_DSN");
    if (dsn_env is null) {
        tap.skip("No DSN found in environment: set TEST_SYMDBI_DNS to run the tests");
        return;
    }

    string[] dsn_parts = dsn_env.split(" ");

    dsn conn_info = new dsn([
        "host": dsn_parts[0],
        "port": dsn_parts[1],
        "dbname": dsn_parts[2],
        "user": dsn_parts[3],
        "password": dsn_parts[4]
    ]);

    DBH dbh = new DBH(conn_info);
    dbh.debugging(false);


    // add some data
    {
        string table = "items";
        string[string] data = [
            "title": "title inserted 1"
            , "description": "desc first"
            , "priority": "1"
            , "updated_tm": "NOW()"
            , "created_tm": "NOW()"
        ];
        string primary_key = "id";
        auto auto_pk_value = dbh.insert(table, primary_key, data);
    }



    tap.done_testing();
    tap.report();

}



#!/usr/bin/env dub
/+ dub.json: { "dependencies": { "zug-tap": "~>0.2.2", "symdbi": { "path": "../" }  } } +/

import symdbi.pg;
import zug.tap;
static import symdbi.util;

import std.process: environment;
import std.array: split;
import std.stdio: writeln;

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
        import std.range: iota;

        string table = "items";
        string[string] data = [
            "title": "title inserted 1"
            , "description": "desc first"
            , "priority": "1"
            , "updated_tm": "NOW()"
            , "created_tm": "NOW()"
        ];
        string primary_key = "id";
        string auto_pk_value = dbh.insert(table, primary_key, data);
        tap.ok(auto_pk_value.length == 36, "answer from insert has the lenght of an uuid");
        // insert 10 more to have something to test updates against
        foreach (i; 10.iota) {
            dbh.insert(table, primary_key, data);
        }
    }

    { // update via prepare and execute
        STH sth = dbh.prepare("update items set title=$1, description=$2 where title like $3||'%'");
        tap.ok(sth.execute(["title updated", "desc updated", "title inserted"]), "update execute returned true");
    }

    {
        string[string][] result = dbh.selectall_assoc(
            "select * from items where title = $1 and description = $2",
            ["title updated", "desc updated" ]
        );
        tap.ok(result.length == 11, "after update found 11 changed records as expected");
    }

    {
        // cleanup
        bool truncated = dbh.do_command("truncate table items");
        tap.ok(truncated, "truncate table items returned true");
        auto result = dbh.selectall("select count(*) from items as total_number");
        tap.ok(result == [["0"]], "table was indeed truncated");
    }

    tap.done_testing();
    tap.report();

}



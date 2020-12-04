#!/usr/bin/env dub
/+ dub.json: { "dependencies": { "zug-tap": "~>0.2.2", "symdbi": { "path": "../" }  } } +/

import std.stdio;
import std.conv;
import std.array;

import symdbi.pg;
import zug.tap;
static import symdbi.util;
import std.process: environment;
import std.array: split;
import std.datetime: DateTime;

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

        bool insert_success = false;
        if (auto_pk_value) {
            insert_success = true;
        }
        tap.ok(
            insert_success,
            "insert with parameters returning something"
        );

        if (insert_success) {
            string[string][] res_assoc_array = dbh.selectall_assoc("select * from items where id = $1", [auto_pk_value]);
            tap.ok(true,"TODO selecting after insert");
        }
    }


    /*
    test_db=# \d items
                                    Table "public.items"
    Column    |            Type             | Collation | Nullable |      Default
    -------------+-----------------------------+-----------+----------+-------------------
    id          | uuid                        |           | not null | gen_random_uuid()
    title       | character varying(128)      |           |          |
    description | text                        |           |          |
    priority    | integer                     |           |          |
    created_tm  | timestamp with time zone    |           |          |
    updated_tm  | timestamp with time zone    |           |          |
    */

    /* this should not work
    class Bla { int i; }
     Bla[] result = dbh.select!Bla("select * from items order by created_tm desc");
    `
    Error: template instance symdbi.pg.dbh.select!(Bla) does not match template declaration select(T)(DBH dbh, string query)
    with T = t005_struct_return.main.Bla
    must satisfy the following constraint:
        is(T == struct)
    `
    */
    // see ItemsRow declaration below, apparently you can't send a
    ItemsRow[] result = dbh.select!ItemsRow(
        `select
            id,
            title,
            description,
            priority,
            to_char(created_tm, 'YYYY-MM-DD"T"HH24:MI:SS') as created_tm,
            to_char(updated_tm, 'YYYY-MM-DD"T"HH24:MI:SS') as updated_tm
        from
            items
        order by
            created_tm desc`
    );
    tap.ok(result.length == 1, "one row in, one row out");
    tap.ok(result[0].label == "title inserted 1", "the return struct works and looks like it's having the right values");

    {
        // cleanup
        bool truncated = dbh.do_command("truncate table items");
        tap.ok(truncated, "truncate table items returned true");
        auto count = dbh.selectall("select count(*) from items as total_number");
        tap.ok(count == [["0"]], "table was indeed truncated");
    }

    tap.done_testing();
    tap.report();
}

// deliberately I made the properties have different names to make it obvious
alias raw_value = ubyte[];
struct ItemsRow {
    string primary_key;
    string label;
    string explanation;
    int urgency;
    DateTime created;
    DateTime updated;

    this(raw_value[string] row_data) {
        import std.conv: to;
        import std.datetime: DateTime;

        this.primary_key = cast(string) row_data["id"];
        this.label = cast(string) row_data["title"];
        this.explanation = cast(string) row_data["description"];
        this.urgency = (cast(string) row_data["priority"]).to!int;
        this.created = DateTime.fromISOExtString( cast(string) row_data["created_tm"] );
        this.updated = DateTime.fromISOExtString( cast(string) row_data["updated_tm"] );
    }
}

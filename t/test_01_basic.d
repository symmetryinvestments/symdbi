#!/usr/bin/env dub
/+ dub.json: { "dependencies": { "zug-tap": "~master", "symdbi": { "path": "../" }  } } +/

import std.stdio;
// import std.variant;
import std.conv;
import std.array;

import symdbi.pg;
import zug.tap;
static import symdbi.util;

debug import std.stdio: writeln;

void main() {
    auto tap = Tap("some test");
    tap.verbose(true);
    tap.enable_debugging();

    dsn conn_info = new dsn([
        "host": "localhost",
        "port": "5432",
        "user": "test_user",
        "password": "asdf1234#",
        "dbname":"test_db",
    ]);

    symdbi.util.write_debug(conn_info.connection_string());

    // variants as bound parameters
    // this does not work:
    // Error: incompatible types for ((1) : ("a")): 'int' and 'string'
    // Variant[3] test = [1, "a", conn_info];
    // https://dlang.org/library/std/variant/variant_array.html

    DBH dbh  = new DBH(conn_info);
    dbh.debugging(false);

    tap.ok( delegate bool() {
            STH sth = dbh.prepare("select * from items");
            sth.execute([]);
            string[string][] result = sth.fetchall_hashref();
            import std.stdio: writeln;
            writeln(result);
            tap.do_debug( symdbi.util.dumper(result) );
            return true;
        },
        "fetchall_arrayref"
    );

    tap.ok( delegate bool() {
            STH sth = dbh.prepare("select * from items where priority=$1");
            sth.execute(["1"]);
            string[string][] result = sth.fetchall_hashref();
            tap.do_debug( symdbi.util.dumper(result) );
            return true;
        },
        "prepared statements with string params fetchall_arrayref"
    );

    tap.ok( delegate bool() {
            STH sth = dbh.prepare(
                "select * from items where priority=$1 and title=$2"
            );
            sth.execute(["2", "second"]);
            string[string][] result = sth.fetchall_hashref();
            tap.do_debug( symdbi.util.dumper(result) );
            return true;
        },
        "prepared statements with string params"
    );

    tap.ok( delegate bool () {
            auto result = dbh.selectall_arrayref(
                "select * from items where priority=2"
            );
            writeln( to!string( result ) );
            return true;
        },
        "plain query selectall_arrayref"
    );

    tap.ok( delegate bool () {
            string query = "select * from items";
            string[string][] res_assoc_array = dbh.selectall_hashref(query);
            tap.do_debug( symdbi.util.dumper(res_assoc_array) );
            return true;
        },
        "plain query selectall_hashref"
    );

    tap.ok( delegate bool () {
            string[string][] res_assoc_array_new = dbh.selectall_hashref(
                "select * from items where title = $1",
                ["first"]
            );
            tap.do_debug( symdbi.util.dumper(res_assoc_array_new) );
            return true;
        },
        "query with one param"
    );

    tap.ok( delegate bool () {
            string[string][] res_assoc_array = dbh.selectall_hashref(
                "select * from items where title = $1 and priority = $2",
                ["first", "1" ]
            );
            tap.do_debug( symdbi.util.dumper(res_assoc_array) );
            return true;
        },
        "query with two params"
    );

    tap.ok( delegate bool () {
            string[string][] res_assoc_array = dbh.selectall_hashref(
                "select * from items where updated_tm <= $1", ["2016-12-27"]
            );
/*
    Postgres does this in the background when the timestamp param is not complete:
    LOG:  execute <unnamed>: select * from items where updated_tm <= $1
    DETAIL:  parameters: $1 = '2016-12-27 00:00:00'
*/
            tap.do_debug( symdbi.util.dumper(res_assoc_array) );
            return true;
        },
        "query with timestamp param"
    );

    string table = "items";
    string[] columns = [
        "title", "description", "priority","updated_tm", "created_tm"
    ];
    string[] values = [
        "tile inserted 1", "desc inserted 1", "1", "NOW()", "NOW()"
    ];
    string primary_key = "id";
    auto auto_pk_value = dbh.insert(table, primary_key, columns, values);

    symdbi.util.write_debug("############ " ~ auto_pk_value);
    bool insert_success = false;
    if (auto_pk_value) {
        insert_success = true;
    }
    tap.ok(
        insert_success,
        "insert with parameters returning something"
    );

    if (insert_success) {
        string[string][] res_assoc_array = dbh.selectall_hashref("select * from items where id = $1", [auto_pk_value]);
        writeln(symdbi.util.dumper(res_assoc_array));
        tap.ok(true,"TODO selecting after insert");
    }
}


void test_query_with_timestamp_param(DBH dbh)
{

}




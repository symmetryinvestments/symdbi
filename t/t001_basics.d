#!/usr/bin/env dub
/+ dub.json: { "dependencies": { "zug-tap": "~>0.2.2", "symdbi": { "path": "../" }  } } +/

import std.stdio;
import std.conv;
import std.array;

import symdbi.pg;
import zug.tap;
static import symdbi.util;

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
        // dsn: data source name, standard meme in some subcultures of programmers
        // set up DSN
        // export TEST_SYMDBI_DSN="localhost 5432 test_db test_user asdf1234#"
        auto dsn_env = environment.get("TEST_SYMDBI_DSN");
        if (dsn_env is null) {
            tap.skip("No DSN found in environment: set TEST_SYMDBI_DNS to run the tests");
            return; // NOTHING to do, giving up
        }

        auto dsn_parts = dsn_env.split(" ");
        host = dsn_parts[0];
        port = dsn_parts[1];
        db_name = dsn_parts[2];
        user = dsn_parts[3];
        password = dsn_parts[4];
    }

    // example TEST_SYMDBI_DSN
    // export TEST_SYMDBI_DSN="localhost 5432 test_db test_user asdf1234#"
    dsn conn_info = new dsn([
        "host": host,
        "port": port,
        "dbname": db_name,
        "user": user,
        "password": password
    ]);

    symdbi.util.write_debug(conn_info.connection_string());

    // variants as bound parameters
    // this does not work:
    // Error: incompatible types for ((1) : ("a")): 'int' and 'string'
    // Variant[3] test = [1, "a", conn_info];
    // https://dlang.org/library/std/variant/variant_array.html
    //
    // TODO: look into sumtype, just added it to dub.json as dependency so I won't forget


    DBH dbh  = new DBH(conn_info);
    dbh.debugging(false);


    {
        string table = "items";
        string[] columns = [
            "title", "description", "priority","updated_tm", "created_tm"
        ];
        string[] values = [
            "title first", "desc first", "1", "NOW()", "NOW()"
        ];
        string primary_key = "id";
        auto auto_pk_value = dbh.insert(table, primary_key, columns, values);
        tap.ok(auto_pk_value.length == 36, "length of the primary key is 36");
    }

    {
        STH sth = dbh.prepare("select * from items");
        sth.execute([]);
        string[string][] result = sth.fetchall_assoc();
        tap.ok(result.length == 1, "plain query no parameters, 1 record found as expected");
    }

    {
        STH sth = dbh.prepare("select * from items where priority=$1");
        sth.execute(["1"]);
        string[string][] result = sth.fetchall_assoc();
        tap.ok(result.length == 1, "prepared query, 1 record found as expected");
    }

    {
        STH sth = dbh.prepare(
            "select * from items where priority=$1 and title=$2"
        );
        sth.execute(["1", "title first"]);
        string[string][] result = sth.fetchall_assoc();
        tap.ok(result.length == 1, "prepared statements with 2 string params");
    }

    // TODO current sth.execute expects tuples back from the server
    // {
    //     STH sth = dbh.prepare("insert into items (title, priority, created_tm, updated_tm) values ($1, $2, $3, $4)");
    //     tap.ok(sth.execute(["title second", "2", "NOW()", "NOW()"]), "prepared explicit insert query does not seem to fail");
    // }

    {
        string table = "items";
        string[] columns = [
            "title", "description", "priority","updated_tm", "created_tm"
        ];
        string[] values = [
            "title second", "desc second", "2", "NOW()", "NOW()"
        ];
        string primary_key = "id";
        auto auto_pk_value = dbh.insert(table, primary_key, columns, values);
        tap.ok(auto_pk_value.length == 36, "length of the primary key is 36");
    }

    {
        auto sth = dbh.prepare("select title from items order by created_tm");
        sth.execute([]);
        auto result = sth.fetchall();
        tap.ok(result[0][0] == "title first", "first record looks fine");
        tap.ok(result[1][0] == "title second", "second record looks fine");
    }

    {
        auto result = dbh.selectall(
            "select * from items where priority=2"
        );
        tap.ok(result[0][1] == "title second", "plain query with selectall");
    }

    {
        string query = "select * from items order by created_tm asc";
        string[string][] result = dbh.selectall_assoc(query);
        tap.ok(result[0]["title"] == "title first", "selectall_assoc result first record title column looks fine");
        tap.ok(result[0]["priority"] == "1", "selectall_assoc result first record priority column looks fine");
        tap.ok(result[1]["title"] == "title second", "selectall_assoc result sercond record title column looks fine");
        tap.ok(result[1]["priority"] == "2", "selectall_assoc result second record priority column looks fine");
    }

    {
        string[string][] result = dbh.selectall_assoc(
            "select * from items where title = $1",
            ["title first"]
        );
        tap.ok(result[0]["title"] == "title first", "selectall_assoc seems to work with bound params");
    }

    {
        string[string][] result = dbh.selectall_assoc(
            "select * from items where title = $1 and priority = $2",
            ["title second", "2" ]
        );
        tap.ok(result[0]["title"] == "title second");
    }

/*
// TODO investigate this date/timestamp, see if it is reliable
   {
        string[string][] res_assoc_array = dbh.selectall_assoc(
            "select * from items where updated_tm <= $1", ["2016-12-27"]
        );

//    Postgres does this in the background when the timestamp param is not complete:
//    LOG:  execute <unnamed>: select * from items where updated_tm <= $1
//    DETAIL:  parameters: $1 = '2016-12-27 00:00:00'

        tap.do_debug( symdbi.util.dumper(res_assoc_array) );
    };
    */
    {
        string table = "items";
        string[] columns = [
            "title", "description", "priority","updated_tm", "created_tm"
        ];
        string[] values = [
            "tile inserted 1", "desc inserted 1", "1", "NOW()", "NOW()"
        ];
        string primary_key = "id";
        auto auto_pk_value = dbh.insert(table, primary_key, columns, values);

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
    {
        // cleanup
        bool truncated = dbh.do_command("truncate table items");
        tap.ok(truncated, "truncate table items returned true");
        auto result = dbh.selectall("select count(*) from items as total_number");
        tap.ok(result == [["0"]], "table was indeed truncated");
    }
}

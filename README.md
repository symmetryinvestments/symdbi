# symdbi

# STATUS

experimental

wrapper over derelict-pq aimed at providing an easy to use API

# DESCRIPTION

the current API is heavily inspired from https://metacpan.org/pod/DBI

To run the tests under t/ make sure they're executable or run with dub

To run all the tests under t/ install prove from Test::More from CPAN or proved from 
  zug-tap and run them in the root of the project

As of now all parameters to use in a query should be strings, all the values returned are strings. Using 
other types is TODO.

# SYNOPSYS

```
import symdbi.pg;

dsn conn_info = new dsn([
    "host": "localhost",
    "port": "5432",
    "user": "test_user",
    "password": "asdf1234#",
    "dbname":"test_db",
]);

STH sth = dbh.prepare("select * from items");
// all queries should have bound parameters, no interpolation
sth.execute([]);
// fetchall* work with the result of prepare, 
// selectall* do everything inside so you don't have to think about the details 
string[string][] result = sth.fetchall_assoc();

// example of bound parameters
STH sth = dbh.prepare(
    "select * from items where priority=$1 and title=$2"
);
sth.execute(["2", "second"]);
string[string][] result = sth.fetchall_assoc();


// doing it all in one call
string[string][] res_assoc_array_new = dbh.selectall_assoc(
    "select * from items where title = $1",
    ["first"]
);

// inserts

string table = "items";
string[] columns = [
    "title", "description", "priority","updated_tm", "created_tm"
];
string[] values = [
    "tile inserted 1", "desc inserted 1", "1", "NOW()", "NOW()"
];
string primary_key = "id";
auto auto_pk_value = dbh.insert(table, primary_key, columns, values);

```

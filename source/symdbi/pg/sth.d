module symdbi.pg.sth;

import symdbi;
import symdbi.pg;
import std.conv;
import std.string;
import std.stdio;
import core.stdc.stdlib;

import symdbi.util;

class STH
{
    private:
        string query;
        DBH dbh;
        PGresult* res;
        int param_no;
    public:

    this(string query, DBH dbh) {
        this.query = query;
        this.dbh = dbh;
    }

    PGresult* result ()
    {
        return this.res;
    }

    void result (PGresult* res)
    {
        this.res = res;
    }

    bool execute(string[] params) {

        const(char)*[] params_pq;
        foreach (string param; params) {
            params_pq ~= toStringz(param);
        }

        if (!this.param_no) {
            this.param_no = cast(int) params.length;
        } else {
            if (this.param_no != cast(int) params.length) {
                throw new Exception(
                    "Expecting " ~ to!string(this.param_no)
                    ~ " parameters, but received " ~ to!string(params.length)
                );
            }
        }

        write_debug("TODO give real names to these vars");
        const(int)* const_int_pointer = null;

        this.res = PQexecPrepared(
            this.dbh.get_handle(), "",
            cast(int) params.length,
            params_pq.ptr,
            const_int_pointer,
            const_int_pointer,
            0
        );

        if (PQresultStatus(res) != PGRES_TUPLES_OK)
        {
            stderr.writef(
                "Query failed: %s", to!string( PQerrorMessage(this.dbh.handle) )
            );
            PQclear(res);
            exit(-1);
        }

        return true;
    }

    string[][] fetchall_arrayref() {
        return this.dbh.fetchall_arrayref(this.res);
    }

    string[string][] fetchall_hashref() {
        return this.dbh.fetchall_hashref(this.res);
    }

    string[] fetchrow_arrayref() {
        return [ "mock"];
    }

    string[string] fetchrow_hashref() {
        return["mocked_key":"mocked_value"];
    }
}

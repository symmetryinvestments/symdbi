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

    // this expects a result to be returned
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

        const(int)* param_length = null;
        const(int)* param_formats = null;
        this.res = PQexecPrepared(
            this.dbh.get_handle(), "",
            cast(int) params.length,
            params_pq.ptr,
            param_length,
            param_formats,
            0
        );

        if (PQresultStatus(res) != PGRES_TUPLES_OK)
        {
            stderr.writef(
                ">>> Query failed: %s\n", to!string( PQerrorMessage(this.dbh.handle) )
            );
            PQclear(res);
            return false;
        }
        return true;
    }

    string[][] fetchall() {
        return this.dbh.fetchall(this.res);
    }

    string[string][] fetchall_assoc() {
        return this.dbh.fetchall_assoc(this.res);
    }

    string[] fetchrow() {
        return [ "mock"];
    }

    string[string] fetchrow() {
        return["mocked_key":"mocked_value"];
    }
}

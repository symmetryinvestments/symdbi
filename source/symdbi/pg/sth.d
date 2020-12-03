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

        const(char)* stmt_name = ""; // TODO allow setting up the statement name
        const(int)* param_length = null;
        const(int)* param_formats = null;
        this.res = PQexecPrepared(
            this.dbh.get_handle(),
            stmt_name,
            cast(int) params.length,
            params_pq.ptr,
            param_length,
            param_formats,
            0
        );

        if (PQresultStatus(this.res) != PGRES_TUPLES_OK)
        {
            throw new Exception(format!"Query failed: %s"(PQerrorMessage(this.dbh.get_handle).to!string));
        }
        return true;
    }

    string[][] fetchall() {
        return this.dbh.fetchall(this.res);
    }

    string[string][] fetchall_assoc() {
        return this.dbh.fetchall_assoc(this.res);
    }

    /// fetchrow is for queries which should return a single row
    /// of course you can use it to get the first row of a multirow result and abandon there rest if you so choose
    string[] fetchrow() {
        return this.dbh.fetchall(this.res)[0];
    }

    string[string] fetchrow_assoc() {
        return this.dbh.fetchall_assoc(this.res)[0];
    }
}

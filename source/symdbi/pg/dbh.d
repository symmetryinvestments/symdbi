module symdbi.pg.dbh;

import symdbi;
import symdbi.pg;
import std.conv;
import std.string;
import std.stdio;
import core.stdc.stdlib;
import std.algorithm;

import symdbi.util;

class DBH
{
    dsn connection_info;
    private bool do_debug = false;
    PGconn* handle;
    private int result_format = 0; // 0 text; 1 binary

    PGconn* get_handle() {
        return this.handle;
    }

    STH prepare(string query)
    {
        if (this.do_debug) {
            stderr.writeln(query);
        }

        const(uint)* OID = null;
        const(int)* const_int_pointer = null;

        PGresult* prep_res = PQprepare(
            this.handle,
            "",
            toStringz(query),
            cast(int) null,
            OID
        );

        if (PQresultStatus(prep_res) != PGRES_COMMAND_OK)
        {
            throw new Exception(format!"Query failed: %s"(PQerrorMessage(this.handle).to!string));
        }

        return new STH(query, this);
    }

    void process_result(PGresult* res, void delegate(PGresult*, int) process)
    {

        auto columns_info = this.columns_info_from_result(res);

        for (int row_no = 0; row_no < PQntuples(res); row_no++)
        {
            process(res, row_no);
            for (int col_no = 0; col_no < columns_info.length; col_no++)
            {
                const(ubyte)* value_ptr = PQgetvalue(res, row_no, col_no);
                int value_length = PQgetlength(res, row_no, col_no);
                ubyte[] value = cast(ubyte[]) value_ptr[0..value_length];
            }
        }

        PQclear(res);
    }


    ResultColumn[] columns_info_from_result (PGresult* res)
    {
        int number_of_columns = PQnfields(res);
        ResultColumn[] columns_info;
        ResultColumn row;

        for (int column_no = 0; column_no < number_of_columns; column_no++) {
            row.name = to!string(PQfname(res, column_no));
            row.format = to!int( PQfformat(res, column_no));
            row.type = to!int( PQftype(res, column_no) );
            row.size = to!int(PQfsize(res, column_no) );
            columns_info ~= row;
        }

        return columns_info;
    }

    // queries which return data
    PGresult* query(string query)
    {
        PGresult* res = PQexec(this.handle, query.toStringz );
        if (PQresultStatus(res) != PGRES_TUPLES_OK)
        {
            throw new Exception(format!"Query failed: %s"(PQerrorMessage(this.handle).to!string));
        }

        return res;
    }

    void insert(string query, string[] params)
    {

    }

    string[][] selectall(string query, string[] params)
    {
        if(this.do_debug) {
            writeln(query, params);
        }

        PGresult* res = this.exec_with_params(query, params);

        return this.fetchall(res);
    }

    string[][] selectall(string query)
    {
        if(this.do_debug) {
            writeln(query);
        }

        PGresult* res = this.query(query);

        return this.fetchall(res);
    }

    string[][] fetchall(PGresult* res) {
        ResultColumn[] columns_info = columns_info_from_result(res);

        string[][] all_rows;

        void delegate(PGresult*, int) callback = (PGresult* db_res, int row_no) {
            string[] row_info;

            for (int col_no = 0; col_no < columns_info.length; col_no++) {
                const(ubyte)* value_ptr = PQgetvalue(db_res, row_no, col_no);
                int value_length = PQgetlength(db_res, row_no, col_no);
                ubyte[] value = cast(ubyte[]) value_ptr[0..value_length];
                row_info ~= cast(string) value;
            }
            all_rows ~= row_info;
        };

        this.process_result(res, callback);

        return all_rows;
    }

    // https://www.postgresql.org/docs/9.5/static/libpq-example.html
    // Example 31-3. libpq Example Program 3
    string[string][] selectall_assoc(string query, string[] params)
    {

        if(this.do_debug) {
            writeln(query, params);
        }

        PGresult* res = this.exec_with_params(query, params);

        return this.fetchall_assoc(res);
    }

    PGresult* exec_with_params(string query, string[] params) {

        const(ubyte)*[] params_pq = new const(ubyte)* [params.length];
        for (int i = 0; i < params.length; i++ )
        {
            string param = params[i];
            param ~= '\0';
            params_pq[i] = cast(const(ubyte)*) param;
        }

        int result_format = this.result_format; // text
        const uint* param_types; /* let the backend deduce param type */
        const int *param_lengths; /* don't need param lengths since text */
        const int *param_formats; /* default to all text params */

        /* requires (
           PGconn*,
           const(char)*,
           int,
           const(uint)*,
           const(ubyte*)*,
           const(int)*,
           const(int*),
           int)
        */

        PGresult* res = PQexecParams(
            this.handle,
            toStringz(query),
            cast(int) params.length,
            param_types,
            &params_pq[0],  // pointer to the first element of the array
            param_lengths,
            param_formats,
            result_format
        );

        if (PQresultStatus(res) != PGRES_TUPLES_OK)
        {
            throw new Exception(format!"Query failed: %s"(PQerrorMessage(this.handle).to!string));
        }

        return res;
    }

    string[string][] selectall_assoc(string query) {

        if(this.do_debug) {
            writeln(query);
        }

        auto res = this.query(query);

        return this.fetchall_assoc(res);
    }

    string[string][] fetchall_assoc(PGresult* res) {
        ResultColumn[] columns_info = columns_info_from_result(res);

        string[string][] all_rows;

        void delegate(PGresult*, int) callback = (db_res, row_no) {
            string[string] row_info;

            for (int col_no = 0; col_no < columns_info.length; col_no++) {
                const(ubyte)* value_ptr = PQgetvalue(db_res, row_no, col_no);
                int value_length = PQgetlength(db_res, row_no, col_no);
                ubyte[] value = cast(ubyte[]) value_ptr[0..value_length];
                row_info[columns_info[col_no].name] = cast(string) value;
            }
            all_rows ~= row_info;
        };

        this.process_result(res, callback);

        return all_rows;
    }

    // queries which don't return data
    bool do_command(string query)
    {

        if(this.do_debug)
        {
            writeln(query);
        }

        auto res = PQexec(this.handle, toStringz( query ));
        if (PQresultStatus(res) != PGRES_COMMAND_OK)
        {
            stderr.writef(
                "Command failed: %s", to!string( PQerrorMessage(this.handle) ));
            PQclear(res);
            return false;
        }

        write_debug("TODO: finish do_command ... if it is really needed");
        return true;
    }


    string insert(
            string table_name,
            string primary_key,
            string[string] data,
        ) {
        import std.array: array;


        string[] placeholders;
        string[] columns = data.keys;
        // not relying on the values being ordered same as the columns
        string[] values = columns.map!(column => data[column]).array;
        // $1, $2 etc. is how Postgresql is counting the bound parameters
        for ( int i = 1; i <= columns.length; i++ ) {
            placeholders ~= "$" ~ i.to!string;
        }

        string query =
            "insert into " ~ table_name
                ~ " (" ~ columns.join(",") ~ ")"
                ~ " values (" ~ placeholders.join(", ") ~ ") "
                ~ " returning " ~ primary_key;

        string query_debug =
            "insert into " ~ table_name
                ~ " (" ~ columns.join(",") ~ ")"
                ~ " values (" ~ values.join(", ") ~ ") "
                ~ " returning " ~ primary_key;
        write_debug(query_debug);

        auto sth = this.prepare(query);
        sth.execute(values);
        auto result = sth.fetchall();
        return result[0][0];
    }


    string[][] insert(string table_name, string primary_key, string[string][] data) {

        string[] columns = data[0].keys;

        // $1, $2 etc. is how Postgresql is counting the bound parameters
        int i = 1;

        string[] placeholders;
        string[] values;
        for (int row = 0; row < data.length; row++) {
            string[] placeholders_for_one_row;
            for (int column = 0; column < columns.length; column++) {
                placeholders_for_one_row ~= "$" ~ i.to!string;
                values ~= data[row][columns[column]];
                i++;
            }
            placeholders ~= "(" ~ placeholders_for_one_row.join(",") ~ ")";
        }

        string query = "insert into " ~ table_name ~ " (" ~ columns.join(",") ~ " )"
            ~ " values " ~ placeholders.join(", ") ~ " returning " ~ primary_key;
        write_debug(query);
        auto sth = this.prepare(query);
        sth.execute(values);
        return sth.fetchall();
    }


    void expect_text_result() {
        this.result_format = 0;
    }

    void expect_binary_result() {
        this.result_format = 1;
    }

    void debugging( bool enable)
    {
        this.do_debug = enable;
    }

    this(dsn conn_info)
    {
        handle = PQconnectdb( toStringz(conn_info.connection_string()) );

        if (PQstatus(this.handle) != CONNECTION_OK)
        {
            stderr.writef(
                "Connection to database failed: %s ",
                to!string( PQerrorMessage(this.handle) )
            );
            exit(-1);
        }
    }

    ~this()
    {
        PQfinish( this.handle );
    }


    /// the rest of the functions are about how PG is seeing you
    string effective_name()
    {
        return to!string(PQdb(this.handle));
    }

    string effective_user()
    {
        return to!string(PQuser(this.handle));
    }

    string effective_pass()
    {
        return to!string(PQpass(this.handle));
    }

    string effective_host()
    {
        return to!string(PQhost(this.handle));
    }

    string effective_port()
    {
        return to!string(PQport(this.handle));
    }

    string effective_options()
    {
        return to!string(PQoptions(this.handle));
    }

    ConnStatusType status()
    {
        return PQstatus(this.handle);
    }

}

T[] select(T)(DBH dbh, string query)
if (is(T == struct))
{
    if(dbh.do_debug) {
        writeln(query);
    }

    PGresult* res = dbh.query(query);

    return dbh.fetch!T(res);
}

T[] fetch(T)(DBH dbh, PGresult* result)
if (is(T == struct))
{

    ResultColumn[] columns_info = dbh.columns_info_from_result(result);

    T[] all_rows;

    void delegate(PGresult*, int) callback = (PGresult* db_res, int row_no) {

        // so I won't forget what a two-dimensional array of unsigned bytes means
        alias raw_field_value = ubyte[];
        raw_field_value[string] raw_row_data;

        for ( int col_no = 0; col_no < columns_info.length; col_no++ ) {

            string column_name = columns_info[col_no].name;

            const(ubyte)* value_ptr = PQgetvalue(db_res, row_no, col_no);
            int value_length = PQgetlength(db_res, row_no, col_no);
            ubyte[] value = cast(ubyte[]) value_ptr[0..value_length];

            raw_row_data[ column_name ] ~= value;
        }

        T row_struct = T(raw_row_data);
        all_rows ~= row_struct;
    };

    dbh.process_result(result, callback);

    return all_rows;
}

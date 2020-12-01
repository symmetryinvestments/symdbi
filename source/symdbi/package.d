module symdbi;

import std.string;
import std.array;
import std.stdio;
import std.conv;

class dsn
{
    private string host;
    private string port = "5432";
    private string dbname;
    private string user;
    private string password;

    this(string dbname)
    {
        this.dbname = dbname;
    }

    this(string[string] conn_info)
    {
        this.host     = conn_info["host"];
        this.port     = conn_info["port"];
        this.dbname   = conn_info["dbname"];
        this.user     = conn_info["user"];
        this.password = conn_info["password"];
    }

    string connection_string() {
        string[] info;
        if (this.host !is null) info     ~= "host=" ~ this.host;
        if (this.port !is null) info     ~= "port=" ~ this.port;
        if (this.dbname !is null) info   ~= "dbname=" ~ this.dbname;
        if (this.user !is null) info     ~= "user=" ~ this.user;
        if (this.password !is null) info ~= "password=" ~ this.password;
        return  std.array.join(info, " ");
    }
}

// https://www.postgresql.org/docs/9.1/static/libpq-exec.html
struct ResultColumn
{
    string name; // PQfname
    // PQfformat: Format code zero indicates textual data representation,
    //   while format code one indicates binary representation.
    //  (Other codes are reserved for future definition.)
    int format;  
    int type;    // PQftype
    int size;    // PQfsize
}

struct ConnectionStatus
{
    string host;
    string port;
    string dbname;
    string user;
    string password;
    
    string info() {
        return "Effective db connection: postgresql://"
            ~ this.user ~ ":" ~ this.password
            ~ "@" ~ this.host ~ ":" ~ this.port ~ "/" ~ this.dbname;
    }
}


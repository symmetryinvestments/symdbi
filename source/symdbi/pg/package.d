module symdbi.pg;

import std.stdio;

public {
    import derelict.pq.pq;
    import symdbi;
    import symdbi.pg.dbh;
    import symdbi.pg.sth;
}

shared static this()
{
    DerelictPQ.load();
}

//shared static ~this()
//{
//    stderr.writeln("unloading derelict pq");
//}
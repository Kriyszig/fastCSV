import magpie.dataframe;
import std.datetime.stopwatch : benchmark, StopWatch, AutoStart;
import std.stdio: writeln;

void main()
{
    DataFrame!(double, 5) df;
    auto sw = StopWatch(AutoStart.no);

    sw.start();
    df.fastCSV("./test/dataset_large.csv", 1, 1);
    sw.stop();
    writeln("fastCSV on large dataset: ", sw.peek.total!"msecs"/1000.0);

    assert(df.rows == 2_000_000);
    assert(df.data[4][1_999_999] == 4.72);

    DataFrame!(double, 5) dfs;
    sw.reset();

    sw.start();
    dfs.from_csv("./test/dataset_small.csv", 1, 1);
    sw.stop();
    writeln("from_csv on small dataset: ", sw.peek.total!"msecs"/1000.0);

    assert(dfs.rows == 50_000);
    assert(dfs.data[4][49_999] == 5.2);
}
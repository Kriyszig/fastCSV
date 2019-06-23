# Magpie fastCSV test

[Magpie](https://github.com/Kriyszig/magpie) is a project that brings DataFrames to D Programming Language ecosystem.

This repository is a test repository for Magpie's CSV parser. The initial parser does well enough in scenarios with small data
but with larger data, time to parse CSV increases exponentially. A file with 100000 rows can take about 5 minutes to parse using
`from_csv`.

As a replacement, `fastCSV` was introduced. It is not the fastest CSV parser but is miles ahead of `from_csv`

### Benchmarks

| Parser              | File                              | Time Taken  |
| ------------------- |:---------------------------------:| -----------:|
| from_csv - dmd      | dataset_small.csv (50,000 x 5)    | 21.437 sec  |
| fastCSV - dmd       | dataset_large.csv (2,000,000 x 5) | 17.365 sec  |
| from_csv - dmd-beta | dataset_small.csv (50,000 x 5)    | 21.380 sec  |
| fastCSV - dmd-beta  | dataset_large.csv (2,000,000 x 5) | 18.371 sec  |
| from_csv - ldc      | dataset_small.csv (50,000 x 5)    | 17.772 sec  |
| fastCSV - ldc       | dataset_large.csv (2,000,000 x 5) | 24.855 sec  |

These results can be verified from Travis CI [build logs](https://travis-ci.com/Kriyszig/fastCSV/builds/116561067)

Unfortunately `from_csv` cannot parse `dataset_large.csv` within this decade. `from_csv` parsing time increases exponentially. A file
100,000 row long will take about 6 minutes to parse.

On `dmd`, `fastCSV` can parse about 40x data in 75% of the time taken by `from_csv`. On `ldc` it takes 133% of time to parse 40x
data.

<b>Note:</b> These are single thread performances as buth of the algorithm uses only one thread to read the CSV files. 

private alias toArr(T) = T[];

/++
The DataFrame Structure
+/
struct DataFrame(FrameFields...)
    if(FrameFields.length > 0
    && ((!isType!(FrameFields[0]) && is(typeof(FrameFields[0]) == bool) && FrameFields[0] == true && FrameFields.length > 1)
    || isType!(FrameFields[0])))
{
    static if(!isType!(FrameFields[0]) && is(typeof(FrameFields[0]) == bool) && FrameFields[0] == true)
        alias RowType = FrameFields[1 .. $];
    else
        alias RowType = getArgsList!(FrameFields);

    alias FrameType = staticMap!(toArr, RowType);

    ///
    size_t rows = 0;
    ///
    size_t cols = RowType.length;

    /// DataFrame indexing
    Index indx;
    /// DataFrame Data
    FrameType data;

private:
    int getPosition(int axis)(string[] index)
    {
        import std.array: appender;
        import std.algorithm: countUntil;
        import std.conv: to;
        auto codes = appender!(int[]);

        foreach(i; 0 .. indx.indexing[axis].codes.length)
        {
            if(indx.indexing[axis].index[i].length == 0)
                codes.put(to!int(index[i]));
            else
            {
                int indxpos = cast(int)countUntil(indx.indexing[axis].index[i], index[i]);
                if(indxpos < 0)
                    return -1;
                codes.put(indxpos);
            }
        }

        foreach(i; 0 .. (axis == 0)? rows: cols)
        {
            bool flag = true;
            foreach(j; 0 .. indx.indexing[axis].codes.length)
            {
                if(indx.indexing[axis].codes[j][i] != codes.data[j])
                    flag = false;
            }

            if(flag)
                return cast(int)i;
        }

        return -1;
    }

public:
    /++
    auto display(bool getStr = false, int maxwidth = 0)
    Description: Converts the given DataFrame into a formatted string to display on the terminal
    @params: getStr - returns the string generated.
    @params: maxwidth - override the width of the terminal.
    +/
    auto display(bool getStr = false, int maxwidth = 0)
    {
        if(rows == 0)
        {
            if(!getStr)
            {
                import std.stdio: writeln;
                writeln("Empty DataFrmae");
            }
            return "";
        }

        const uint terminalw = (maxwidth > 100)? maxwidth: 200;
        const uint maxColSize = 43;
        auto gaps = appender!(size_t[]);

        size_t top, bottom;
        const size_t totalHeight = rows + indx.column.index.length +
            ((indx.row.titles.length > 0 && indx.column.titles.length > 0)? 1: 0);
        const size_t totalWidth = cols + indx.row.index.length;

        if(totalHeight > 50)
        {
            top = 25;
            bottom = 25;
        }
        else
        {
            top = totalHeight;
            bottom = 0;
        }

        import std.algorithm: map, reduce, max;
        import std.conv: to;
        size_t dataIndex = 0;
        foreach(i; 0 .. totalWidth)
        {
            int extra = (indx.row.titles.length > 0 && indx.column.titles.length > 0)? 1: 0;
            if(i < indx.row.index.length)
            {
                size_t thisGap = (i < indx.row.titles.length && top > indx.column.index.length + extra)? indx.row.titles[i].length: 0;
                if(top > indx.column.index.length + extra)
                {
                    size_t tmp = 0;
                    if(indx.row.codes[i].length == 0)
                        tmp = indx.row.index[i][0 .. top - indx.column.index.length - extra].map!(e => e.length).reduce!max;
                    else if(indx.row.index[i].length == 0)
                        tmp = indx.row.codes[i][0 .. top - indx.column.index.length - extra].map!(e => to!string(e).length).reduce!max;
                    else
                        tmp = indx.row.codes[i][0 .. top - indx.column.index.length - extra].map!(e => indx.row.index[i][e].length).reduce!max;

                    if(tmp > thisGap)
                    {
                        thisGap = tmp;
                    }
                }

                if(bottom > 0)
                {
                    if(bottom > indx.row.index[i].length)
                    {
                        size_t tmp = 0;
                        if(indx.row.codes[i].length == 0)
                            tmp = indx.row.index[i].map!(e => e.length).reduce!max;
                        else if(indx.row.index[i].length == 0)
                            tmp = indx.row.codes[i].map!(e => to!string(e).length).reduce!max;
                        else
                            tmp = indx.row.codes[i].map!(e => indx.row.index[i][e].length).reduce!max;

                        if(tmp > thisGap)
                        {
                            thisGap = tmp;
                        }
                    }
                    else
                    {
                        size_t tmp = 0;
                        if(indx.row.codes[i].length == 0)
                            tmp = indx.row.index[i][$ - bottom .. $].map!(e => e.length).reduce!max;
                        else if(indx.row.index[i].length == 0)
                            tmp = indx.row.codes[i][$ - bottom .. $].map!(e => to!string(e).length).reduce!max;
                        else
                            tmp = indx.row.codes[i][$ - bottom .. $].map!(e => indx.row.index[i][e].length).reduce!max;

                        if(tmp > thisGap)
                        {
                            thisGap = tmp;
                        }
                    }
                }

                if(i == indx.row.index.length - 1 && indx.column.titles.length > 0)
                {
                    const auto tmp = (indx.column.titles.length > top)
                        ? indx.column.titles[0 .. top].map!(e => e.length).reduce!max
                        : indx.column.titles.map!(e => e.length).reduce!max;

                    if(tmp > thisGap)
                    {
                        thisGap = tmp;
                    }
                }

                gaps.put((thisGap < maxColSize)? thisGap: maxColSize);
            }
            else
            {
                size_t maxGap = 0;
                foreach(j; 0 .. (top > indx.column.index.length)? indx.column.index.length: top)
                {
                    size_t lenCol = 0;
                    if(indx.column.codes[j].length == 0)
                        lenCol = indx.column.index[j][dataIndex].length;
                    else if(indx.column.index[j].length == 0)
                        lenCol = to!string(indx.column.codes[j][dataIndex]).length;
                    else
                        lenCol = indx.column.index[j][indx.column.codes[j][dataIndex]].length;

                    maxGap = (maxGap > lenCol)? maxGap: lenCol;
                }

                foreach(j; totalHeight - bottom .. indx.column.index.length)
                {
                    size_t lenCol = 0;
                    if(indx.column.codes[j].length == 0)
                        lenCol = indx.column.index[j][dataIndex].length;
                    else if(indx.column.index[j].length == 0)
                        lenCol = to!string(indx.column.codes[j][dataIndex]).length;
                    else
                        lenCol = indx.column.index[j][indx.column.codes[j][dataIndex]].length;

                    maxGap = (maxGap > lenCol)? maxGap: lenCol;
                }

                static foreach(j; 0 .. RowType.length)
                {
                    if(j == dataIndex)
                    {
                        size_t maxsize = data[j].map!(e => to!string(e).length).reduce!max;
                        if(maxsize > maxGap)
                        {
                            maxGap = maxsize;
                        }
                    }
                }

                gaps.put((maxGap < maxColSize)? maxGap: maxColSize);
                ++dataIndex;
            }
        }

        auto cwidth = gaps.data;
        size_t left = 0, right = 0;
        int wOccupied = 0;
        foreach(i; cwidth)
        {
            if(wOccupied + i + 4 < terminalw/2)
            {
                wOccupied += i + 2;
                left++;
            }
            else
                break;
        }

        wOccupied = 0;
        foreach_reverse(i; cwidth)
        {
            if(wOccupied + i + 5 < terminalw/2)
            {
                wOccupied += i + 2;
                right++;
            }
            else
                break;
        }

        if(left + right > cwidth.length)
        {
            left = cwidth.length;
            right = 0;
        }

        auto dispstr = appender!string;
        foreach(ele; [[0, top], [totalHeight - bottom, totalHeight]])
        {
            const int extra = (indx.row.titles.length > 0 && indx.column.titles.length > 0)? 1: 0;
            if(ele[0] < indx.column.index.length + extra)
            {
                dataIndex = 0;
            }
            else
            {
                dataIndex = ele[0] - (indx.column.index.length + extra);
            }
            foreach(i; ele[0] .. ele[1])
            {
                bool skipIndex = true;
                foreach(lim; [[0, left], [totalWidth - right, totalWidth]])
                {
                    foreach(j; lim[0] .. lim[1])
                    {
                        if(i < indx.column.index.length)
                        {
                            if(j < indx.row.index.length)
                            {
                                if(j == indx.row.index.length - 1
                                    && indx.column.titles.length != 0)
                                {
                                    if(indx.column.titles[i].length > maxColSize)
                                    {
                                        dispstr.put(indx.column.titles[i][0 .. maxColSize]);
                                        dispstr.put("  ");
                                    }
                                    else
                                    {
                                        dispstr.put(indx.column.titles[i]);
                                        foreach(k;indx.column.titles[i].length .. cwidth[j] + 2)
                                        {
                                            dispstr.put(" ");
                                        }
                                    }
                                }
                                else if(i == indx.column.index.length - 1
                                    && indx.column.titles.length == 0)
                                {
                                    if(indx.row.titles[j].length > maxColSize)
                                    {
                                        dispstr.put(indx.row.titles[j][0 .. maxColSize]);
                                        dispstr.put("  ");
                                    }
                                    else
                                    {
                                        dispstr.put(indx.row.titles[j]);
                                        foreach(k; indx.row.titles[j].length .. cwidth[j] + 2)
                                        {
                                            dispstr.put(" ");
                                        }
                                    }
                                }
                                else
                                {
                                    foreach(k; 0 .. cwidth[j] + 2)
                                    {
                                        dispstr.put(" ");
                                    }
                                }
                            }
                            else
                            {
                                string colindx ="";
                                if(indx.column.codes[i].length == 0)
                                    colindx = indx.column.index[i][j - indx.row.index.length];
                                else if(indx.column.index[i].length == 0)
                                    colindx = to!string(indx.column.codes[i][j - indx.row.index.length]);
                                else
                                    colindx = indx.column.index[i][indx.column.codes[i][j - indx.row.index.length]];

                                if(colindx.length > maxColSize)
                                {
                                    dispstr.put(colindx[0 .. maxColSize]);
                                    dispstr.put("  ");
                                }
                                else
                                {
                                    dispstr.put(colindx);
                                    foreach(k; colindx.length .. cwidth[j] + 2)
                                    {
                                        dispstr.put(" ");
                                    }
                                }
                            }
                        }
                        else if(i == indx.column.index.length && indx.column.titles.length != 0)
                        {
                            if(j < indx.row.titles.length)
                            {
                                if(indx.row.titles[j].length > maxColSize)
                                {
                                    dispstr.put(indx.row.titles[j][0 .. maxColSize]);
                                    dispstr.put("  ");
                                }
                                else
                                {
                                    dispstr.put(indx.row.titles[j]);
                                    foreach(k; indx.row.titles[j].length .. cwidth[j] + 2)
                                    {
                                        dispstr.put(" ");
                                    }
                                }
                            }
                        }
                        else
                        {
                            if(j < indx.row.index.length)
                            {
                                string idx = "";
                                if(indx.row.codes[j].length == 0)
                                    idx = indx.row.index[j][dataIndex];
                                else if(indx.row.index[j].length == 0)
                                    idx = to!string(indx.row.codes[j][dataIndex]);
                                else if(dataIndex > 0 && j < indx.row.index.length
                                    && indx.row.codes[j][dataIndex] == indx.row.codes[j][dataIndex - 1]
                                    && skipIndex && indx.isMultiIndexed)
                                    idx = "";
                                else
                                {
                                    idx = indx.row.index[j][indx.row.codes[j][dataIndex]];
                                    skipIndex = false;
                                }

                                if(idx.length > maxColSize)
                                {
                                    dispstr.put(idx[0 .. maxColSize]);
                                    dispstr.put("  ");
                                }
                                else
                                {
                                    dispstr.put(idx);
                                    foreach(k; idx.length .. cwidth[j] + 2)
                                    {
                                        dispstr.put(" ");
                                    }
                                }
                            }
                            else
                            {
                                string idx = "";
                                static foreach(k; 0 .. RowType.length)
                                {
                                    if(k == j - indx.row.index.length)
                                        idx = to!string(data[k][dataIndex]);
                                }

                                if(idx.length > maxColSize)
                                {
                                    dispstr.put(idx[0 .. maxColSize]);
                                    dispstr.put("  ");
                                }
                                else
                                {
                                    dispstr.put(idx);
                                    foreach(k; idx.length .. cwidth[j] + 2)
                                    {
                                        dispstr.put(" ");
                                    }
                                }
                            }
                        }
                    }
                    if(right > 0 && lim[0] == 0)
                    {
                        dispstr.put("...  ");
                    }
                }
                dispstr.put("\n");
                if(i >= indx.column.index.length + extra)
                    ++dataIndex;
            }
            if(bottom > 0 && ele[0] == 0)
            {
                foreach(i; 0 .. left)
                {
                    foreach(j; 0 .. cwidth[i])
                        dispstr.put(".");
                    dispstr.put("  ");
                }

                if(right > 0)
                {
                    dispstr.put("...  ");
                }

                foreach(i; cwidth.length - right .. cwidth.length)
                {
                    foreach(j; 0 .. cwidth[i])
                        dispstr.put(".");
                    dispstr.put("  ");
                }
                dispstr.put("\n");
            }
        }

        import std.stdio: writeln;
        if(!getStr)
        {
            writeln(dispstr.data);
            // writeln(RowType.length);
            // writeln(gaps.data);
            // writeln(left,"\t", right);

            writeln("Dataframe Dimension: [ ", totalHeight," X ", totalWidth, " ]");
            writeln("Data Dimension: [ ", rows," X ", cols, " ]");
        }
        return ((getStr)? dispstr.data: "");
    }

    /++
    void to_csv(string path, bool writeIndex = true, bool writecolumn.index = true, char sep = ',')
    Description: Writes given DataFrame to a CSV file
    @params: path - path to the output file
    @params: writeIndex - write row index to the file
    @params: writecolumn.index - write column index to the file
    @params: sep - data seperator
    +/
    void to_csv(string path, bool writeIndex = true, bool writeColumn = true, char sep = ',')
    {
        import std.array: appender;
        import std.conv: to;

        auto formatter = appender!(string);
        const size_t totalHeight = rows + indx.column.index.length +
            ((indx.row.titles.length > 0 && indx.column.titles.length > 0)? 1: 0);

        if(rows == 0)
        {
            return;
        }

        if(writeColumn)
        {
            foreach(i; 0 .. indx.column.index.length)
            {
                if(writeIndex)
                {
                    foreach(j; 0 .. indx.row.index.length)
                    {
                        if(i != indx.column.index.length - 1 && j < indx.row.index.length - 1)
                        {
                            formatter.put(sep);
                        }
                        else if(i == indx.column.index.length - 1 && indx.column.titles.length == 0)
                        {
                            formatter.put(indx.row.titles[j]);
                            formatter.put(sep);
                        }
                        else if(j == indx.row.index.length - 1 && indx.column.titles.length != 0)
                        {
                            formatter.put(indx.column.titles[i]);
                            formatter.put(sep);
                        }
                        else
                        {
                            formatter.put(sep);
                        }
                    }
                }

                foreach(j; 0 .. cols)
                {
                    string colindx ="";
                    if(indx.column.codes[i].length == 0)
                        colindx = indx.column.index[i][j];
                    else if(indx.column.index[i].length == 0)
                        colindx = to!string(indx.column.codes[i][j]);
                    else
                        colindx = indx.column.index[i][indx.column.codes[i][j]];

                    formatter.put(colindx);
                    if(j < cols - 1)
                        formatter.put(sep);
                }

                formatter.put("\n");
            }
            if(indx.column.titles.length != 0 && writeIndex)
            {
                formatter.put(indx.row.titles[0]);
                foreach(j; 1 .. indx.row.index.length)
                {
                    formatter.put(sep);
                    formatter.put(indx.row.titles[j]);
                }
                formatter.put("\n");
            }
        }

        foreach(i; 0 .. rows)
        {
            if(writeIndex)
            {
                bool skipIndex = true;
                foreach(j; 0 .. indx.row.index.length)
                {
                    string idx = "";
                    if(indx.row.codes[j].length == 0)
                        idx = indx.row.index[j][i];
                    else if(indx.row.index[j].length == 0)
                        idx = to!string(indx.row.codes[j][i]);
                    else if(i > 0 && j < indx.row.index.length
                        && indx.row.codes[j][i] == indx.row.codes[j][i - 1]
                        && skipIndex && indx.isMultiIndexed)
                        idx = "";
                    else
                    {
                        idx = indx.row.index[j][indx.row.codes[j][i]];
                        skipIndex = false;
                    }

                    formatter.put(idx);
                    formatter.put(sep);
                }
            }
            formatter.put(to!string(data[0][i]));
            static foreach(j; 1 .. RowType.length)
            {
                formatter.put(sep);
                formatter.put(to!string(data[j][i]));
            }

            formatter.put("\n");
        }

        import std.stdio: File;
        File outfile = File(path, "w");
        outfile.write(formatter.data);
        outfile.close();
    }

    /++
    void from_csv(string path, size_t indexDepth, size_t columnDepth, size_t[] column.index = [], char sep = ',')
    Description: Parsing of DataFrame from a CSV file
    @params: path - File path of csv file
    @params: indexDepth - Number of column row index span
    @params: columnDepth - Number of rows column index span
    @params: column.index - Integer row.index of column to selectively parse
    @params: sep - Data seperator in the file
    +/
    void from_csv(string path, size_t indexDepth, size_t columnDepth, size_t[] columns = [], char sep = ',')
    {
        import std.array: appender, split;
        import std.stdio: File;
        import std.string: chomp;

        if(columns.length == 0)
        {
            auto all = appender!(size_t[]);
            foreach(i; 0 .. cols)
                all.put(i);
            columns = all.data;
        }

        assert(columns.length == cols, "The dimension of columns must be same as dimension of the DataFrame");

        File csvfile = File(path, "r");
        bool bothTitle = false;
        size_t line = 0;
        indx = Index();

        foreach(i; 0 .. indexDepth)
        {
            indx.row.codes ~= [[]];
            indx.row.index ~= [[]];
        }

        size_t dataIndex = 0;
        while(!csvfile.eof())
        {
            string[] fields = chomp(csvfile.readln()).split(sep);

            if(line < columnDepth)
            {
                if(indexDepth > 0 && line == columnDepth - 1 && fields[0].length > 0)
                {
                    indx.row.titles = fields[0 .. indexDepth];
                }
                else if(indexDepth > 0 && fields[indexDepth - 1].length > 0)
                {
                    indx.column.titles ~= fields[indexDepth - 1];
                    bothTitle = true;
                }

                indx.column.index ~= [[]];
                indx.column.codes ~= [[]];
                foreach(i; 0 .. cols)
                {
                    size_t pos = columns[i];
                    string colindx = fields[indexDepth + pos];

                    if(i > 0 && colindx.length == 0)
                    {
                        indx.column.codes[line] ~= indx.column.codes[line][$ - 1];
                    }
                    else
                    {
                        import std.algorithm: countUntil;
                        int idxpos = cast(int)countUntil(indx.column.index[line], colindx);

                        if(idxpos > -1)
                        {
                            indx.column.codes[line] ~= cast(int)idxpos;
                        }
                        else
                        {
                            indx.column.index[line] ~= colindx;
                            indx.column.codes[line] ~= cast(uint)indx.column.index[line].length - 1;
                        }
                    }
                }
            }
            else if(line == columnDepth && bothTitle)
            {
                indx.row.titles = fields[0 .. indexDepth];
            }
            else
            {
                if(indexDepth == 1 && columnDepth == 1 && line == columnDepth && fields.length == 1)
                {
                    bothTitle = true;
                    indx.row.titles = fields;
                }
                else if(fields.length > 0)
                {
                    foreach(i; 0 .. indexDepth)
                    {
                        import std.algorithm: countUntil;
                        int indxpos = cast(int)countUntil(indx.row.index[i], fields[i]);
                        if(fields[i].length == 0 && dataIndex > 0)
                        {
                            indx.row.codes[i] ~= indx.row.codes[$ - 1];
                        }
                        else if(indxpos > -1)
                        {
                            indx.row.codes[i] ~= cast(uint)indxpos;
                        }
                        else
                        {
                            indx.row.index[i] ~= fields[i];
                            indx.row.codes[i] ~= cast(uint)indx.row.index[i].length - 1;
                        }
                    }

                    static foreach(i; 0 .. RowType.length)
                    {

                        if(fields.length > (columns[i] + indexDepth))
                        {
                            import std.conv: to, ConvException;

                            try
                            {
                                data[i] ~= to!(RowType[i])(fields[columns[i] + indexDepth]);
                            }
                            catch(ConvException e)
                            {
                                data[i] ~= RowType[i].init;
                            }
                        }
                        else
                        {
                            data[i] ~= RowType[i].init;
                        }
                    }
                }
            }

            if(fields.length > 0)
                ++line;
        }
        csvfile.close();

        rows = line - columnDepth - ((bothTitle)?1: 0);

        if(indexDepth == 0)
        {
            indx.row.titles ~= "Index";
            indx.row.index = [[]];
            indx.row.codes = [[]];
            foreach(i; 0 .. rows)
                indx.row.codes[0] ~= cast(uint)i;
        }

        if(columnDepth == 0)
        {
            indx.column.index = [[]];
            indx.column.codes = [[]];
            foreach(i; 0 .. indexDepth)
                indx.row.titles ~= ["Index"];
            foreach(i; 0 .. line)
                indx.column.codes[0] ~= cast(uint)i;
        }

        indx.optimize();
    }

    /++
    from_csv rebuild for faster read
    +/
    void fastCSV(string path, size_t indexDepth, size_t columnDepth, char sep = ',')
    {
        import std.array: appender, split;
        import std.stdio: File;
        import std.string: chomp;

        File csvfile = File(path, "r");
        string[][] lines;
        int totalLines = 0;

        while(!csvfile.eof())
        {
            ++lines.length;
            lines[totalLines++] = chomp(csvfile.readln()).split(sep);
        }

        indx.row.titles.length = indexDepth;
        indx.row.index.length = indexDepth;
        indx.column.index.length = columnDepth;
        indx.row.codes.length = indexDepth;
        indx.column.codes.length = columnDepth;
        indx.row.titles = lines[columnDepth - 1][0 .. indexDepth];

        foreach(i, ele; lines[0 .. columnDepth])
            indx.column.index[i] = ele[indexDepth .. $];

        foreach(i, ele; lines[columnDepth .. $])
        {
            if(ele.length > 0)
            {
                foreach(j; 0 .. indexDepth)
                {
                    ++indx.row.index[j].length;
                    indx.row.index[j][i] = ele[j];
                }

                static foreach(j; 0 .. RowType.length)
                {
                    import std.conv: to;
                    ++data[j].length;
                    if(ele[indexDepth + j].length == 0)
                        data[j][i] =  RowType[j].init;
                    else
                        data[j][i] = to!(RowType[j])(ele[indexDepth + j]);
                }
            }
        }

        rows = totalLines - columnDepth - 1;
        if(indx.row.index.length == 0)
        {
            indx.row.index.length = 1;
            indx.row.codes.length = 1;
            indx.row.codes[0].length = rows;
            foreach(i; 0 .. rows)
                indx.row.codes[0][i] = cast(int)i;

            indx.row.titles = ["Index"];
        }

        if(indx.column.index.length == 0)
        {
            indx.column.index.length = 1;
            indx.column.codes.length = 1;
            indx.column.codes[0].length = rows;
            foreach(i; 0 .. rows)
                indx.column.codes[0][i] = cast(int)i;

            indx.row.titles.length = indx.row.codes.length;
            foreach(i; 0 .. indx.row.titles.length)
            {
                import std.conv: to;
                indx.row.titles[i] = "Index" ~ to!(string)(i + 1);
            }
        }

        indx.generateCodes();
        indx.optimize();

    }
}
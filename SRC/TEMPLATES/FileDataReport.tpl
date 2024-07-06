<CODEGEN_FILENAME><STRUCTURE_NAME>_DATA_REPORT.DBL</CODEGEN_FILENAME>

import Synergex.SynergyDE.Select

.include "<STRUCTURE_NOALIAS>" repository, structure="str<StructureName>", end

main <StructureName>DataReport

    global common
        tt, i4
        ch, i4
        log, i4
        errors, i4
        initBadData, boolean
        saveRecord, boolean
    endcommon

    stack record
        selector, @Select
        enumerator, @AlphaEnumerator
        <structureName>, str<StructureName>
    endrecord
proc

    open(tt=0,i,"tt:")
    open(log=0,o:s,"<StructureName>DataReport.log")

    xcall flags(7004000,1)

    repeat
    begin
        data yn, a1
        display(tt,$SCR_CLR(SCREEN),$SCR_POS(2,1),"INIT/CLEAR bad data (Y/N): ")
        reads(tt,yn)
        if (yn=="Y"||yn=="N")
        begin
            try
            begin
                if (initBadData = (yn=="Y")) then
                begin
                    writes(log,"Opening <FILE_NAME> for exclusive write access")
                    writes(log,"Fields containing bad data WILL be initialized")
                    open(ch=0,u:i,"<FILE_NAME>",SHARE:Q_EXCL_RW)
                end
                else
                begin
                    writes(log,"Opening <FILE_NAME> for read only access")
                    writes(log,"Fields containing bad data will NOT be initialized")
                    open(ch=0,i:i,"<FILE_NAME>")
                end
            end
            catch (ex, @FileNameException)
            begin
                writes(log,"ERROR: Invalid file name")
                init ch
            end
            catch (ex, @NoFileFoundException)
            begin
                writes(log,"ERROR: File not found")
                init ch
            end
            catch (ex, @ProtectionViolationException)
            begin
                writes(log,"ERROR: protection violation")
                init ch
            end
            catch (ex, @FileInUseException)
            begin
                writes(log,"ERROR: File is in use")
                init ch
            end
            endtry
            exitloop
        end
    end

    if (ch)
    begin
        ;;Look for a unique key in the file
        data uniqueKey, int, -1
        data thisKey, int
        for thisKey from 0 thru %isinfo(ch,"NUMKEYS") - 1
        begin
            if (!%isinfo(ch,"DUPS",thisKey))
            begin
                ;;Found one
                uniqueKey = thisKey
                exitloop
            end
        end

        ;;Did we find one
        if (uniqueKey==-1)
        begin
            writes(tt,"Replication not possible - no unique key found!")
            close ch
        end
    end

    if (ch)
    begin
        ;;Prepare to read all records from the file
        selector = new Select(new From(ch,<structureName>))
        enumerator = selector.GetEnumerator()

        while (enumerator.MoveNext())
        begin
            <structureName> = enumerator.Current
            saveRecord = false

            ;;Check that decimal fields contain valid numeric values
            <FIELD_LOOP>
            <IF DECIMAL>
            if (!CheckDecimal(<structureName>,"<FIELD_NAME>",^a(<structureName>.<field_name>),<IF NEGATIVE_ALLOWED>true<ELSE>false</IF NEGATIVE_ALLOWED>) && initBadData)
                <IF ARRAY>clear<ELSE>init</IF ARRAY> <structureName>.<field_name>
            </IF DECIMAL>
            </FIELD_LOOP>

            ;;Check that integer fields contain valid numeric values
            <FIELD_LOOP>
            <IF INTEGER>
            if (!CheckInteger(<structureName>,"<FIELD_NAME>",^a(<structureName>.<field_name>),<IF NEGATIVE_ALLOWED>true<ELSE>false</IF NEGATIVE_ALLOWED>) && initBadData)
                <IF ARRAY>clear<ELSE>init</IF ARRAY> <structureName>.<field_name>
            </IF INTEGER>
            </FIELD_LOOP>

            ;;Check that date fields contain valid date values
            <FIELD_LOOP>
            <IF DATE>
            if (!CheckDate(<structureName>,"<FIELD_NAME>",^a(<structureName>.<field_name>),<IF DATE_NULLABLE>true<ELSE>false</IF DATE_NULLABLE>) && initBadData)
                <IF ARRAY>clear<ELSE>init</IF ARRAY> <structureName>.<field_name>
            </IF DATE>
            </FIELD_LOOP>

            ;;Check that time fields contain valid time values
            <FIELD_LOOP>
            <IF TIME>
            if (!CheckTime(<structureName>,"<FIELD_NAME>",^a(<structureName>.<field_name>)) && initBadData)
                <IF ARRAY>clear<ELSE>init</IF ARRAY> <structureName>.<field_name>
            </IF TIME>
            </FIELD_LOOP>

            ;;If necessary, update the record
            if (initBadData&&saveRecord)
                enumerator.Current = <structureName>
        end

        if (errors) then
        begin
            writes(tt,%string(errors) + " errors were found. Check log file <StructureName>DataReport.log")
            close log
            xcall shell(,"<StructureName>DataReport.log",D_NOWINDOW)
        end
        else
        begin
            writes(tt,"No problems detected")
            purge log
        end
    end

    close ch
    close tt

    sleep 1

    stop

endmain

subroutine LogError
    required in fullRecord, str<StructureName>
    required in fieldName, string
    required in errorMessage, string
    required in fieldData, string
    external common
        tt, i4
        ch, i4
        log, i4
        errors, i4
        initBadData, boolean
        saveRecord, boolean
    endcommon
    stack record
        field, a30
    endrecord
proc
    if (!saveRecord)
    begin
        writes(log,"Record " + %keyval(ch,fullRecord,0))
        saveRecord = true
    end
    field = fieldName
    writes(log,field + " " + errorMessage + " " + fieldData)
    errors += 1
    xreturn
endsubroutine

function CheckDecimal, boolean
    required in fullRecord, str<StructureName>
    required in fieldName, string
    required in fieldData, a
    required in allowNegative, boolean
    endparams
    stack record
        ok, boolean
    endrecord
proc
    try
    begin
        data tmpval, d28
        tmpval = fieldData
        ok = ((tmpval>=0)||allowNegative)
    end
    catch (ex, @BadDigitException)
    begin
        ok = false
    end
    endtry
    if (!ok)
        LogError(fullRecord,fieldName,"Invalid decimal value",fieldData)
    freturn ok
endfunction

function CheckInteger, boolean
    required in fullRecord, str<StructureName>
    required in fieldName, string
    required in fieldData, a
    required in allowNegative, boolean
    endparams
    stack record
        ok, boolean
    endrecord
proc
    ok = true

    using ^size(fieldData) select
    (1),
    begin
        data ival, i1
        ival = ^i(fieldData)
        ok = ((ival>=0)||allowNegative)
    end
    (2),
    begin
        data ival, i2
        ival = ^i(fieldData)
        ok = ((ival>=0)||allowNegative)
    end
    (4),
    begin
        data ival, i4
        ival = ^i(fieldData)
        ok = ((ival>=0)||allowNegative)
    end
    (8),
    begin
        data ival, i8
        ival = ^i(fieldData)
        ok = ((ival>=0)||allowNegative)
    end
    (),
    begin
        ok = false
    end
    endusing

    if (!ok)
        LogError(fullRecord,fieldName,"Invalid integer value",fieldData)

    freturn ok
endfunction

function CheckDate, boolean
    required in fullRecord, str<StructureName>
    required in fieldName, string
    required in fieldData, a
    required in allowNull, boolean
    endparams
    stack record
        ok, boolean
        dval, d28
    endrecord
proc
    ok = true

    ;;Check the value is a valid decimal
    try
    begin
        dval = fieldData
        ok = true
    end
    catch (ex, @BadDigitException)
    begin
        ok = false
    end
    endtry

    ;;Only allow zero values where supported
    ok = (ok&&((dval>0)||((dval==0)&&allowNull)))

    ;;Check we have a valid date
    if (ok&(dval>0))
    begin
        try
        begin
            data julian, i4
            julian = %jperiod(^d(fieldData))
            ok = true
        end
        catch (ex, @SynException)
        begin
            ok = false
        end
        endtry
    end

    if (!ok)
        LogError(fullRecord,fieldName,"Invalid date value",fieldData)

    freturn ok

endfunction

function CheckTime, boolean
    required in fullRecord, str<StructureName>
    required in fieldName, string
    required in group fieldData, a
        hour, d2
        minute, d2
        second, d2
    endgroup
    endparams
    stack record
        ok, boolean
        dval, d28
    endrecord
proc
    ok = true

    ;;Check the value is a valid decimal
    try
    begin
        dval = fieldData
        ok = true
    end
    catch (ex, @BadDigitException)
    begin
        ok = false
    end
    endtry

    ;;Check the value is a valid time
    if (ok)
    begin
        ;;Hour and minute
        ok = ((hour>=0)&&(hour<=23)&&(minute>=0)&&(minute<=59))
        ;;Second
        if (^size(fieldData)==6)
            ok = (ok&&((second>=0)&&(second<=59)))
    end

    if (!ok)
        LogError(fullRecord,fieldName,"Invalid time value",fieldData)

    freturn ok
endfunction


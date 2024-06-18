<CODEGEN_FILENAME><StructureName>IO.dbl</CODEGEN_FILENAME>
<REQUIRES_CODEGEN_VERSION>6.0.2</REQUIRES_CODEGEN_VERSION>
;//****************************************************************************
;//
;// Guard against REPLICATOR_EXCLUDE being used on key segments
;//
<COUNTER_1_RESET>
<FIELD_LOOP>
  <IF CUSTOM_REPLICATOR_EXCLUDE AND KEYSEGMENT>
    <COUNTER_1_INCREMENT>
    <IF COUNTER_1_EQ_1>
*****************************************************************************
CODE GENERATION EXCEPTIONS:

    </IF COUNTER_1_EQ_1>
Field <FIELD_NAME> may not be excluded via REPLICATOR_EXCLUDE because it is a key segment!

  </IF CUSTOM_REPLICATOR_EXCLUDE>
</FIELD_LOOP>
;//
;//*****************************************************************************
;//
;// Title:       SdmsIO.tpl
;//
;// Description: Template to generate a collection of Synergy functions which
;//              facilitate SDMS to SDMS data replication.
;//
;// Author:      Steve Ives, Synergex Professional Services Group
;//
;// Copyright    (c) 2024 Synergex International Corporation.
;//              All rights reserved.
;//
;// Redistribution and use in source and binary forms, with or without
;// modification, are permitted provided that the following conditions are met:
;//
;// * Redistributions of source code must retain the above copyright notice,
;//   this list of conditions and the following disclaimer.
;//
;// * Redistributions in binary form must reproduce the above copyright notice,
;//   this list of conditions and the following disclaimer in the documentation
;//   and/or other materials provided with the distribution.
;//
;// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
;// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;// POSSIBILITY OF SUCH DAMAGE.
;//
;*****************************************************************************
;
; File:        <StructureName>IO.dbl
;
; Description: Various functions that performs SDMS I/O for <STRUCTURE_NAME>
;
;*****************************************************************************
;
; The following functions are identical to and therefor use the code from the
; SQL Connection replication code in <StructureName>SqlIO.dbl
;
<IF STRUCTURE_ISAM>
;   %<StructureName>KeyVal
;   %<StructureName>KeyNum
</IF>
<IF STRUCTURE_MAPPED>
;   %<structure_name>_map
;   %<structure_name>_unmap
</IF>
;   %<StructureName>Length
;   %<StructureName>Type
;   %<StructureName>Cols
;   %<StructureName>Recs
;
; In addition, there is no concept of load vs bulk load for SDMS replication,
; so the replicator calls %<StructureName>$Load for both operations.
;
;*****************************************************************************
; WARNING: THIS CODE WAS CODE GENERATED AND WILL BE OVERWRITTEN IF CODE
;          GENERATION IS RE-EXECUTED FOR THIS PROJECT.
;*****************************************************************************

import ReplicationLibrary
import Synergex.SynergyDE.Select
.ifdef DBLNET
import System.IO
.endc
import System.Text

.ifndef str<StructureName>
.include "<STRUCTURE_NOALIAS>" repository, structure="str<StructureName>", end
.endc

.define writelog(x) if Settings.LogFileChannel && %chopen(Settings.LogFileChannel) writes(Settings.LogFileChannel,%string(^d(now(1:14)),"XXXX-XX-XX XX:XX:XX") + " " + x)
.define writett(x)  if Settings.TerminalChannel writes(Settings.TerminalChannel,"   - " + %string(^d(now(9:8)),"XX:XX:XX.XX") + " " + x)

;*****************************************************************************
; <summary>
; Determines if <FILE_NAME> exists in the replicated data set.
; </summary>
; <param name="errorMessage">Returned error message.</param>
; <returns>Returns 1 if the file exists, otherwise a number indicating the type of error.</returns>

function <StructureName>$Exists, ^val
    required out errorMessage, a
    endparams

    .align
    stack record localData
        status,  int    ;Returned status
    endrecord

proc
    init localData
    errorMessage = ""

    if (ReplicationLibrary.File.Exists("<FILE_NAME>")) then
        status = 1
    else
    begin
        status = 0
        errorMessage = "File <FILE_NAME> does not exist!"
    end

    freturn status

endfunction

;*****************************************************************************
; <summary>
; Creates <FILE_NAME> in the replicated data set.
; </summary>
; <param name="errorMessage">Returned error message.</param>
; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>Create_, ^val
    required out errorMessage, a

    .align
    stack record localData
        ok,     boolean    ;Return status
<IF STRUCTURE_RELATIVE>
        ch,     int         ;Channel number
</IF>
    endrecord

proc
    init localData
    ok = true
    errorMessage = ""

    try
    begin
<IF STRUCTURE_ISAM>
        xcall isamc("<FILE_ISAMC_SPEC>",<STRUCTURE_SIZE>,<STRUCTURE_KEYS>,
  <KEY_LOOP>
        & "<KEY_ISAMC_SPEC>"<,>
  </KEY_LOOP>
        & )
<ELSE STRUCTURE_RELATIVE>
        open(ch=0,o:r,"<FILE_NAME>",RECSIZ:<STRUCTURE_SIZE>)
</IF>
    end
    catch (ex, @Exception)
    begin
        ok = false
        errorMessage = "Failed to create <FILE_NAME>. Error was " + ex.Message
    end
<IF STRUCTURE_RELATIVE>
    finally
    begin
        if (ch > 0)
            close ch
    end
</IF>
    endtry

    freturn ok

endfunction

<IF STRUCTURE_ISAM>
;*****************************************************************************
; <summary>
; Not used in the SDMS replication use case.
; </summary>
; <param name="errorMessage">Returned error message.</param>
; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>$Index, ^val
    required out errorMessage, a
proc
    errorMessage = ""
    freturn true
endfunction

;*****************************************************************************
; <summary>
; Not used in the SDMS replication use case.
; </summary>
; <param name="errorMessage">Returned error message.</param>
; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>$UnIndex, ^val
    required out errorMessage, a
proc
    errorMessage = ""
    freturn true
endfunction

</IF STRUCTURE_ISAM>
;*****************************************************************************
; <summary>
; Insert a record into <FILE_NAME>.
; </summary>
<IF STRUCTURE_RELATIVE>
; <param name="recordNumber">Relative record number to be inserted.</param>
</IF STRUCTURE_RELATIVE>
; <param name="recordData">Record to be inserted.</param>
; <param name="errorMessage">Returned error message.</param>
; <returns>Returns 1 if the row was inserted, 2 to indicate the row already exists, or 0 if an error occurred.</returns>

function <StructureName>$Insert, ^val
<IF STRUCTURE_RELATIVE>
    required in  recordNumber, n
</IF STRUCTURE_RELATIVE>
    required in  recordData,   a
    required out errorMessage, a

    .align
    stack record localData
        status, int
    endrecord

    external common
        ch<StructureName>, int
    endcommon

proc
    ;Make sure the channel is open
    if (!ch<StructureName> && !Open$<StructureName>(errorMessage))
    begin
        freturn 0
    end

    init localData
    status = 1
    errorMessage = ""

    try
    begin
<IF STRUCTURE_ISAM>
        store(ch<StructureName>,recordData)
<ELSE STRUCTURE_RELATIVE>
        write(ch<StructureName>,recordData,recordNumber)
</IF>
    end
    catch (ex, @DuplicateException)
    begin
        status = 2
        errorMessage = "Record already exists!"
    end
    catch (ex, @Exception)
    begin
        status = 0
        errorMessage = "Failed to insert record. Error was " + ex.Message
    end
    endtry

    freturn status

endfunction

;*****************************************************************************
; <summary>
; Inserts multiple records into <FILE_NAME>.
; </summary>
; <param name="recordsHandle">Memory handle containing one or more rows to insert.</param>
; <param name="errorMessage">Returned error text.</param>
; <param name="exceptionRecordsHandle">Memory handle to load exception data records into.</param>
; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>$InsertRows, ^val
    required in  recordsHandle, D_HANDLE
    required out errorMessage, a
    required out exceptionRecordsHandle, D_HANDLE

    .define EXCEPTION_BUFSZ 100

    stack record localData
        ok          ,boolean    ;Return status
        rows        ,int        ;Number of rows to insert
        ex_ms       ,int        ;Size of exception array
        ex_mc       ,int        ;Items in exception array
<IF STRUCTURE_RELATIVE>
        recordNumber,d28
</IF>
    endrecord

<IF STRUCTURE_ISAM>
    .include "<STRUCTURE_NOALIAS>" repository, structure="inpbuf", nofields, end
<ELSE STRUCTURE_RELATIVE>
    structure inpbuf
        recnum, d28
        .include "<STRUCTURE_NOALIAS>" repository, group="inprec", nofields
    endstructure
</IF>
    .include "<STRUCTURE_NOALIAS>" repository, static record="<structure_name>", end

    external common
        ch<StructureName>, int
    endcommon

proc
    ;Make sure the channel is open
    if (!ch<StructureName> && !Open$<StructureName>(errorMessage))
    begin
        freturn false
    end

    init localData
    ok = true

    ;Figure out how many records to insert

    rows = (%mem_proc(DM_GETSIZE,recordsHandle)/^size(inpbuf))

    ;Insert the records into the database

    if (ok)
    begin
        data cnt, int
        for cnt from 1 thru rows
        begin
            ;Load data into bound record

<IF STRUCTURE_ISAM AND STRUCTURE_MAPPED>
            <structure_name> = %<structure_name>_map(^m(inpbuf[cnt],recordsHandle))
<ELSE STRUCTURE_ISAM AND NOT STRUCTURE_MAPPED>
            <structure_name> = ^m(inpbuf[cnt],recordsHandle)
<ELSE STRUCTURE_RELATIVE AND STRUCTURE_MAPPED>
            recordNumber = ^m(inpbuf[cnt].recnum,recordsHandle)
            <structure_name> = %<structure_name>_map(^m(inpbuf[cnt].inprec,recordsHandle))
<ELSE STRUCTURE_RELATIVE AND NOT STRUCTURE_MAPPED>
            recordNumber = ^m(inpbuf[cnt].recnum,recordsHandle)
            <structure_name> = ^m(inpbuf[cnt].inprec,recordsHandle)
</IF>

            ;Insert the record into the file
            try
            begin
<IF STRUCTURE_ISAM>
                store(ch<StructureName>,<structure_name>)
<ELSE STRUCTURE_RELATIVE>
                write(ch<StructureName>,<structure_name>,recordNumber)
</IF>
            end
            catch (ex, @Exception)
            begin
                ;If the insert failed, record the exception in the exceptions buffer
                ex_mc += 1
                if (ex_mc == 0) then
                begin
                    exceptionRecordsHandle = %mem_proc(DM_ALLOC,^size(inpbuf)*EXCEPTION_BUFSZ)
                end
                else if (ex_mc >= ex_ms)
                begin
                    exceptionRecordsHandle = %mem_proc(DM_RESIZ,^size(inpbuf)*(ex_ms+=EXCEPTION_BUFSZ),exceptionRecordsHandle)
                end
                ^m(inpbuf[ex_mc],exceptionRecordsHandle) = <structure_name>
            end
            endtry
        end
    end

    ;Resize the returned exceptions buffer to the correct size

    if (ex_mc)
    begin
        exceptionRecordsHandle = %mem_proc(DM_RESIZ,^size(inpbuf)*ex_mc,exceptionRecordsHandle)
        errorMessage = "Failed to insert " + %string(ex_mc) + " records"
    end

    freturn ok

endfunction

;*****************************************************************************
; <summary>
; Updates a record in <FILE_NAME>.
; </summary>
<IF STRUCTURE_RELATIVE>
; <param name="recordNumber">record number.</param>
</IF>
; <param name="dataRecord">Record containing data to update.</param>
; <param name="recordsUpdated">Returned number of rows affected.</param>
; <param name="errorMessage">Returned error message.</param>
; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>$Update, ^val
<IF STRUCTURE_RELATIVE>
    required in  recordNumber, n
</IF>
    required in  dataRecord, a
    required out recordsUpdated, i
    required out errorMessage, a

    stack record localData
        ok, boolean
        keyValue, a255
        keyLength, i4
    endrecord

    static record
        <structure_name>, str<StructureName>
    endrecord

    external function
        <StructureName>KeyVal, ^val
        <StructureName>KeyNum, ^val
    endexternal

    external common
        ch<StructureName>, int
    endcommon

proc
    ;Make sure the channel is open
    if (!ch<StructureName> && !Open$<StructureName>(errorMessage))
    begin
        freturn false
    end

    init localData
    recordsUpdated = 0
    ok = false

    ;Extract the key value from the RECORD

    xcall <StructureName>KeyVal(dataRecord,keyValue,keyLength)

    ;Read the record to lock it

    try
    begin
<IF STRUCTURE_ISAM>
        read(ch<StructureName>,<structure_name>,keyValue(1:keyLength),KEYNUM:%<StructureName>KeyNum)
<ELSE STRUCTURE_RELATIVE>
        read(ch<StructureName>,<structure_name>,recordNumber)
</IF>
    end
    catch (ex, @Exception)
    begin
        errorMessage = "Failed to update record. Error was " + ex.Message
    end
    endtry

    ;Update the record in the file

    if (ok)
    begin
<IF STRUCTURE_MAPPED>
        <structure_name> = %<structure_name>_map(dataRecord)
<ELSE>
        <structure_name> = dataRecord
</IF>
        try
        begin
<IF STRUCTURE_ISAM>
            write(ch<StructureName>,<structure_name>)
<ELSE STRUCTURE_RELATIVE>
            write(ch<StructureName>,<structure_name>,recordNumber)
</IF>
            recordsUpdated = 1
            ok = true
        end
        catch (ex, @Exception)
        begin
            unlock ch<StructureName>
            errorMessage = "Failed to update record. Error was " + ex.Message
        end
        endtry
    end

    freturn ok

endfunction

<IF STRUCTURE_ISAM>
;*****************************************************************************
; <summary>
; Deletes a record from <FILE_NAME>
; </summary>
; <param name="keyValue">Unique key of record to be deleted.</param>
; <param name="errorMessage">Returned error message.</param>
; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>$Delete, ^val
    required in  keyValue, a
    required out errorMessage, a
    .include "<STRUCTURE_NOALIAS>" repository, stack record="<structureName>", nofields
    external function
        <StructureName>KeyNum, ^val
    endexternal
    external common
        ch<StructureName>, int
    endcommon
proc
    ;Make sure the channel is open
    if (!ch<StructureName> && !Open$<StructureName>(errorMessage))
    begin
        freturn false
    end

    ;TODO: Needs to support relative files on OpenVMS
    try
    begin
        read(ch<StructureName>,<structure_name>,keyValue,KEYNUM:%<StructureName>KeyNum)
        try
        begin
            delete(ch<StructureName>)
            errorMessage = ""
            freturn true
        end
        catch (ex, @Exception)
        begin
            unlock ch<StructureName>
            errorMessage = "Failed to delete record. Error was " + ex.Message
        end
        endtry
    end
    catch (ex, @Exception)
    begin
        errorMessage = "Failed to read and lock record for delete. Error was " + ex.Message
    end
    endtry

    freturn false

endfunction

</IF>
;*****************************************************************************
; <summary>
; Deletes all rows from the <StructureName> table.
; </summary>
; <param name="errorMessage">Returned error text.</param>
; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>$Clear, ^val
    required out errorMessage, a
    external common
        ch<StructureName>, int
    endcommon
proc
    errorMessage = ""

    ;If the file is open, close it

    if (ch<StructureName>)
    begin
        close ch<StructureName>
        ch<StructureName> = 0
    end

    ;Clear the file

    try
    begin
        data ignored, i4
        xcall isclr("FILE_NAME",ignored)
        freturn true
    end
    catch (ex, @Exception)
    begin
        errorMessage = "Failed to clear file <FILE_NAME>. Error was " + ex.Message
    end
    endtry

    freturn false

endfunction

;*****************************************************************************
; <summary>
; Deletes the <StructureName> table from the database.
; </summary>
; <param name="errorMessage">Returned error message.</param>
; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>$Drop, ^val
    required out errorMessage, a
    external common
        ch<StructureName>, int
    endcommon
proc
    errorMessage = ""

    ;If the file is open, close it

    if (ch<StructureName>)
    begin
        close ch<StructureName>
        ch<StructureName> = 0
    end

    try
    begin
        xcall delet("<FILE_NAME>")
        freturn true
    end
    catch (ex, @Exception)
    begin
        errorMessage = "Failed to delete <FILE_NAME>. Error was " + ex.Message
    end
    endtry

    freturn false

endfunction

;*****************************************************************************
; <summary>
; Load all data from the original file into <IF STRUCTURE_MAPPED><MAPPED_FILE><ELSE><FILE_NAME></IF>
; </summary>
; <param name="a_maxrows">Maximum number of rows to load.</param>
; <param name="a_added">Number of successful inserts.</param>
; <param name="a_failed">Number of failed inserts.</param>
; <param name="errorMessage">Returned error message (if return value is false).</param>
; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>$Load, ^val
    required in  a_maxrows, n
    required out a_added, n
    required out a_failed, n
    required out errorMessage, a

<IF STRUCTURE_ISAM AND STRUCTURE_MAPPED>
    ;.include "<MAPPED_STRUCTURE>" repository, structure="inpbuf", end
<ELSE STRUCTURE_ISAM AND NOT STRUCTURE_MAPPED>
    ;.include "<STRUCTURE_NOALIAS>" repository, structure="inpbuf", end
<ELSE STRUCTURE_RELATIVE AND STRUCTURE_MAPPED>
    ;structure inpbuf
    ;    recnum, d28
    ;    .include "<MAPPED_STRUCTURE>" repository, group="inprec"
    ;endstructure
<ELSE STRUCTURE_RELATIVE AND NOT STRUCTURE_MAPPED>
    ;structure inpbuf
    ;    recnum, d28
    ;    .include "<STRUCTURE_NOALIAS>" repository, group="inprec"
    ;endstructure
    ;.include "<STRUCTURE_NOALIAS>" repository, structure="<STRUCTURE_NAME>", end
</IF>
<IF STRUCTURE_MAPPED>
    ;.include "<MAPPED_STRUCTURE>" repository, stack record="tmprec", end
<ELSE>
    ;.include "<STRUCTURE_NOALIAS>" repository, stack record="tmprec", end
</IF>

    stack record local_data
        ok          ,boolean    ;Return status
        now         ,a20        ;Current date and time
        timer       ,@Timer
<IF STRUCTURE_RELATIVE>
        recordNumber,d28
</IF>
    endrecord

    external common
        ch<StructureName>, int
    endcommon
proc
    init local_data
    ok = true
    a_added = 0
    a_failed = 0
    errorMessage = ""

    timer = new Timer()
    timer.Start()




    ok = false
    errorMessage = "Load is not implemented yet!"





    ;Return totals
    ;a_added = ?
    ;a_failed = ?

    timer.Stop()
    now = %datetime

    if (ok) then
    begin
        writelog("Load COMPLETE after " + timer.ElapsedTimeString)
        writett("Load COMPLETE after " + timer.ElapsedTimeString)
    end
    else
    begin
        writelog("Load FAILED after " + timer.ElapsedTimeString)
        writett("Load FAILED after " + timer.ElapsedTimeString)
    end

    freturn ok

endfunction

;*****************************************************************************
; <summary>
; Close cursors associated with the <StructureName> table.
; </summary>

subroutine <StructureName>$Close
    external common
        ch<StructureName>, int
    endcommon
proc
    ;If the file is open, close it

    if (ch<StructureName>)
    begin
        close ch<StructureName>
        ch<StructureName> = 0
    end

    xreturn

endsubroutine

;*****************************************************************************
; <summary>
; Exports <IF STRUCTURE_MAPPED><MAPPED_FILE><ELSE><FILE_NAME></IF> to a CSV file.
; </summary>
; <param name="fileSpec">File to create</param>
; <param name="maxRecords">Mumber of records to export.</param>
; <param name="recordCount">Returned number of records exported.</param>
; <param name="errorMessage">Returned error text.</param>
; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>$Csv, boolean
    required in  fileSpec, a
    required in  maxRecords, n
    required out recordCount, n
    required out errorMessage, a

    .include "<STRUCTURE_NOALIAS>" repository, record="<structure_name>", end

    .define EXCEPTION_BUFSZ 100

    external function
        IsDecimalNo, boolean
<IF NOT_DEFINED_DBLV11>
        MakeDateForCsv, a
</IF>
        MakeDecimalForCsvNegatives, a
        MakeDecimalForCsvNoNegatives, a
        MakeTimeForCsv, a
<IF DEFINED_ASA_TIREMAX>
        TmJulianToYYYYMMDD, a
        TmJulianToCsvDate, a
</IF>
    endexternal

    .align
    stack record local_data
        ok,         boolean ;Return status
        filechn,    int     ;Data file channel
        outchn,     int     ;CSV file channel
        outrec,     @StringBuilder  ;A CSV file record
        records,    int     ;Number of records exported
        pos,        int     ;Position in a string
        recordsMax, int     ;Max # or records to export
        errtxt,     a512    ;Error message text
        now,        a20     ;The time now
        timer,      @Timer  ;A timer
    endrecord

    external common
        ch<StructureName>, int
    endcommon
proc
    ;Make sure the channel is open
    if (!ch<StructureName> && !Open$<StructureName>(errorMessage))
    begin
        freturn false
    end

    clear records, errtxt
    ok = true
    errorMessage = ""

    timer = new Timer()
    timer.Start()

    ;Were we given a max # or records to export?

    recordsMax = maxRecords > 0 ? maxRecords : 0

    ;Open the data file associated with the structure

    if (!(filechn=%<StructureName>OpenInput(errtxt)))
    begin
        errtxt = "Failed to open data file! Error was " + errtxt
        ok = false
    end

    ;Create the local CSV file

    if (ok)
    begin
.ifdef OS_WINDOWS7
        open(outchn=0,o:s,fileSpec)
.endc
.ifdef OS_UNIX
        open(outchn=0,o,fileSpec)
.endc
.ifdef OS_VMS
        open(outchn=0,o,fileSpec,OPTIONS:"/stream")
.endc

        ;Add a row of column headers
.ifdef OS_WINDOWS7
        writes(outchn,"<IF STRUCTURE_RELATIVE>RecordNumber|</IF><FIELD_LOOP><IF CUSTOM_NOT_REPLICATOR_EXCLUDE><FieldSqlName><IF MORE>|</IF></IF></FIELD_LOOP>")
.else
        puts(outchn,"<IF STRUCTURE_RELATIVE>RecordNumber|</IF><FIELD_LOOP><IF CUSTOM_NOT_REPLICATOR_EXCLUDE><FieldSqlName><IF MORE>|</IF></IF></FIELD_LOOP>" + %char(13) + %char(10))
.endc

        ;Read and add data file records
        foreach <structure_name> in new Select(new From(filechn,Q_NO_GRFA,0,<structure_name>)<IF STRUCTURE_TAGS>,(Where)(<TAG_LOOP><TAGLOOP_CONNECTOR_C>(<structure_name>.<tagloop_field_name><TAGLOOP_OPERATOR_DBL><TAGLOOP_TAG_VALUE>)</TAG_LOOP>)</IF>)
        begin
            ;Make sure there are no | characters in the data
            while (pos = %instr(1,<structure_name>,"|"))
            begin
                clear <structure_name>(pos:1)
            end

            incr records

            if (recordsmax && (records > recordsMax))
            begin
                decr records
                exitloop
            end

            outrec = new StringBuilder()
<FIELD_LOOP>
  <IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
    <IF STRUCTURE_RELATIVE>
            outrec.Append(%string(records) + "|")
    </IF>
    <IF CUSTOM_DBL_TYPE>
;//
;// CUSTOM FIELDS
;//
            outrec.Append(%<FIELD_CUSTOM_STRING_FUNCTION>(<structure_name>.<field_original_name_modified>,<structure_name>) + "<IF MORE>|</IF MORE>")
;//
;// ALPHA
;//
    <ELSE ALPHA>
      <IF DEFINED_DBLV11>
            outrec.Append(<structure_name>.<field_original_name_modified> ? %atrim(<structure_name>.<field_original_name_modified>)<IF MORE> + "|"</IF> : "<IF MORE>|</IF>")
      <ELSE>
            outrec.Append(%atrim(<structure_name>.<field_original_name_modified>) + "<IF MORE>|</IF>")
      </IF>
;//
;// DECIMAL
;//
    <ELSE DECIMAL>
      <IF DEFINED_DBLV11>
            outrec.Append(<structure_name>.<field_original_name_modified> ? <IF NEGATIVE_ALLOWED>%MakeDecimalForCsvNegatives<ELSE>%MakeDecimalForCsvNoNegatives</IF>(<structure_name>.<field_original_name_modified>)<IF MORE> + "|"</IF> : "<IF MORE>0|</IF>")
      <ELSE>
            outrec.Append(<IF NEGATIVE_ALLOWED>%MakeDecimalForCsvNegatives<ELSE>%MakeDecimalForCsvNoNegatives</IF>(<structure_name>.<field_original_name_modified>) + "<IF MORE>|</IF>")
      </IF>
;//
;// DATE
;//
    <ELSE DATE>
      <IF DEFINED_DBLV11>
            outrec.Append(<structure_name>.<field_original_name_modified> ? %string(<structure_name>.<field_original_name_modified>,"XXXX-XX-XX")<IF MORE> + "|"</IF> : "<IF MORE>|</IF>")
      <ELSE>
            outrec.Append(%MakeDateForCsv(<structure_name>.<field_original_name_modified>) + "<IF MORE>|</IF>")
      </IF>
;//
;// DATE_YYMMDD
;//
    <ELSE DATE_YYMMDD>
            outrec.Append(%atrim(^a(<structure_name>.<field_original_name_modified>)) + "<IF MORE>|</IF>")
;//
;// TIME_HHMM
;//
    <ELSE TIME_HHMM>
      <IF DEFINED_DBLV11>
            outrec.Append(<structure_name>.<field_original_name_modified> ? %MakeTimeForCsv(<structure_name>.<field_original_name_modified>)<IF MORE> + "|"</IF> : "<IF MORE>|</IF>")
      <ELSE>
            outrec.Append(%MakeTimeForCsv(<structure_name>.<field_original_name_modified>) + "<IF MORE>|</IF>")
      </IF>
;//
;// TIME_HHMMSS
;//
    <ELSE TIME_HHMMSS>
      <IF DEFINED_DBLV11>
            outrec.Append(<structure_name>.<field_original_name_modified> ? %MakeTimeForCsv(<structure_name>.<field_original_name_modified>)<IF MORE> + "|"</IF> : "<IF MORE>|</IF>")
      <ELSE>
            outrec.Append(%MakeTimeForCsv(<structure_name>.<field_original_name_modified>) + "<IF MORE>|</IF>")
      </IF>
;//
;// USER-DEFINED
;//
    <ELSE USER>
      <IF USERTIMESTAMP>
            outrec.Append(%string(^d(<structure_name>.<field_original_name_modified>),"XXXX-XX-XX XX:XX:XX.XXXXXX") + "<IF MORE>|</IF>")
      <ELSE>
            outrec.Append(<IF DEFINED_ASA_TIREMAX>%TmJulianToCsvDate<ELSE>%atrim</IF>(<structure_name>.<field_original_name_modified>) + "<IF MORE>|</IF>")
      </IF>
;//
;//
;//
    </IF CUSTOM_DBL_TYPE>
  </IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
</FIELD_LOOP>

            .ifdef OS_WINDOWS7
            writes(outchn,outrec.ToString())
            .else
            puts(outchn,outrec.ToString() + %char(13) + %char(10))
            .endc
        end
    end

<IF NOT STRUCTURE_TAGS>
eof,
</IF>

    ;Close the file
    if (filechn && %chopen(filechn))
    begin
        close filechn
    end

    ;Close the CSV file
    if (outchn && %chopen(outchn))
    begin
        close outchn
    end

    ;Return the record count
    recordCount = records

    ;Return any error text
    errorMessage = errtxt

    timer.Stop()
    now = %datetime

    if (ok)
    begin
        writelog("Export took " + timer.ElapsedTimeString)
        writett("Export took " + timer.ElapsedTimeString)
    end

    freturn ok

endfunction

;*****************************************************************************
; <summary>
; Opens the <FILE_NAME> for update.
; </summary>
; <param name="errorMessage">Returned error message.</param>
; <returns>Returns the channel number, or 0 if an error occured.</returns>

function Open$<StructureName>, ^val
    required out errorMessage, a  ;Returned error text
    global common
        ch<StructureName>, int
    endcommon
proc
    errorMessage = ""

    if (ch<StructureName>) then
        freturn true
    else
    begin
        try
        begin
            open(ch<StructureName>=0,<IF STRUCTURE_ISAM>u:i<ELSE STRUCTURE_RELATIVE>u:r</IF>,"<FILE_NAME>")
        end
        catch (ex, @Exception)
        begin
            errorMessage = ex.Message
            clear ch<StructureName>
            freturn false
        end
        endtry
    end
    freturn true
endfunction

<IF STRUCTURE_ISAM>
;*****************************************************************************
; <summary>
; Loads a unique key value into the respective fields in a record.
; </summary>
; <param name="aKeyValue">Unique key value.</param>
; <returns>Returns a record containig only the unique key segment data.</returns>

function <StructureName>$KeyToRecord, a
    required in aKeyValue, a

    .include "<STRUCTURE_NOALIAS>" repository, stack record="<structureName>", end

    stack record
        segPos, int
    endrecord

proc

    clear <structureName>
    segPos = 1

  <UNIQUE_KEY>
    <SEGMENT_LOOP>
      <IF ALPHA>
    <structureName>.<segment_name> = aKeyValue(segPos:<SEGMENT_LENGTH>)
      <ELSE DECIMAL>
    <structureName>.<segment_name> = ^d(aKeyValue(segPos:<SEGMENT_LENGTH>))
      <ELSE DATE>
    if ((!^d(aKeyValue(segPos:<SEGMENT_LENGTH>)))||(!%IsDate(^a(^d(aKeyValue(segPos:<SEGMENT_LENGTH>)))))) then
        ^a(<structureName>.<segment_name>) = "17530101"
    else
        <structureName>.<segment_name> = ^d(aKeyValue(segPos:<SEGMENT_LENGTH>))
      <ELSE TIME>
    <structureName>.<segment_name> = ^d(aKeyValue(segPos:<SEGMENT_LENGTH>))
      <ELSE USER>
    <structureName>.<segment_name> = aKeyValue(segPos:<SEGMENT_LENGTH>)
      </IF>
    segPos += <SEGMENT_LENGTH>
    </SEGMENT_LOOP>
  </UNIQUE_KEY>

    freturn <structureName>

endfunction

</IF STRUCTURE_ISAM>

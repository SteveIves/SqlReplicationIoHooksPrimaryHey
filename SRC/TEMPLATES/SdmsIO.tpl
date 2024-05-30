<CODEGEN_FILENAME><StructureName>SdmsIO.dbl</CODEGEN_FILENAME>
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
; File:        <StructureName>SdmsIO.dbl
;
; Description: Various functions that performs SDMS I/O for <STRUCTURE_NAME>
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

function <StructureName>Exists, ^val
    required out errorMessage, a
    endparams

    .align
    stack record localData
        error,  int    ;Returned error number (0=no error)
    endrecord

proc
    init localData
    errorMessage = ""




    freturn error

endfunction

;*****************************************************************************
; <summary>
; Creates <FILE_NAME> in the replicated data set.
; </summary>
; <param name="errorMessage">Returned error message.</param>
; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>Create, ^val
    required out errorMessage, a

    .align
    stack record localData
        ok          ,boolean    ;Return status
    endrecord

proc
    init localData
    ok = true
    errorMessage = ""



    freturn ok

endfunction

<IF STRUCTURE_ISAM>
;*****************************************************************************
; <summary>
; Not used in the SDMS replication use case.
; </summary>
; <param name="errorMessage">Returned error message.</param>
; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>Index, ^val
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

function <StructureName>UnIndex, ^val
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

function <StructureName>Insert, ^val
<IF STRUCTURE_RELATIVE>
    required in  recordNumber, n
</IF STRUCTURE_RELATIVE>
    required in  recordData,   a
    required out errorMessage, a

    .align
    stack record localData
        status, int
    endrecord

proc
    init localData
    status = 1
    errorMessage = ""

<IF STRUCTURE_RELATIVE>

<ELSE>

</IF STRUCTURE_RELATIVE>

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

function <StructureName>InsertRows, ^val
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
</IF STRUCTURE_RELATIVE>
    endrecord

<IF STRUCTURE_ISAM>
    .include "<STRUCTURE_NOALIAS>" repository, structure="inpbuf", nofields, end
<ELSE STRUCTURE_RELATIVE>
    structure inpbuf
        recnum, d28
        .include "<STRUCTURE_NOALIAS>" repository, group="inprec", nofields
    endstructure
</IF STRUCTURE_ISAM>
    .include "<STRUCTURE_NOALIAS>" repository, static record="<structure_name>", end

proc
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
</IF STRUCTURE_ISAM>

            ;Insert the record into the file
            try
            begin
<IF STRUCTURE_ISAM>
                store(ch,<structure_name>)
<ELSE STRUCTURE_RELATIVE>
                write(ch,<structure_name>,recordNumber)
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
; Updates a row in the <StructureName> table.
; </summary>
<IF STRUCTURE_RELATIVE>
; <param name="a_recnum">record number.</param>
</IF STRUCTURE_RELATIVE>
; <param name="a_data">Record containing data to update.</param>
; <param name="a_rows">Returned number of rows affected.</param>
; <param name="a_errtxt">Returned error text.</param>
; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>Update, ^val
<IF STRUCTURE_RELATIVE>
    required in  a_recnum, n
</IF STRUCTURE_RELATIVE>
    required in  a_data,   a
    required out a_rows,   i
    required out a_errtxt, a

    .include "CONNECTDIR:ssql.def"

<IF DEFINED_ASA_TIREMAX>
    external function
        TmJulianToYYYYMMDD, a
    endexternal

</IF DEFINED_ASA_TIREMAX>
    stack record local_data
        ok          ,boolean    ;OK to continue
        openAndBind ,boolean    ;Should we open the cursor and bind data this time?
        transaction ,boolean    ;Transaction in progress
        dberror     ,int        ;Database error number
        cursor      ,int        ;Database cursor
        length      ,int        ;Length of a string
        rows        ,int        ;Number of rows updated
        errtxt      ,a512       ;Error message text
    endrecord

    literal
        sql         ,a*, 'UPDATE <StructureName> SET '
<COUNTER_1_RESET>
<COUNTER_2_RESET>
<FIELD_LOOP>
  <IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
    <COUNTER_1_INCREMENT>
    <COUNTER_2_INCREMENT>
    <IF USERTIMESTAMP>
        & +              '"<FieldSqlName>"=CONVERT(DATETIME2,:<COUNTER_1_VALUE>,21)<,>'
    <ELSE>
        & +              '"<FieldSqlName>"=:<COUNTER_1_VALUE><,>'
    </IF USERTIMESTAMP>
  </IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
</FIELD_LOOP>
<IF STRUCTURE_ISAM>
        & +              ' WHERE <UNIQUE_KEY><SEGMENT_LOOP><COUNTER_1_INCREMENT>"<FieldSqlName>"=:<COUNTER_1_VALUE> <AND> </SEGMENT_LOOP></UNIQUE_KEY>'
<ELSE STRUCTURE_RELATIVE>
        & +              ' WHERE "RecordNumber"=:<COUNTER_1_INCREMENT><COUNTER_1_VALUE>'
</IF STRUCTURE_ISAM>
    endliteral

    static record
        <structure_name>, str<StructureName>
<FIELD_LOOP>
  <IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
    <IF CUSTOM_DBL_TYPE>
        tmp<FieldSqlName>, <FIELD_CUSTOM_DBL_TYPE>
    <ELSE USERTIMESTAMP>
        tmp<FieldSqlName>, a26     ;Storage for user-defined timestamp field
    <ELSE TIME_HHMM>
        tmp<FieldSqlName>, a5      ;Storage for HH:MM time field
    <ELSE TIME_HHMMSS>
        tmp<FieldSqlName>, a8      ;Storage for HH:MM:SS time field
    <ELSE DEFINED_ASA_TIREMAX AND USER>
        tmp<FieldSqlName>, a8      ;Storage for user defined JJJJJJ date field
    </IF CUSTOM_DBL_TYPE>
  </IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
</FIELD_LOOP>
    endrecord

    global common
        c3<StructureName>, i4
    endcommon
proc
    init local_data
    ok = true

    openAndBind = (c3<StructureName> == 0)

    clear a_rows

    ;Load the data into the bound record

<IF STRUCTURE_MAPPED>
    <structure_name> = %<structure_name>_map(a_data)
<ELSE>
    <structure_name> = a_data
</IF STRUCTURE_MAPPED>

    ;If we're in manual commit mode, start a transaction

    if (Settings.DatabaseCommitMode==DatabaseCommitMode.Manual)
    begin
        ok = %StartTransactionSqlConnection(transaction,errtxt)
    end

    ;Open a cursor for the UPDATE statement

    if (ok && openAndBind)
    begin
        if (%ssc_open(Settings.DatabaseChannel,c3<StructureName>,sql,SSQL_NONSEL,SSQL_STANDARD)==SSQL_FAILURE)
        begin
            ok = false
            if (%ssc_getemsg(Settings.DatabaseChannel,errtxt,length,,dberror)==SSQL_FAILURE)
                errtxt="Failed to open cursor"
        end
    end

    ;Bind the host variables for data to be updated
<COUNTER_1_RESET>
<FIELD_LOOP>
  <IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
    <COUNTER_1_INCREMENT>
    <IF COUNTER_1_EQ_1>

    if (ok && openAndBind)
    begin
        if (%ssc_bind(Settings.DatabaseChannel,c3<StructureName>,<REPLICATION_REMAINING_INCLUSIVE_MAX_250>,
    </IF COUNTER_1_EQ_1>
    <IF CUSTOM_DBL_TYPE>
        &    tmp<FieldSqlName><IF NOMORE>)==SSQL_FAILURE)<ELSE><IF COUNTER_1_LT_250>,<ELSE>)==SSQL_FAILURE)</IF COUNTER_1_LT_250></IF NOMORE>
    <ELSE ALPHA>
        &    <structure_name>.<field_original_name_modified><IF NOMORE>)==SSQL_FAILURE)<ELSE><IF COUNTER_1_LT_250>,<ELSE>)==SSQL_FAILURE)</IF COUNTER_1_LT_250></IF NOMORE>
    <ELSE DECIMAL>
        &    <structure_name>.<field_original_name_modified><IF NOMORE>)==SSQL_FAILURE)<ELSE><IF COUNTER_1_LT_250>,<ELSE>)==SSQL_FAILURE)</IF COUNTER_1_LT_250></IF NOMORE>
    <ELSE INTEGER>
        &    <structure_name>.<field_original_name_modified><IF NOMORE>)==SSQL_FAILURE)<ELSE><IF COUNTER_1_LT_250>,<ELSE>)==SSQL_FAILURE)</IF COUNTER_1_LT_250></IF NOMORE>
    <ELSE DATE>
        &    ^a(<structure_name>.<field_original_name_modified>)<IF NOMORE>)==SSQL_FAILURE)<ELSE><IF COUNTER_1_LT_250>,<ELSE>)==SSQL_FAILURE)</IF COUNTER_1_LT_250></IF NOMORE>
    <ELSE TIME>
        &    tmp<FieldSqlName><IF NOMORE>)==SSQL_FAILURE)<ELSE><IF COUNTER_1_LT_250>,<ELSE>)==SSQL_FAILURE)</IF COUNTER_1_LT_250></IF NOMORE>
    <ELSE USER AND USERTIMESTAMP>
        &    tmp<FieldSqlName><IF NOMORE>)==SSQL_FAILURE)<ELSE><IF COUNTER_1_LT_250>,<ELSE>)==SSQL_FAILURE)</IF COUNTER_1_LT_250></IF NOMORE>
    <ELSE USER AND NOT USERTIMESTAMP AND NOT DEFINED_ASA_TIREMAX>
        &    <structure_name>.<field_original_name_modified><IF NOMORE>)==SSQL_FAILURE)<ELSE><IF COUNTER_1_LT_250>,<ELSE>)==SSQL_FAILURE)</IF COUNTER_1_LT_250></IF NOMORE>
    <ELSE USER AND NOT USERTIMESTAMP AND DEFINED_ASA_TIREMAX>
        &    tmp<FieldSqlName><IF NOMORE>)==SSQL_FAILURE)<ELSE><IF COUNTER_1_LT_250>,<ELSE>)==SSQL_FAILURE)</IF COUNTER_1_LT_250></IF NOMORE>
    </IF CUSTOM_DBL_TYPE>
    <IF COUNTER_1_EQ_250>
        begin
            ok = false
            if (%ssc_getemsg(Settings.DatabaseChannel,errtxt,length,,dberror)==SSQL_FAILURE)
                errtxt="Failed to bind variables"
        end
    end
      <COUNTER_1_RESET>
    <ELSE NOMORE>
        begin
            ok = false
            if (%ssc_getemsg(Settings.DatabaseChannel,errtxt,length,,dberror)==SSQL_FAILURE)
                errtxt="Failed to bind variables"
        end
    end
    </IF COUNTER_1_EQ_250>
  </IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
</FIELD_LOOP>

    ;Bind the host variables for the key segments / WHERE clause

    if (ok && openAndBind)
    begin
<IF STRUCTURE_ISAM>
        if (%ssc_bind(Settings.DatabaseChannel,c3<StructureName>,<UNIQUE_KEY><KEY_SEGMENTS>,<SEGMENT_LOOP><IF DATEORTIME>^a(</IF DATEORTIME><structure_name>.<segment_name><IF DATEORTIME>)</IF DATEORTIME><,></SEGMENT_LOOP></UNIQUE_KEY>)==SSQL_FAILURE)
<ELSE STRUCTURE_RELATIVE>
        if (%ssc_bind(Settings.DatabaseChannel,c3<StructureName>,1,a_recnum)==SSQL_FAILURE)
</IF STRUCTURE_ISAM>
        begin
            ok = false
            if (%ssc_getemsg(Settings.DatabaseChannel,errtxt,length,,dberror)==SSQL_FAILURE)
                errtxt="Failed to bind key variables"
        end
    end

    ;Update the row in the database

    if (ok)
    begin
<IF DEFINED_CLEAN_DATA>
  <IF STRUCTURE_ALPHA_FIELDS>
        ;Clean up any alpha fields

    <FIELD_LOOP>
      <IF ALPHA AND CUSTOM_NOT_REPLICATOR_EXCLUDE AND NOT FIRST_UNIQUE_KEY_SEGMENT>
        <structure_name>.<field_original_name_modified> = %atrim(<structure_name>.<field_original_name_modified>)+%char(0)
      </IF ALPHA>
    </FIELD_LOOP>

  </IF STRUCTURE_ALPHA_FIELDS>
  <IF STRUCTURE_DECIMAL_FIELDS>
        ;Clean up any decimal fields

    <FIELD_LOOP>
      <IF DECIMAL AND CUSTOM_NOT_REPLICATOR_EXCLUDE>
        if ((!<structure_name>.<field_original_name_modified>)||(!<IF NEGATIVE_ALLOWED>%IsDecimalNegatives<ELSE>%IsDecimalNoNegatives</IF NEGATIVE_ALLOWED>(<structure_name>.<field_original_name_modified>)))
            clear <structure_name>.<field_original_name_modified>
      </IF DECIMAL>
    </FIELD_LOOP>

  </IF STRUCTURE_DECIMAL_FIELDS>
  <IF STRUCTURE_DATE_FIELDS>
        ;Clean up any date fields

    <FIELD_LOOP>
      <IF DATE AND CUSTOM_NOT_REPLICATOR_EXCLUDE>
        if ((!<structure_name>.<field_original_name_modified>)||(!%IsDate(^a(<structure_name>.<field_original_name_modified>))))
        <IF FIRST_UNIQUE_KEY_SEGMENT>
            ^a(<structure_name>.<field_original_name_modified>) = "17530101"
        <ELSE>
            ^a(<structure_name>.<field_original_name_modified>(1:1)) = %char(0)
        </IF FIRST_UNIQUE_KEY_SEGMENT>
      </IF DATE>
    </FIELD_LOOP>

  </IF STRUCTURE_DATE_FIELDS>
  <IF STRUCTURE_TIME_FIELDS>
        ;Clean up any time fields

    <FIELD_LOOP>
      <IF TIME AND CUSTOM_NOT_REPLICATOR_EXCLUDE>
        if ((!<structure_name>.<field_original_name_modified>)||(!%IsTime(^a(<structure_name>.<field_original_name_modified>))))
            ^a(<structure_name>.<field_original_name_modified>(1:1)) = %char(0)
      </IF TIME>
    </FIELD_LOOP>

  </IF STRUCTURE_TIME_FIELDS>
</IF DEFINED_CLEAN_DATA>
        ;Assign any time and user-defined timestamp fields

<FIELD_LOOP>
  <IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
    <IF USERTIMESTAMP>
        tmp<FieldSqlName> = %string(^d(<structure_name>.<field_original_name_modified>),"XXXX-XX-XX XX:XX:XX.XXXXXX")
    <ELSE TIME_HHMM>
        tmp<FieldSqlName> = %string(<structure_name>.<field_original_name_modified>,"XX:XX")
    <ELSE TIME_HHMMSS>
        tmp<FieldSqlName> = %string(<structure_name>.<field_original_name_modified>,"XX:XX:XX")
    <ELSE DEFINED_ASA_TIREMAX AND USER>
        tmp<FieldSqlName> = %TmJulianToYYYYMMDD(<field_path>)
    </IF USERTIMESTAMP>
  </IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
</FIELD_LOOP>

        ;Assign values to temp fields for any fields with custom data types

<FIELD_LOOP>
  <IF CUSTOM_DBL_TYPE>
        tmp<FieldSqlName> = %<FIELD_CUSTOM_CONVERT_FUNCTION>(<field_path>,<structure_name>)
  </IF CUSTOM_DBL_TYPE>
</FIELD_LOOP>

        if (%ssc_execute(Settings.DatabaseChannel,c3<StructureName>,SSQL_STANDARD,,rows)==SSQL_NORMAL) then
        begin
            a_rows = rows
        end
        else
        begin
            ok = false
            if (%ssc_getemsg(Settings.DatabaseChannel,errtxt,length,,dberror)==SSQL_FAILURE)
                errtxt="Failed to execute SQL statement"
            xcall ThrowOnCommunicationError(dberror,errtxt)
        end
    end

    ;If we're in manual commit mode, commit or rollback the transaction

    if ((Settings.DatabaseCommitMode==DatabaseCommitMode.Manual) && transaction)
    begin
        if (ok) then
        begin
            ;Success, commit the transaction
            ok = %CommitTransactionSqlConnection(Settings.DatabaseChannel,errtxt)
        end
        else
        begin
            ;There was an error, rollback the transaction
            ok = %RollbackSqlConnection(Settings.DatabaseChannel,errtxt)
        end
    end

    ;Return error message

    if (ok) then
        clear a_errtxt
    else
        a_errtxt = errtxt

    freturn ok

endfunction

<IF STRUCTURE_ISAM>
;*****************************************************************************
; <summary>
; Deletes a row from the <StructureName> table.
; </summary>
; <param name="a_key">Unique key of row to be deleted.</param>
; <param name="a_errtxt">Returned error text.</param>
; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>Delete, ^val
    required in  a_key,    a
    required out a_errtxt, a

    .include "CONNECTDIR:ssql.def"
    .include "<STRUCTURE_NOALIAS>" repository, stack record="<structureName>"

    external function
        <StructureName>KeyToRecord, a
<IF DEFINED_ASA_TIREMAX>
        TmJulianToYYYYMMDD, a
</IF DEFINED_ASA_TIREMAX>
    endexternal

    stack record local_data
        ok          ,boolean    ;Return status
        dberror     ,int        ;Database error number
        cursor      ,int        ;Database cursor
        length      ,int        ;Length of a string
        transaction ,boolean    ;Transaction in progress
        errtxt      ,a512       ;Error message text
        sql         ,string     ;SQL statement
    endrecord

proc

    init local_data
    ok = true

    ;Put the unique key value into the record

    <structureName> = %<StructureName>KeyToRecord(a_key)

    ;If we're in manual commit mode, start a transaction

    if (Settings.DatabaseCommitMode==DatabaseCommitMode.Manual)
    begin
        ok = %StartTransactionSqlConnection(transaction,errtxt)
    end

    ;Open a cursor for the DELETE statement

    if (ok)
    begin
        sql = 'DELETE FROM "<StructureName>" WHERE'
  <UNIQUE_KEY>
    <SEGMENT_LOOP>
      <IF ALPHA>
        & + ' "<FieldSqlName>"=' + "'" + %atrim(<structureName>.<segment_name>) + "' <AND>"
      <ELSE NOT DEFINED_ASA_TIREMAX>
        & + ' "<FieldSqlName>"=' + "'" + %string(<structureName>.<segment_name>) + "' <AND>"
      <ELSE DEFINED_ASA_TIREMAX AND USER>
        & + " <SegmentName>='" + %TmJulianToYYYYMMDD(<structureName>.<segment_name>) + "' <AND>"
      <ELSE DEFINED_ASA_TIREMAX AND NOT USER>
        & + ' "<FieldSqlName>"=' + "'" + %string(<structureName>.<segment_name>) + "' <AND>"
      </IF ALPHA>
    </SEGMENT_LOOP>
  </UNIQUE_KEY>
        if (%ssc_open(Settings.DatabaseChannel,cursor,(a)sql,SSQL_NONSEL)==SSQL_FAILURE)
        begin
            ok = false
            if (%ssc_getemsg(Settings.DatabaseChannel,errtxt,length,,dberror)==SSQL_FAILURE)
                errtxt="Failed to open cursor"
        end
    end

    ;Execute the query

    if (ok)
    begin
        if (%ssc_execute(Settings.DatabaseChannel,cursor,SSQL_STANDARD)==SSQL_FAILURE)
        begin
            ok = false
            if (%ssc_getemsg(Settings.DatabaseChannel,errtxt,length,,dberror)==SSQL_FAILURE)
                errtxt="Failed to execute SQL statement"
            xcall ThrowOnCommunicationError(dberror,errtxt)
        end
    end

    ;Close the database cursor

    if (cursor)
    begin
        if (%ssc_close(Settings.DatabaseChannel,cursor)==SSQL_FAILURE)
        begin
            if (ok)
            begin
                ok = false
                if (%ssc_getemsg(Settings.DatabaseChannel,errtxt,length,,dberror)==SSQL_FAILURE)
                    errtxt="Failed to close cursor"
            end
        end
    end

    ;If we're in manual commit mode, commit or rollback the transaction

    if ((Settings.DatabaseCommitMode==DatabaseCommitMode.Manual) && transaction)
    begin
        if (ok) then
        begin
            ;Success, commit the transaction
            ok = %CommitTransactionSqlConnection(Settings.DatabaseChannel,errtxt)
        end
        else
        begin
            ;There was an error, rollback the transaction
            ok = %RollbackSqlConnection(Settings.DatabaseChannel,errtxt)
        end
    end

    ;If there was an error message, return it to the calling routine

    if (ok) then
        clear a_errtxt
    else
        a_errtxt = errtxt

    freturn ok

endfunction

</IF STRUCTURE_ISAM>
;*****************************************************************************
; <summary>
; Deletes all rows from the <StructureName> table.
; </summary>
; <param name="a_errtxt">Returned error text.</param>
; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>Clear, ^val
    required out a_errtxt, a

    .include "CONNECTDIR:ssql.def"

    stack record local_data
        ok          ,boolean    ;Return status
        dberror     ,int        ;Database error number
        cursor      ,int        ;Database cursor
        length      ,int        ;Length of a string
        transaction ,boolean    ;Transaction in process
        errtxt      ,a512       ;Returned error message text
        sql         ,string     ;SQL statement
    endrecord

proc

    init local_data
    ok = true

    ;If we're in manual commit mode, start a transaction

    if (Settings.DatabaseCommitMode==DatabaseCommitMode.Manual)
    begin
        ok = %StartTransactionSqlConnection(transaction,errtxt)
    end

    ;Open cursor for the SQL statement

    if (ok)
    begin
        sql = 'TRUNCATE TABLE "<StructureName>"'
        if (%ssc_open(Settings.DatabaseChannel,cursor,(a)sql,SSQL_NONSEL)==SSQL_FAILURE)
        begin
            ok = false
            if (%ssc_getemsg(Settings.DatabaseChannel,errtxt,length,,dberror)==SSQL_FAILURE)
                errtxt="Failed to open cursor"
        end
    end

    ;Execute SQL statement

    if (ok)
    begin
        if (%ssc_execute(Settings.DatabaseChannel,cursor,SSQL_STANDARD)==SSQL_FAILURE)
        begin
            ok = false
            if (%ssc_getemsg(Settings.DatabaseChannel,errtxt,length,,dberror)==SSQL_FAILURE)
                errtxt="Failed to execute SQL statement"
            xcall ThrowOnCommunicationError(dberror,errtxt)
        end
    end

    ;Close the database cursor

    if (cursor)
    begin
        if (%ssc_close(Settings.DatabaseChannel,cursor)==SSQL_FAILURE)
        begin
            if (ok)
            begin
                ok = false
                if (%ssc_getemsg(Settings.DatabaseChannel,errtxt,length,,dberror)==SSQL_FAILURE)
                    errtxt="Failed to close cursor"
            end
        end
    end

    ;Commit or rollback the transaction

    ;If we're in manual commit mode, commit or rollback the transaction
    begin
        if (ok) then
        begin
            ;Success, commit the transaction
            ok = %CommitTransactionSqlConnection(Settings.DatabaseChannel,errtxt)
        end
        else
        begin
            ;There was an error, rollback the transaction
            ok = %RollbackSqlConnection(Settings.DatabaseChannel,errtxt)
        end
    end

    ;If there was an error message, return it to the calling routine

    if (ok) then
        clear a_errtxt
    else
        a_errtxt = errtxt

    freturn ok

endfunction

;*****************************************************************************
; <summary>
; Deletes the <StructureName> table from the database.
; </summary>
; <param name="a_errtxt">Returned error text.</param>
; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>Drop, ^val
    required out a_errtxt, a

    .include "CONNECTDIR:ssql.def"

    stack record local_data
        ok          ,boolean    ;Return status
        dberror     ,int        ;Database error number
        cursor      ,int        ;Database cursor
        length      ,int        ;Length of a string
        transaction ,boolean    ;Transaction in progress
        errtxt      ,a512       ;Returned error message text
    endrecord

proc

    init local_data
    ok = true

    ;Close any open cursors

    xcall <StructureName>Close()

    ;If we're in manual commit mode, start a transaction

    if (Settings.DatabaseCommitMode==DatabaseCommitMode.Manual)
    begin
        ok = %StartTransactionSqlConnection(transaction,errtxt)
    end

    ;Open cursor for DROP TABLE statement

    if (ok)
    begin
        if (%ssc_open(Settings.DatabaseChannel,cursor,"DROP TABLE <StructureName>",SSQL_NONSEL)==SSQL_FAILURE)
        begin
            ok = false
            if (%ssc_getemsg(Settings.DatabaseChannel,errtxt,length,,dberror)==SSQL_FAILURE)
                errtxt="Failed to open cursor"
        end
    end

    ;Execute DROP TABLE statement

    if (ok)
    begin
        if (%ssc_execute(Settings.DatabaseChannel,cursor,SSQL_STANDARD)==SSQL_FAILURE)
        begin
            if (%ssc_getemsg(Settings.DatabaseChannel,errtxt,length,,dberror)==SSQL_NORMAL) then
            begin
                ;Check if the error was that the table did not exist
                if (dberror==-3701) then
                    clear errtxt
                else
                    ok = false
            end
            else
            begin
                errtxt="Failed to execute SQL statement"
                ok = false
            end
            xcall ThrowOnCommunicationError(dberror,errtxt)
        end
    end

    ;Close the database cursor

    if (cursor)
    begin
        if (%ssc_close(Settings.DatabaseChannel,cursor)==SSQL_FAILURE)
        begin
            if (ok)
            begin
                ok = false
                if (%ssc_getemsg(Settings.DatabaseChannel,errtxt,length,,dberror)==SSQL_FAILURE)
                    errtxt="Failed to close cursor"
            end
        end
    end

    ;If we're in manual commit mode, commit or rollback the transaction

    if ((Settings.DatabaseCommitMode==DatabaseCommitMode.Manual) && transaction)
    begin
        if (ok) then
        begin
            ;Success, commit the transaction
            ok = %CommitTransactionSqlConnection(Settings.DatabaseChannel,errtxt)
        end
        else
        begin
            ;There was an error, rollback the transaction
            ok = %RollbackSqlConnection(Settings.DatabaseChannel,errtxt)
        end
    end

    ;If there was an error message, return it to the calling routine

    if (ok) then
        clear a_errtxt
    else
        a_errtxt = errtxt

    freturn ok

endfunction

;*****************************************************************************
; <summary>
; Load all data from <IF STRUCTURE_MAPPED><MAPPED_FILE><ELSE><FILE_NAME></IF STRUCTURE_MAPPED> into the <StructureName> table.
; </summary>
; <param name="a_maxrows">Maximum number of rows to load.</param>
; <param name="a_added">Total number of successful inserts.</param>
; <param name="a_failed">Total number of failed inserts.</param>
; <param name="a_errtxt">Returned error text.</param>
; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>Load, ^val
    required in  a_maxrows,       n
    required out a_added,         n
    required out a_failed,        n
    required out a_errtxt,        a

    .include "CONNECTDIR:ssql.def"
<IF STRUCTURE_ISAM AND STRUCTURE_MAPPED>
    .include "<MAPPED_STRUCTURE>" repository, structure="inpbuf", end
<ELSE STRUCTURE_ISAM AND NOT STRUCTURE_MAPPED>
    .include "<STRUCTURE_NOALIAS>" repository, structure="inpbuf", end
<ELSE STRUCTURE_RELATIVE AND STRUCTURE_MAPPED>
    structure inpbuf
        recnum, d28
        .include "<MAPPED_STRUCTURE>" repository, group="inprec"
<ELSE STRUCTURE_RELATIVE AND NOT STRUCTURE_MAPPED>
    structure inpbuf
        recnum, d28
        .include "<STRUCTURE_NOALIAS>" repository, group="inprec"
    endstructure
    .include "<STRUCTURE_NOALIAS>" repository, structure="<STRUCTURE_NAME>", end
</IF STRUCTURE_ISAM>
<IF STRUCTURE_MAPPED>
    .include "<MAPPED_STRUCTURE>" repository, stack record="tmprec", end
<ELSE>
    .include "<STRUCTURE_NOALIAS>" repository, stack record="tmprec", end
</IF STRUCTURE_MAPPED>

    .define BUFFER_ROWS     1000
    .define EXCEPTION_BUFSZ 100

    stack record local_data
        ok          ,boolean    ;Return status
        firstRecord ,boolean    ;Is this the first record?
        filechn     ,int        ;Data file channel
        mh          ,D_HANDLE   ;Memory handle containing data to insert
        ms          ,int        ;Size of memory buffer in rows
        mc          ,int        ;Memory buffer rows currently used
        ex_mh       ,D_HANDLE   ;Memory buffer for exception records
        ex_mc       ,int        ;Number of records in returned exception array
        ex_ch       ,int        ;Exception log file channel
        attempted   ,int        ;Rows being attempted
        done_records,int        ;Records loaded
        max_records ,int        ;Maximum records to load
        ttl_added   ,int        ;Total rows added
        ttl_failed  ,int        ;Total failed inserts
        errnum      ,int        ;Error number
        errtxt      ,a512       ;Error message text
        now         ,a20        ;Current date and time
        timer       ,@Timer
<IF STRUCTURE_RELATIVE>
        recordNumber,d28
</IF STRUCTURE_RELATIVE>
    endrecord

proc
    init local_data
    ok = true
<IF STRUCTURE_RELATIVE>
    recordNumber = 0
</IF STRUCTURE_RELATIVE>

    timer = new Timer()
    timer.Start()

    ;If we are logging exceptions, delete any existing exceptions file.
    if (Settings.LogBulkLoadExceptions)
    begin
        xcall delet("REPLICATOR_LOGDIR:<structure_name>_data_exceptions.log")
    end

    ;Open the data file associated with the structure

    if (!(filechn = %<StructureName>OpenInput(errtxt)))
    begin
        errtxt = "Failed to open data file! Error was " + errtxt
        ok = false
    end

    ;Were we passed a max # records to load

    max_records = a_maxrows > 0 ? a_maxrows : 0
    done_records = 0

    if (ok)
    begin
        ;Allocate memory buffer for the database rows

        mh = %mem_proc(DM_ALLOC,^size(inpbuf)*(ms=BUFFER_ROWS))

        ;Read records from the input file

        firstRecord = true
        repeat
        begin
            ;Get the next record from the input file
            try
            begin
;//
;// First record processing
;//
                if (firstRecord) then
                begin
<IF STRUCTURE_TAGS>
                    find(filechn,,^FIRST)
                    repeat
                    begin
                        reads(filechn,tmprec)
                        if (<TAG_LOOP><TAGLOOP_CONNECTOR_C>tmprec.<TAGLOOP_FIELD_NAME><TAGLOOP_OPERATOR_C><TAGLOOP_TAG_VALUE></TAG_LOOP>)
                            exitloop
                    end
<ELSE>
                    read(filechn,tmprec,^FIRST)
</IF STRUCTURE_TAGS>
                    firstRecord = false
                end
;//
;// Subsequent record processing
;//
                else
                begin
<IF STRUCTURE_TAGS>
                    repeat
                    begin
                        reads(filechn,tmprec)
                        if (<TAG_LOOP><TAGLOOP_CONNECTOR_C>tmprec.<TAGLOOP_FIELD_NAME><TAGLOOP_OPERATOR_C><TAGLOOP_TAG_VALUE></TAG_LOOP>)
                            exitloop
                    end
<ELSE>
                    reads(filechn,tmprec)
</IF STRUCTURE_TAGS>
                end
            end
            catch (ex, @EndOfFileException)
            begin
                exitloop
            end
            catch (ex, @Exception)
            begin
                ok = false
                errtxt = "Unexpected error while reading data file: " + ex.Message
                exitloop
            end
            endtry

            ;Got one, load it into or buffer
<IF STRUCTURE_ISAM>
            ^m(inpbuf[mc+=1],mh) = tmprec
<ELSE STRUCTURE_RELATIVE>
            ^m(inpbuf[mc+=1].recnum,mh) = recordNumber += 1
            ^m(inpbuf[mc].inprec,mh) = tmprec
</IF STRUCTURE_ISAM>

            incr done_records

            ;If the buffer is full, write it to the database
            if (mc==ms)
            begin
                call insert_data
            end

            if (max_records && (done_records == max_records))
            begin
                exitloop
            end
        end

        if (mc)
        begin
            mh = %mem_proc(DM_RESIZ,^size(inpbuf)*mc,mh)
            call insert_data
        end

        ;Deallocate memory buffer

        mh = %mem_proc(DM_FREE,mh)

    end

    ;Close the file
    if (filechn && %chopen(filechn))
        close filechn

    ;Close the exceptions log file
    if (ex_ch && %chopen(ex_ch))
        close ex_ch

    ;Return any error text
    a_errtxt = errtxt

    ;Return totals
    a_added = ttl_added
    a_failed = ttl_failed

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

insert_data,

    attempted = (%mem_proc(DM_GETSIZE,mh)/^size(inpbuf))

    if (%<StructureName>InsertRows(mh,errtxt,ex_mh))
    begin
        ;Any exceptions?
        if (ex_mh) then
        begin
            ;How many exceptions to log?
            ex_mc = (%mem_proc(DM_GETSIZE,ex_mh)/^size(inpbuf))
            ;Update totals
            ttl_failed+=ex_mc
            ttl_added+=(attempted-ex_mc)
            ;Are we logging exceptions?
            if (Settings.LogBulkLoadExceptions) then
            begin
                data cnt, int
                ;Open the log file
                if (!ex_ch)
                    open(ex_ch=0,o:s,"REPLICATOR_LOGDIR:<structure_name>_data_exceptions.log")
                ;Log the exceptions
                for cnt from 1 thru ex_mc
                    writes(ex_ch,^m(inpbuf[cnt],ex_mh))
                if (Settings.RunningOnTerminal)
                    writes(Settings.TerminalChannel,"Exceptions were logged to REPLICATOR_LOGDIR:<structure_name>_data_exceptions.log")
            end
            else
            begin
                ;No, report and error
                ok = false
            end
            ;Release the exception buffer
            ex_mh=%mem_proc(DM_FREE,ex_mh)
        end
        else
        begin
            ;No exceptions
            ttl_added += attempted
            if (Settings.RunningOnTerminal && Settings.LogLoadProgress)
            begin
                writes(Settings.TerminalChannel," - " + %string(ttl_added) + " rows inserted")
            end
        end
    end

    clear mc

    return

endfunction

;*****************************************************************************
; <summary>
; Bulk load data from <IF STRUCTURE_MAPPED><MAPPED_FILE><ELSE><FILE_NAME></IF STRUCTURE_MAPPED> into the <StructureName> table via a CSV file.
; </summary>
; <param name="recordsToLoad">Number of records to load (0=all)</param>
; <param name="a_records">Records loaded</param>
; <param name="a_exceptions">Records failes</param>
; <param name="a_errtxt">Error message (if return value is false)</param>
; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>BulkLoad, ^val
    required in recordsToLoad, n
    required out a_records,    n
    required out a_exceptions, n
    required out a_errtxt,     a

    .include "CONNECTDIR:ssql.def"

     stack record local_data
        ok,                     boolean    ;Return status
        transaction,            boolean
        cursorOpen,             boolean
        remoteBulkLoad,         boolean
        sql,                    string
        localCsvFile,           string
        localExceptionsFile,    string
        localExceptionsLog,     string
        remoteCsvFile,          string
        remoteExceptionsFile,   string
        remoteExceptionsLog,    string
        copyTarget,             string
        fileToLoad,             string
        cursor,                 int
        length,                 int
        dberror,                int
        recordCount,            int	        ;# records to load / loaded
        exceptionCount,         int
        errtxt,                 a512        ;Error message text
        fsc,                    @FileServiceClient
        now,                    a20
        timer,                  @Timer
    endrecord

proc

    init local_data
    ok = true

    timer = new Timer()
    timer.Start()

    ;If we're doing a remote bulk load, create an instance of the FileService client and verify that we can access the FileService server

    remoteBulkLoad = Settings.CanBulkLoad() && Settings.DatabaseIsRemote()

    if (remoteBulkLoad)
    begin
        fsc = new FileServiceClient(Settings.FileServiceHost,Settings.FileServicePort)

        now = %datetime
        writelog("Verifying FileService connection")
        writett("Verifying FileService connection")

        if (!fsc.Ping(errtxt))
        begin
            now = %datetime
            writelog(errtxt = "No response from FileService, bulk upload cancelled")
            writett(errtxt = "No response from FileService, bulk upload cancelled")
            ok = false
        end
    end

    if (ok)
    begin
        ;Determine temporary file names

        .ifdef OS_WINDOWS7
        localCsvFile = Settings.LocalExportPath + "\<StructureName>.csv"
        .endc
        .ifdef OS_UNIX
        localCsvFile = Settings.LocalExportPath + "/<StructureName>.csv"
        .endc
        .ifdef OS_VMS
        localCsvFile = Settings.LocalExportPath + "<StructureName>.csv"
        .endc
        localExceptionsFile  = localCsvFile + "_err"
        localExceptionsLog   = localExceptionsFile + ".Error.Txt"

        if (remoteBulkLoad)
        begin
            remoteCsvFile = "<StructureName>.csv"
            remoteExceptionsFile = remoteCsvFile + "_err"
            remoteExceptionsLog  = remoteExceptionsFile + ".Error.Txt"
        end

        ;Make sure there are no files left over from previous operations

        ;Delete local files

        now = %datetime
        writelog("Deleting local files")
        writett("Deleting local files")

        xcall delet(localCsvFile)
        xcall delet(localExceptionsFile)
        xcall delet(localExceptionsLog)

        ;Delete remote files

        if (remoteBulkLoad)
        begin
            now = %datetime
            writelog("Deleting remote files")
            writett("Deleting remote files")

            fsc.Delete(remoteCsvFile)
            fsc.Delete(remoteExceptionsFile)
            fsc.Delete(remoteExceptionsLog)
        end

        ;And export the data

        now = %datetime
        writelog("Exporting delimited file")
        writett("Exporting delimited file")

        ok = %<StructureName>Csv(localCsvFile,recordsToLoad,recordCount,errtxt)
    end

    if (ok)
    begin
        ;If necessary, upload the exported file to the database server

        if (remoteBulkLoad) then
        begin
            now = %datetime
            writelog("Uploading delimited file to database host")
            writett("Uploading delimited file to database host")
            ok = fsc.UploadChunked(localCsvFile,remoteCsvFile,320,fileToLoad,errtxt)
        end
        else
        begin
            fileToLoad  = localCsvFile
        end
    end

    if (ok)
    begin
        ;Bulk load the database table

        ;If we're in manual commit mode, start a transaction

        if (Settings.DatabaseCommitMode==DatabaseCommitMode.Manual)
        begin
            now = %datetime
            writelog("Starting transaction")
            ok = %StartTransactionSqlConnection(transaction,errtxt)
        end

        ;Open a cursor for the statement

        if (ok)
        begin
            sql = "BULK INSERT <StructureName> FROM '" + fileToLoad + "' WITH (FIRSTROW=2,FIELDTERMINATOR='|',ROWTERMINATOR='\n',MAXERRORS=100000000,ERRORFILE='" + fileToLoad + "_err'"

            if (Settings.BulkLoadBatchSize > 0)
            begin
                sql = sql + ",BATCHSIZE=" + %string(Settings.BulkLoadBatchSize)
            end

           sql = sql + ")"

            if (%ssc_open(Settings.DatabaseChannel,cursor,sql,SSQL_NONSEL,SSQL_STANDARD)==SSQL_NORMAL) then
                cursorOpen = true
            else
            begin
                ok = false
                if (%ssc_getemsg(Settings.DatabaseChannel,errtxt,length,,dberror)==SSQL_FAILURE)
                    errtxt="Failed to open cursor"
            end
        end

        ;Set the SQL statement execution timeout to the bulk load value

        if (ok)
        begin
            now = %datetime
            writelog("Setting database timeout to " + %string(Settings.BulkLoadTimeout) + " seconds")
            writett("Setting database timeout to " + %string(Settings.BulkLoadTimeout) + " seconds")
            if (%ssc_cmd(Settings.DatabaseChannel,,SSQL_TIMEOUT,%string(Settings.BulkLoadTimeout))==SSQL_FAILURE)
            begin
                ok = false
                if (%ssc_getemsg(Settings.DatabaseChannel,errtxt,length,,dberror)==SSQL_FAILURE)
                    errtxt="Failed to set database timeout"
            end
        end

        ;Execute the statement

        if (ok)
        begin
            now = %datetime
            writelog("Executing BULK INSERT")
            writett("Executing BULK INSERT")

            if (%ssc_execute(Settings.DatabaseChannel,cursor,SSQL_STANDARD)==SSQL_FAILURE)
            begin
                if (%ssc_getemsg(Settings.DatabaseChannel,errtxt,length,,dberror)==SSQL_NORMAL) then
                begin
                    xcall ThrowOnCommunicationError(dberror,errtxt)

                    now = %datetime
                    writelog("Bulk insert error: " + %atrim(errtxt))
                    writett("Bulk insert error: " + %atrim(errtxt))

                    using dberror select
                    (-4864),
                    begin
                        ;Bulk load data conversion error
                        now = %datetime
                        writelog("Data conversion errors reported")
                        writett("Data conversion errors reported")
                        clear dberror, errtxt
                        call GetExceptionDetails
                    end
                    (),
                    begin
                        errtxt = %string(dberror) + " " + errtxt
                        ok = false
                    end
                    endusing
                end
                else
                begin
                    errtxt="Failed to execute SQL statement"
                    ok = false
                end
            end

            ;Delete local temp files

            now = %datetime
            writelog("Deleting local temp files")
            writett("Deleting local temp files")

            xcall delet(localCsvFile)
            xcall delet(localExceptionsFile)
            xcall delet(localExceptionsLog)

            ;Delete remote temp files

            if (remoteBulkLoad)
            begin
                now = %datetime
                writelog("Deleting remote temp files")
                writett("Deleting remote temp files")

                fsc.Delete(remoteCsvFile)
                fsc.Delete(remoteExceptionsFile)
                fsc.Delete(remoteExceptionsLog)
            end
        end

        ;If we're in manual commit mode, commit or rollback the transaction

        if ((Settings.DatabaseCommitMode==DatabaseCommitMode.Manual) && transaction)
        begin
            now = %datetime
            if (ok) then
            begin
                writelog("COMMIT")
                writett("COMMIT")
                ok = %CommitTransactionSqlConnection(Settings.DatabaseChannel,errtxt)
            end
            else
            begin
                ;There was an error, rollback the transaction
                writelog("ROLLBACK")
                writett("ROLLBACK")
                ok = %RollbackSqlConnection(Settings.DatabaseChannel,errtxt)
            end
        end

        ;Set the database timeout back to the regular value

        now = %datetime
        writelog("Resetting database timeout to " + %string(Settings.DatabaseTimeout) + " seconds")
        writett("Resetting database timeout to " + %string(Settings.DatabaseTimeout) + " seconds")

        if (%ssc_cmd(Settings.DatabaseChannel,,SSQL_TIMEOUT,%string(Settings.DatabaseTimeout))==SSQL_FAILURE)
            nop

        ;Close the cursor

        if (cursorOpen)
        begin
            if (%ssc_close(Settings.DatabaseChannel,cursor)==SSQL_FAILURE)
            begin
                if (%ssc_getemsg(Settings.DatabaseChannel,errtxt,length,,dberror)==SSQL_FAILURE)
                    errtxt="Failed to close cursor"
            end
        end
    end

    ; Return the record and exception count
    a_records = recordCount
    a_exceptions = exceptionCount

    ;Return any error text
    a_errtxt = errtxt

    timer.Stop()
    now = %datetime

    if (ok) then
    begin
        writelog("Bulk load finished in " + timer.ElapsedTimeString)
        writett("Bulk load finished in " + timer.ElapsedTimeString)
    end
    else
    begin
        writelog("Bulk load failed after " + timer.ElapsedTimeString)
        writett("Bulk load failed after " + timer.ElapsedTimeString)
    end

    freturn ok

GetExceptionDetails,

    ;If we get here then the bulk load reported one or more "data conversion error" issues
    ;There should be two files on the server

    now = %datetime
    writelog("Data conversion errors, processing exceptions")
    writett("Data conversion errors, processing exceptions")

    if (remoteBulkLoad) then
    begin
        data fileExists, boolean
        data tmpmsg, string

        if (fsc.Exists(remoteExceptionsFile,fileExists,tmpmsg)) then
        begin
            if (fileExists) then
            begin
                ;Download the error file
                data exceptionRecords, [#]string
                data errorMessage, string

                now = %datetime
                writelog("Downloading remote exceptions data file")
                writett("Downloading remote exceptions data file")

                if (fsc.DownloadText(remoteExceptionsFile,exceptionRecords,errorMessage))
                begin
                    data ex_ch, int
                    data exceptionRecord, string

                    open(ex_ch=0,o:s,localExceptionsFile)

                    foreach exceptionRecord in exceptionRecords
                        writes(ex_ch,exceptionRecord)

                    close ex_ch

                    exceptionCount = exceptionRecords.Length

                    now = %datetime
                    writelog(%string(exceptionCount) + " items saved to " + localExceptionsFile)
                    writett(%string(exceptionCount) + " items saved to " + localExceptionsFile)
                end
            end
            else
            begin
                ;Error file does not exist! In theory this should not happen, because we got here due to "data conversion error" being reported
                now = %datetime
                writelog("Remote exceptions data file not found!")
                writett("Remote exceptions data file not found!")
            end
        end
        else
        begin
            ;Failed to determine if file exists
            now = %datetime
            writelog("Failed to determine if remote exceptions data file exists. Error was " + tmpmsg)
            writett("Failed to determine if remote exceptions data file exists. Error was " + tmpmsg)
        end

        ;Now check for and retrieve the associated exceptions log

        if (fsc.Exists(remoteExceptionsLog,fileExists,tmpmsg)) then
        begin
            if (fileExists) then
            begin
                ;Download the error file
                data exceptionRecords, [#]string
                data errorMessage, string

                now = %datetime
                writelog("Downloading remote exceptions log file")
                writett("Downloading remote exceptions log file")

                if (fsc.DownloadText(remoteExceptionsLog,exceptionRecords,errorMessage))
                begin
                    data ex_ch, int
                    data exceptionRecord, string

                    open(ex_ch=0,o:s,localExceptionsLog)

                    foreach exceptionRecord in exceptionRecords
                        writes(ex_ch,exceptionRecord)

                    close ex_ch

                    now = %datetime
                    writelog(%string(exceptionRecords.Length) + " items saved to " + localExceptionsLog)
                    writelog(" - " + %string(exceptionRecords.Length) + " items saved to " + localExceptionsLog)
                end
            end
            else
            begin
                ;Error file does not exist! In theory this should not happen, because we got here due to "data conversion error" being reported
                now = %datetime
                writelog("Remote exceptions file not found!")
                writett("Remote exceptions file not found!")
            end
        end
        else
        begin
            ;Failed to determine if file exists
            now = %datetime
            writelog("Failed to determine if remote exceptions log file exists. Error was " + tmpmsg)
        end
    end
    else
    begin
        ;Local bulk load

        if (File.Exists(localExceptionsFile)) then
        begin
            data ex_ch, int
            data tmprec, a65535
            open(ex_ch=0,i:s,localExceptionsFile)
            repeat
            begin
                reads(ex_ch,tmprec,eof)
                exceptionCount += 1
            end
eof,        close ex_ch
            now = %datetime
            writelog(%string(exceptionCount) + " exception items found in " + localExceptionsFile)
        end
        else
        begin
            ;Error file does not exist! In theory this should not happen, because we got here due to "data conversion error" being reported
            now = %datetime
            writelog("Exceptions data file not found!")
        end
    end

    return

endfunction

;*****************************************************************************
; <summary>
; Close cursors associated with the <StructureName> table.
; </summary>

subroutine <StructureName>Close

    .include "CONNECTDIR:ssql.def"

    external common
<IF STRUCTURE_ISAM>
        c1<StructureName>, i4
        c2<StructureName>, i4
</IF STRUCTURE_ISAM>
        c3<StructureName>,  i4
    endcommon

proc

<IF STRUCTURE_ISAM>
    if (c1<StructureName>)
    begin
        try
        begin
            if (%ssc_close(Settings.DatabaseChannel,c1<StructureName>))
                nop
        end
        catch (ex, @Exception)
        begin
            nop
        end
        finally
        begin
            clear c1<StructureName>
        end
        endtry
    end

    if (c2<StructureName>)
    begin
        try
        begin
            if (%ssc_close(Settings.DatabaseChannel,c2<StructureName>))
                nop
        end
        catch (ex, @Exception)
        begin
            nop
        end
        finally
        begin
            clear c2<StructureName>
        end
        endtry
    end

</IF STRUCTURE_ISAM>
    if (c3<StructureName>)
    begin
        try
        begin
            if (%ssc_close(Settings.DatabaseChannel,c3<StructureName>))
                nop
        end
        catch (ex, @Exception)
        begin
            nop
        end
        finally
        begin
            clear c3<StructureName>
        end
        endtry
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

function <StructureName>Csv, boolean
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

proc
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
; Opens the <FILE_NAME> for input.
; </summary>
; <param name="errorMessage">Returned error message.</param>
; <returns>Returns the channel number, or 0 if an error occured.</returns>

function <StructureName>OpenInput, ^val
    required out errorMessage, a  ;Returned error text

    stack record
        ch, int
        errmsg, a128
    endrecord
proc

    try
    begin
        open(ch=0,<IF STRUCTURE_ISAM>i:i<ELSE STRUCTURE_RELATIVE>i:r</IF>,"<FILE_NAME>")
        clear errmsg
    end
    catch (ex, @Exception)
    begin
        errmsg = ex.Message
        clear ch
    end
    endtry

    errorMessage = errmsg

    freturn ch

endfunction

<IF STRUCTURE_ISAM>
;*****************************************************************************
; <summary>
; Loads a unique key value into the respective fields in a record.
; </summary>
; <param name="aKeyValue">Unique key value.</param>
; <returns>Returns a record containig only the unique key segment data.</returns>

function <StructureName>KeyToRecord, a
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
      </IF ALPHA>
    segPos += <SEGMENT_LENGTH>
    </SEGMENT_LOOP>
  </UNIQUE_KEY>

    freturn <structureName>

endfunction

;*****************************************************************************
; <summary>
; Extract a key value from the segment fields in a record.
; This function behaves like %KEYVAL but without requiring an open channel.
; </summary>
; <param name="aRecord">Record containing key data</param>
; <param name="aKeyVal">Returned key value</param>
; <param name="aKeyLen">Returned key length</param>
; <returns>Always returns true</returns>

function <StructureName>KeyVal, ^val
    required in  aRecord, a
    required out aKeyVal, a
    required out aKeyLen, n

    .align
    stack record
        pos,    int
        len,    int
        keyval, a255
  <UNIQUE_KEY>
    <IF LITERAL_SEGMENTS>
        tmpval, string
    </IF LITERAL_SEGMENTS>
  </UNIQUE_KEY>
    endrecord
proc
    clear keyval
    pos = 1
    len = 0

  <UNIQUE_KEY>
    <SEGMENT_LOOP>
      <IF SEG_TYPE_FIELD>
    ; Key segment <SEGMENT_NUMBER> (Field)
    keyval(pos:<SEGMENT_LENGTH>) = aRecord(<SEGMENT_POSITION>:<SEGMENT_LENGTH>)
        <IF MORE>
    pos += <SEGMENT_LENGTH>
        </IF MORE>
    len += <SEGMENT_LENGTH>
      <ELSE SEG_TYPE_LITERAL>
    ; Key segment <SEGMENT_NUMBER> (Literal value)
    tmpval = "<SEGMENT_LITVAL>"
    keyval(pos:tmpval.Length) = tmpval
        <IF MORE>
    pos += tmpval.Length
        </IF MORE>
    len += tmpval.Length
      <ELSE SEG_TYPE_RECNUM>
    throw new ApplicationException("Key segments of type RECORD NUMBER are not supported by replication!")
      <ELSE SEG_TYPE_EXTERNAL>
    throw new ApplicationException("Key segments of type EXTERNAL VALUE are not supported by replication!")
      </IF>

    </SEGMENT_LOOP>
  </UNIQUE_KEY>
    aKeyVal = keyval(1,len)
    aKeyLen = len

    freturn true

endfunction

;*****************************************************************************
; <summary>
; Returns the key number of the first unique key.
; </summary>
; <returns>Returned key number.</returns>

function <StructureName>KeyNum, ^val
proc
    freturn <UNIQUE_KEY><KEY_NUMBER></UNIQUE_KEY>
endfunction

</IF STRUCTURE_ISAM>
<IF STRUCTURE_MAPPED>
;*****************************************************************************
; <summary>
; 
; </summary>
; <param name="<mapped_structure>"></param>
; <returns></returns>

function <structure_name>_map, a
    .include "<MAPPED_STRUCTURE>" repository, required in group="<mapped_structure>"

    .include "<STRUCTURE_NAME>" repository, stack record="<structure_name>"
proc
    init <structure_name>
    ;Store the record
  <FIELD_LOOP>
    <field_path> = <mapped_path_conv>
  </FIELD_LOOP>
    freturn <structure_name>
endfunction

;*****************************************************************************
; <summary>
; 
; </summary>
; <param name="<structure_name>"></param>
; <returns></returns>

function <structure_name>_unmap, a
    .include "<STRUCTURE_NAME>" repository, required in group="<structure_name>"

    .include "<MAPPED_STRUCTURE>" repository, stack record="<mapped_structure>"
proc
    init <mapped_structure>
    ;Store the record
  <FIELD_LOOP>
    <mapped_path> = <field_path_conv>
  </FIELD_LOOP>
    freturn <mapped_structure>
endfunction

</IF STRUCTURE_MAPPED>
;*****************************************************************************
; <summary>
; 
; </summary>
; <returns></returns>

function <StructureName>Length ,^val
proc
    freturn <STRUCTURE_SIZE>
endfunction

;*****************************************************************************
; <summary>
; 
; </summary>
; <param name="fileType"></param>
; <returns></returns>

function <StructureName>Type, ^val
    required out fileType, a
proc
    fileType = "<FILE_TYPE>"
    freturn true
endfunction

;*****************************************************************************
; <summary>
; 
; </summary>
; <returns></returns>

function <StructureName>Cols ,^val
proc
<COUNTER_1_RESET>
<IF STRUCTURE_RELATIVE><COUNTER_1_INCREMENT></IF STRUCTURE_RELATIVE>
<FIELD_LOOP>
  <IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
    <IF DEFINED_ASA_TIREMAX>
      <IF STRUCTURE_ISAM AND USER>
        <COUNTER_1_INCREMENT>
      <ELSE STRUCTURE_ISAM AND NOT USER>
        <COUNTER_1_INCREMENT>
      <ELSE STRUCTURE_RELATIVE AND USER>
        <COUNTER_1_INCREMENT>
      <ELSE STRUCTURE_RELATIVE AND NOT USER>
        <COUNTER_1_INCREMENT>
      </IF STRUCTURE_ISAM>
    <ELSE>
      <IF STRUCTURE_ISAM>
        <COUNTER_1_INCREMENT>
      <ELSE STRUCTURE_RELATIVE>
        <COUNTER_1_INCREMENT>
      </IF STRUCTURE_ISAM>
    </IF DEFINED_ASA_TIREMAX>
  </IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
</FIELD_LOOP>
    freturn <COUNTER_1_VALUE>

endfunction

;*****************************************************************************
; <summary>
; 
; </summary>
; <param name="fileType"></param>
; <returns></returns>

function <StructureName>Recs, ^val
    required out recordCount, n
    required out errorMessage, a
    stack record
        ok, boolean
        ch, int
    endrecord
proc
    try
    begin
        open(ch=0,<IF STRUCTURE_ISAM>i:i<ELSE STRUCTURE_RELATIVE>i:r</IF>,"<FILE_NAME>")
        recordCount = %isinfo(ch,"NUMRECS")
        errorMessage = ""
        ok = true
    end
    catch (ex, @Exception)
    begin
        recordCount = -1
        errorMessage = ex.Message
        ok = false
    end
    finally
    begin
        if (ch && %chopen(ch))
            close ch
    end
    endtry
    freturn ok
endfunction


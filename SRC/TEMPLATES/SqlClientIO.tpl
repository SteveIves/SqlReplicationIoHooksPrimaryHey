<CODEGEN_FILENAME><StructureName>_SqlIO.dbl</CODEGEN_FILENAME>
<REQUIRES_CODEGEN_VERSION>6.0.3</REQUIRES_CODEGEN_VERSION>
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
;// Title:       SqlClientIO.tpl
;//
;// Description: Template to generate a collection of Synergy functions which
;//              create and interact with a table in a SQL Server database
;//              whose columns match the fields defined in a Synergy
;//              repository structure.
;//
;//              The code uses the System.Data.SqlClient classes
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
; File:        <StructureName>_SqlIO.dbl
;
; Description: Various functions that performs SQL I/O for <STRUCTURE_NAME>
;
;*****************************************************************************
; WARNING: THIS CODE WAS CODE GENERATED AND WILL BE OVERWRITTEN IF CODE
;          GENERATION IS RE-EXECUTED FOR THIS PROJECT.
;*****************************************************************************

.ifndef DBLNET
 ;This code was generated from the SqlClientIO template and can only be used
 ;in .NET. For traditional DBL environments use the SqlIO template
.else

import ReplicationLibrary
import Synergex.SynergyDE.Select
import System.Data.SqlClient
import System.IO
import System.Text

.ifndef str<StructureName>
.include "<STRUCTURE_NOALIAS>" repository, structure="str<StructureName>", end
.endc

.define writelog(x) if (Settings.LogFileChannel && %chopen(Settings.LogFileChannel)) writes(Settings.LogFileChannel,%string(^d(now(1:14)),"XXXX-XX-XX XX:XX:XX") + " " + x)
.define writett(x)  if (Settings.TerminalChannel) writes(Settings.TerminalChannel,"   - " + %string(^d(now(9:8)),"XX:XX:XX.XX") + " " + x)

;*****************************************************************************
;;; <summary>
;;; Determines if the <StructureName> table exists in the database.
;;; </summary>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <returns>Returns 1 if the table exists, otherwise a number indicating the type of error.</returns>

function <StructureName>_Exists, ^val
    required out aErrorMessage, a

    stack record
        error, int
        errorMessage, string
    endrecord
proc
    error = 0
    errorMessage = String.Empty

    try
    begin
        disposable data command = new SqlCommand("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='<StructureName>'",Settings.DatabaseConnection) { 
        &   CommandTimeout = Settings.DatabaseTimeout
        & }
        disposable data reader = command.ExecuteReader()
        if (reader.Read()) then
        begin
            ;Table exists
            error = 1
        end
        else
        begin
            errorMessage = "Table not found"
            error = 0
        end
    end
    catch (ex, @SqlException)
    begin
        errorMessage = ex.Message
        error = -1
        xcall ThrowOnSqlClientError(errorMessage,ex)
    end
    endtry

    ;Return any error message to the calling routine
    aErrorMessage = error == 1 ? String.Empty : errorMessage

    freturn error

endfunction

;*****************************************************************************
;;; <summary>
;;; Creates the <StructureName> table in the database.
;;; </summary>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_Create, ^val
    required out aErrorMessage, a

    .align
    stack record
        ok, boolean
        errorMessage, string
    endrecord
    static record
        createTableCommand, string
    endrecord
proc
    ok = true
    errorMessage = String.Empty

    ;If we're in manual commit mode, start a transaction

    disposable data transaction, @SqlTransaction
    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        transaction = Settings.DatabaseConnection.BeginTransaction()
    end

    ;Define the CREATE TABLE statement

    if (ok && createTableCommand == ^null)
    begin
        createTableCommand = 'CREATE TABLE "<StructureName>" ('
;//
;// Columns
;//
<IF STRUCTURE_RELATIVE>
        & + '"RecordNumber" INT NOT NULL,'
</IF STRUCTURE_RELATIVE>
<FIELD_LOOP>
  <IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
    <IF DEFINED_ASA_TIREMAX>
      <IF STRUCTURE_ISAM AND USER>
        & + '"<FieldSqlName>" DATE<IF REQUIRED> NOT NULL</IF><IF LAST><IF STRUCTURE_HAS_UNIQUE_PK>,</IF STRUCTURE_HAS_UNIQUE_PK><ELSE>,</IF LAST>'
      <ELSE STRUCTURE_ISAM AND NOT USER>
        & + '"<FieldSqlName>" <FIELD_CUSTOM_SQL_TYPE><IF REQUIRED> NOT NULL</IF><IF LAST><IF STRUCTURE_HAS_UNIQUE_PK>,</IF STRUCTURE_HAS_UNIQUE_PK><ELSE>,</IF LAST>'
      <ELSE STRUCTURE_RELATIVE AND USER>
        & + '"<FieldSqlName>" DATE<IF REQUIRED> NOT NULL</IF><,>'
      <ELSE STRUCTURE_RELATIVE AND NOT USER>
        & + '"<FieldSqlName>" <FIELD_CUSTOM_SQL_TYPE><IF REQUIRED> NOT NULL</IF><,>'
      </IF STRUCTURE_ISAM>
    <ELSE>
      <IF STRUCTURE_ISAM>
        & + '"<FieldSqlName>" <FIELD_CUSTOM_SQL_TYPE><IF REQUIRED> NOT NULL</IF><IF LAST><IF STRUCTURE_HAS_UNIQUE_PK>,</IF STRUCTURE_HAS_UNIQUE_PK><ELSE>,</IF LAST>'
      <ELSE STRUCTURE_RELATIVE>
        & + '"<FieldSqlName>" <FIELD_CUSTOM_SQL_TYPE><IF REQUIRED> NOT NULL</IF><,>'
      </IF STRUCTURE_ISAM>
    </IF DEFINED_ASA_TIREMAX>
  </IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
</FIELD_LOOP>
;//
;// Primary key constraint
;//
<IF STRUCTURE_ISAM AND STRUCTURE_HAS_UNIQUE_PK>
        & + 'CONSTRAINT PK_<StructureName> PRIMARY KEY CLUSTERED(<PRIMARY_KEY><SEGMENT_LOOP>"<FieldSqlName>" <SEGMENT_ORDER><,></SEGMENT_LOOP></PRIMARY_KEY>)'
<ELSE STRUCTURE_RELATIVE>
        & + 'CONSTRAINT PK_<StructureName> PRIMARY KEY CLUSTERED("RecordNumber" ASC)'
</IF STRUCTURE_ISAM>
        & + ')'

        using Settings.DataCompressionMode select
        (DatabaseDataCompression.Page),
            createTableCommand = createTableCommand + " WITH(DATA_COMPRESSION=PAGE)"
        (DatabaseDataCompression.Row),
            createTableCommand = createTableCommand + " WITH(DATA_COMPRESSION=ROW)"
        endusing
    end

    ;Create the database table and primary key constraint

    try
    begin
        disposable data command = new SqlCommand(createTableCommand,Settings.DatabaseConnection) { 
        &   CommandTimeout = Settings.DatabaseTimeout
        & }
        command.ExecuteNonQuery()
    end
    catch (ex, @SqlException)
    begin
        ok = false
        errorMessage = "Failed to create table. Error was: " + ex.Message
    end
    endtry 

    ;Grant access permissions

    if (ok)
    begin
        try
        begin
            disposable data command = new SqlCommand('GRANT ALL ON "<StructureName>" TO PUBLIC',Settings.DatabaseConnection) { 
            &   CommandTimeout = Settings.DatabaseTimeout
            & }
            command.ExecuteNonQuery()
        end
        catch (ex, @SqlException)
        begin
            ok = false
            errorMessage = "Failed to grant table permissions. Error was: " + ex.Message
        end
        endtry
    end

    ;Commit or rollback the transaction

    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        if (ok) then
        begin
            ;Success, commit the transaction
            transaction.Commit()
        end
        else
        begin
            ;There was an error, rollback the transaction
            transaction.Rollback()
        end
    end

    ;Return any error message to the calling routine
    aErrorMessage = ok ? String.Empty : errorMessage

    freturn ok

endfunction

<IF STRUCTURE_ISAM>
;*****************************************************************************
;;; <summary>
;;; Add alternate key indexes to the <StructureName> table if they do not exist.
;;; </summary>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_Index, ^val
    required out aErrorMessage, a

    .align
    stack record
        ok, boolean
        errorMessage, string
        now, a20
    endrecord

proc
    ok = true
    errorMessage = String.Empty

    ;If we're in manual commit mode, start a transaction

    disposable data transaction, @SqlTransaction
    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        transaction = Settings.DatabaseConnection.BeginTransaction()
    end

  <IF NOT STRUCTURE_HAS_UNIQUE_PK>
;   ;The structure has no unique primary key, so no primary key constraint was added to the table. Create an index instead.
;
    if (ok && !%Index_Exists("IX_<StructureName>_<PRIMARY_KEY><KeyName></PRIMARY_KEY>"))
    begin
        data sql = '<PRIMARY_KEY>CREATE INDEX IX_<StructureName>_<KeyName> ON "<StructureName>"(<SEGMENT_LOOP>"<FieldSqlName>" <SEGMENT_ORDER><,></SEGMENT_LOOP>)</PRIMARY_KEY>'

        using Settings.DataCompressionMode select
        (DatabaseDataCompression.Page),
            sql = sql + " WITH(DATA_COMPRESSION=PAGE)"
        (DatabaseDataCompression.Row),
            sql = sql + " WITH(DATA_COMPRESSION=ROW)"
        endusing

        try
        begin
            disposable data command = new SqlCommand(sql,Settings.DatabaseConnection) { 
            &   CommandTimeout = Settings.BulkLoadTimeout
            & }
            command.ExecuteNonQuery()
        end
        catch (ex, @SqlException)
        begin
            ok = false
            errorMessage = "Failed to create index. Error was: " + ex.Message
        end
        endtry 

        now = %datetime
        if (ok) then
        begin
            writelog(" - Added index IX_<StructureName>_<PRIMARY_KEY><KeyName></PRIMARY_KEY>")
        end
        else
        begin
            writelog(" - ERROR: Failed to add index IX_<StructureName>_<PRIMARY_KEY><KeyName></PRIMARY_KEY>")
            ok = true
        end
    end

  </IF STRUCTURE_HAS_UNIQUE_PK>
  <ALTERNATE_KEY_LOOP>
    ;Create index <KEY_NUMBER> (<KEY_DESCRIPTION>)

    if (ok && !%Index_Exists("IX_<StructureName>_<KeyName>"))
    begin
        data sql = 'CREATE <IF FIRST_UNIQUE_KEY>CLUSTERED<ELSE><KEY_UNIQUE></IF FIRST_UNIQUE_KEY> INDEX IX_<StructureName>_<KeyName> ON "<StructureName>"(<SEGMENT_LOOP>"<FieldSqlName>" <SEGMENT_ORDER><,></SEGMENT_LOOP>)'

        using Settings.DataCompressionMode select
        (DatabaseDataCompression.Page),
            sql = sql + " WITH(DATA_COMPRESSION=PAGE)"
        (DatabaseDataCompression.Row),
            sql = sql + " WITH(DATA_COMPRESSION=ROW)"
        endusing

        try
        begin
            disposable data command = new SqlCommand(sql,Settings.DatabaseConnection) { 
            &   CommandTimeout = Settings.BulkLoadTimeout
            & }
            command.ExecuteNonQuery()
        end
        catch (ex, @SqlException)
        begin
            ok = false
            errorMessage = "Failed to create index IX_<StructureName>_<KeyName>. Error was: " + ex.Message
        end
        endtry 

        now = %datetime

        if (ok) then
        begin
            writelog(" - Added index IX_<StructureName>_<KeyName>")
        end
        else
        begin
            writelog(" - ERROR: " + errorMessage)
            ok = true
        end
    end

  </ALTERNATE_KEY_LOOP>
    ;If we're in manual commit mode, commit or rollback the transaction

    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        if (ok) then
        begin
            ;Success, commit the transaction
            transaction.Commit()
        end
        else
        begin
            ;There was an error, rollback the transaction
            transaction.Rollback()
        end
    end

    ;Return any error message to the calling routine
    aErrorMessage = ok ? String.Empty : errorMessage

    freturn ok

endfunction

;*****************************************************************************
;;; <summary>
;;; Removes alternate key indexes from the <StructureName> table in the database.
;;; </summary>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_UnIndex, ^val
    required out aErrorMessage, a

    .align
    stack record
        ok, boolean
        errorMessage, string
    endrecord

proc
    ok = true
    errorMessage = String.Empty

    ;If we're in manual commit mode, start a transaction

    disposable data transaction, @SqlTransaction
    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        transaction = Settings.DatabaseConnection.BeginTransaction()
    end

  <IF NOT STRUCTURE_HAS_UNIQUE_PK>
    if (ok)
    begin
        try
        begin
            disposable data command = new SqlCommand('<PRIMARY_KEY>DROP INDEX IF EXISTS IX_<StructureName>_<KeyName></PRIMARY_KEY> ON "<StructureName>"',Settings.DatabaseConnection) { 
            &   CommandTimeout = Settings.DatabaseTimeout
            & }
            command.ExecuteNonQuery()
        end
        catch (ex, @SqlException)
        begin
            ok = false
            errorMessage = "Failed to drop index IX_<PRIMARY_KEY><StructureName>_<KeyName></PRIMARY_KEY>. Error was: " + ex.Message
        end
        endtry
    end

  </IF STRUCTURE_HAS_UNIQUE_PK>
  <ALTERNATE_KEY_LOOP>
    ;Drop index <KEY_NUMBER> (<KEY_DESCRIPTION>)

    if (ok)
    begin
        try
        begin
            disposable data command = new SqlCommand('DROP INDEX IF EXISTS IX_<StructureName>_<KeyName> ON "<StructureName>"',Settings.DatabaseConnection) { 
            &   CommandTimeout = Settings.DatabaseTimeout
            & }
            command.ExecuteNonQuery()
        end
        catch (ex, @SqlException)
        begin
            ok = false
            errorMessage = "Failed to drop index IX_<StructureName>_<KeyName>. Error was: " + ex.Message
        end
        endtry
    end

  </ALTERNATE_KEY_LOOP>
    ;If we're in manual commit mode, commit or rollback the transaction

    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        if (ok) then
        begin
            ;Success, commit the transaction
            transaction.Commit()
        end
        else
        begin
            ;There was an error, rollback the transaction
            transaction.Rollback()
        end
    end

    ;Return any error message to the calling routine
    aErrorMessage = ok ? String.Empty : errorMessage

    freturn ok

endfunction

</IF STRUCTURE_ISAM>
;*****************************************************************************
;;; <summary>
;;; Insert a row into the <StructureName> table.
;;; </summary>
<IF STRUCTURE_RELATIVE>
;;; <param name="a_recnum">Relative record number to be inserted.</param>
</IF STRUCTURE_RELATIVE>
;;; <param name="a_data">Record to be inserted.</param>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <returns>Returns 1 if the row was inserted, 2 to indicate the row already exists, or 0 if an error occurred.</returns>

function <StructureName>_Insert, ^val
<IF STRUCTURE_RELATIVE>
    required in  a_recnum, n
</IF STRUCTURE_RELATIVE>
    required in  a_data,   a
    required out aErrorMessage, a

<IF DEFINED_ASA_TIREMAX>
    external function
        TmJulianToYYYYMMDD, a
    endexternal

</IF DEFINED_ASA_TIREMAX>
    .align
    stack record local_data
        ok          ,boolean    ;OK to continue
        sts         ,int        ;Return status
        errorMessage,string     ;Error message text
<IF STRUCTURE_RELATIVE>
        recordNumber,d28        ;Relative record number
</IF STRUCTURE_RELATIVE>
    endrecord

    literal
        sql, string, "INSERT INTO <StructureName> ("
<IF STRUCTURE_RELATIVE>
        & + '"RecordNumber",'
</IF STRUCTURE_RELATIVE>
<FIELD_LOOP>
  <IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
        & + '"<FieldSqlName>"<,>'
  </IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
</FIELD_LOOP>
        & + ") VALUES(<IF STRUCTURE_RELATIVE>RecordNumber,</IF STRUCTURE_RELATIVE><FIELD_LOOP><IF CUSTOM_NOT_REPLICATOR_EXCLUDE><IF USERTIMESTAMP>CONVERT(DATETIME2,@<FieldSqlName>,21)<,><ELSE>@<FieldSqlName><,></IF USERTIMESTAMP></IF CUSTOM_NOT_REPLICATOR_EXCLUDE></FIELD_LOOP>)"
    endliteral

    static record
        <structure_name>, str<StructureName>
<FIELD_LOOP>
  <IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
    <IF USERTIMESTAMP>
        tmp<FieldSqlName>, a26     ;Storage for user-defined timestamp field
    <ELSE>
      <IF TIME_HHMM>
        tmp<FieldSqlName>, a5      ;Storage for HH:MM time field
      </IF TIME_HHMM>
      <IF TIME_HHMMSS>
        tmp<FieldSqlName>, a8      ;Storage for HH:MM:SS time field
      </IF TIME_HHMMSS>
      <IF DEFINED_ASA_TIREMAX>
        <IF USER>
        tmp<FieldSqlName>, a8      ;Storage for user defined JJJJJJ date field
        </IF USER>
      </IF DEFINED_ASA_TIREMAX>
      <IF CUSTOM_DBL_TYPE>
        tmp<FieldSqlName>, <FIELD_CUSTOM_DBL_TYPE>
      </IF CUSTOM_DBL_TYPE>
    </IF USERTIMESTAMP>
  </IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
</FIELD_LOOP>
    endrecord

proc
    init local_data
    ok = true
    sts = 1
<IF STRUCTURE_RELATIVE>
    recordNumber = a_recnum
</IF STRUCTURE_RELATIVE>

    if (ok)
    begin
<IF STRUCTURE_MAPPED>
        ;Map the file data into the table data record

        <structure_name> = %<structure_name>_map(a_data)
<ELSE>
        ;Load the data into the bound record

        <structure_name> = a_data
</IF STRUCTURE_MAPPED>

<IF DEFINED_CLEAN_DATA>
  <IF STRUCTURE_ALPHA_FIELDS>
        ;Clean up any alpha fields

    <FIELD_LOOP>
      <IF ALPHA AND CUSTOM_NOT_REPLICATOR_EXCLUDE>
        <IF NOT FIRST_UNIQUE_KEY_SEGMENT>
        <structure_name>.<field_original_name_modified> = %atrim(<structure_name>.<field_original_name_modified>)+%char(0)
        </IF FIRST_UNIQUE_KEY_SEGMENT>
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
            ^a(<structure_name>.<field_original_name_modified>(1:1))=%char(0)
      </IF TIME>
    </FIELD_LOOP>

  </IF STRUCTURE_TIME_FIELDS>
</IF DEFINED_CLEAN_DATA>
        ;Assign data to any temporary time or user-defined timestamp fields

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
    end

    ;If we're in manual commit mode, start a transaction

    disposable data transaction, @SqlTransaction
    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        transaction = Settings.DatabaseConnection.BeginTransaction()
    end

    if (ok)
    begin
        try
        begin
            disposable data command = new SqlCommand(sql,Settings.DatabaseConnection) { 
            &   CommandTimeout = Settings.DatabaseTimeout
            & }

<IF STRUCTURE_RELATIVE>
            command.Parameters.AddWithValue("@RecordNumber",DblToNetConverter.NumberToInt(recordNumber))
</IF STRUCTURE_RELATIVE>
<FIELD_LOOP>
  <IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
    <IF CUSTOM_DBL_TYPE>
            command.Parameters.AddWithValue("@<FieldSqlName>",tmp<FieldSqlName>)
    <ELSE ALPHA OR DECIMAL OR INTEGER OR DATE OR TIME>
            command.Parameters.AddWithValue("@<FieldSqlName>",<FIELD_DBL_TO_NET_CONVERTER>(<structure_name>.<field_original_name_modified>))
    <ELSE USER AND USERTIMESTAMP>
            command.Parameters.AddWithValue("@<FieldSqlName>",tmp<FieldSqlName>)
    <ELSE USER AND NOT USERTIMESTAMP>
      <IF DEFINED_ASA_TIREMAX>
            command.Parameters.AddWithValue("@<FieldSqlName>",tmp<FieldSqlName>)
      <ELSE>
            command.Parameters.AddWithValue("@<FieldSqlName>",<structure_name>.<field_original_name_modified>)
      </IF DEFINED_ASA_TIREMAX>
    </IF CUSTOM_DBL_TYPE>
  </IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
</FIELD_LOOP>

            command.ExecuteNonQuery()
        end
        catch (ex, @SqlException)
        begin
            ok = false
            sts = 0
            using ex.Number Select
            (-2627),    ;TODO: * * * MAY NOT BE THE CORRECT ERROR NUMBER FOR DUPLICATE KEY
            begin
                ;Duplicate key
                errorMessage = "Duplicate key detected in database!"
                sts = 2
            end
            (),
            begin
                errorMessage = "Failed to insert row into <StructureName>. Error was: " + ex.Message
            end
            endusing
            xcall ThrowOnSqlClientError(errorMessage,ex)
        end
        endtry
    end

    ;If we're in manual commit mode, commit or rollback the transaction

    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        if (ok) then
        begin
            ;Success, commit the transaction
            transaction.Commit()
        end
        else
        begin
            ;There was an error, rollback the transaction
            transaction.Rollback()
        end
    end

    ;Return any error message to the calling routine
    aErrorMessage = ok ? String.Empty : errorMessage

    freturn sts

endfunction

;*****************************************************************************
;;; <summary>
;;; Inserts multiple rows into the <StructureName> table.
;;; </summary>
;;; <param name="a_data">Memory handle containing one or more rows to insert.</param>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <param name="a_exception">Memory handle to load exception data records into.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_InsertRows, ^val
    required in  a_data, i
    required out aErrorMessage, a
    optional out a_exception, i

<IF DEFINED_ASA_TIREMAX>
    external function
        TmJulianToYYYYMMDD, a
    endexternal

</IF DEFINED_ASA_TIREMAX>
    .define EXCEPTION_BUFSZ 100

    stack record local_data
        ok,             boolean     ;Return status
        rows,           int         ;Number of rows to insert
        command,        @SqlCommand ;Represtens the SQL command to execute
        length,         int         ;Length of a string
        ex_ms,          int         ;Size of exception array
        ex_mc,          int         ;Items in exception array
        continue,       int         ;Continue after an error
        errorMessage,   string      ;Error message text
<IF STRUCTURE_RELATIVE>
        recordNumber,d28
</IF STRUCTURE_RELATIVE>
    endrecord

    literal
        sql, string, "INSERT INTO <StructureName> ("
<IF STRUCTURE_RELATIVE>
        & + '"RecordNumber",'
</IF STRUCTURE_RELATIVE>
<FIELD_LOOP>
  <IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
        & + '"<FieldSqlName>"<,>'
  </IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
</FIELD_LOOP>
        & + ") VALUES("
<IF STRUCTURE_RELATIVE>
        & + "@RecordNumber,"
</IF STRUCTURE_RELATIVE>
<FIELD_LOOP>
  <IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
    <IF USERTIMESTAMP>
        & + "CONVERT(DATETIME2,@<FieldSqlName>,21)<,>"
    <ELSE>
        & + "@<FieldSqlName><,>"
    </IF USERTIMESTAMP>
  </IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
</FIELD_LOOP>
        & + ")"
    endliteral

<IF STRUCTURE_ISAM>
    .include "<STRUCTURE_NOALIAS>" repository, structure="inpbuf", nofields, end
<ELSE STRUCTURE_RELATIVE>
    structure inpbuf
        recnum, d28
        .include "<STRUCTURE_NOALIAS>" repository, group="inprec", nofields
    endstructure
</IF STRUCTURE_ISAM>
    .include "<STRUCTURE_NOALIAS>" repository, static record="<structure_name>", end

    static record
<FIELD_LOOP>
  <IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
    <IF CUSTOM_DBL_TYPE>
        tmp<FieldSqlName>, <FIELD_CUSTOM_DBL_TYPE>
    <ELSE USERTIMESTAMP>
        tmp<FieldSqlName>, a26      ;Storage for user-defined timestamp field
    <ELSE TIME_HHMM>
        tmp<FieldSqlName>, a5       ;Storage for HH:MM time field
    <ELSE TIME_HHMMSS>
        tmp<FieldSqlName>, a8       ;Storage for HH:MM:SS time field
    <ELSE DEFINED_ASA_TIREMAX AND USER>
        tmp<FieldSqlName>, a8       ;Storage for user defined JJJJJJ date field
    </IF CUSTOM_DBL_TYPE>
  </IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
</FIELD_LOOP>
        , a1                        ;In case there are no user timestamp, date or JJJJJJ date fields
    endrecord
proc
    init local_data
    ok = true
    errorMessage = String.Empty

    if (^passed(a_exception) && a_exception)
        clear a_exception

    ;Figure out how many rows to insert

    rows = (%mem_proc(DM_GETSIZE,a_data) / ^size(inpbuf))

   ;If enabled, disable auto-commit

    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Automatic)
    begin
        try
        begin
            disposable data command = new SqlCommand("SET IMPLICIT_TRANSACTIONS ON",Settings.DatabaseConnection) { CommandTimeout = Settings.DatabaseTimeout }
            command.ExecuteNonQuery()
        end
        catch (ex, @SqlException)
        begin
            errorMessage = "Failed to disable auto-commit. Error was: " + ex.Message
            ok = false
        end
        endtry
    end

    ;If we're in manual commit mode, start a transaction

    disposable data transaction, @SqlTransaction
    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        transaction = Settings.DatabaseConnection.BeginTransaction()
    end

    ; If we're binding once, create the SqlCommand object and define parameters

    if (ok && Settings.SqlCommandReuse)
    begin
        command = new SqlCommand(sql,Settings.DatabaseConnection) { CommandTimeout = Settings.DatabaseTimeout }
<IF STRUCTURE_RELATIVE>
        command.Parameters.Add(new SqlParameter("@RecordNumber",DblToNetConverter.NumberToInt(recordNumber)))
</IF STRUCTURE_RELATIVE>
<FIELD_LOOP>
  <IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
    <IF CUSTOM_DBL_TYPE>
        command.Parameters.Add("@<FieldSqlName>")
    <ELSE ALPHA OR DECIMAL OR INTEGER OR DATE OR TIME>
        command.Parameters.Add(new SqlParameter("@<FieldSqlName>",<FIELD_DBL_TO_NET_CONVERTER>(<structure_name>.<field_original_name_modified>)))
    <ELSE USER AND USERTIMESTAMP>
        command.Parameters.Add("@<FieldSqlName>")
    <ELSE USER AND NOT USERTIMESTAMP AND NOT DEFINED_ASA_TIREMAX>
        command.Parameters.Add("@<FieldSqlName>")
    <ELSE USER AND NOT USERTIMESTAMP AND DEFINED_ASA_TIREMAX>
        command.Parameters.Add("@<FieldSqlName>")
    </IF CUSTOM_DBL_TYPE>
  </IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
</FIELD_LOOP>
    end

    ;Insert the rows into the database

    if (ok)
    begin
        data cnt, int
        for cnt from 1 thru rows
        begin
            ;Load data into bound record
<IF STRUCTURE_ISAM AND STRUCTURE_MAPPED>
            <structure_name> = %<structure_name>_map(^m(inpbuf[cnt],a_data))
<ELSE STRUCTURE_ISAM AND NOT STRUCTURE_MAPPED>
            <structure_name> = ^m(inpbuf[cnt],a_data)
<ELSE STRUCTURE_RELATIVE AND STRUCTURE_MAPPED>
            recordNumber = ^m(inpbuf[cnt].recnum,a_data)
            <structure_name> = %<structure_name>_map(^m(inpbuf[cnt].inprec,a_data))
<ELSE STRUCTURE_RELATIVE AND NOT STRUCTURE_MAPPED>
            recordNumber = ^m(inpbuf[cnt].recnum,a_data)
            <structure_name> = ^m(inpbuf[cnt].inprec,a_data)
</IF STRUCTURE_ISAM>

<IF DEFINED_CLEAN_DATA>
  <IF STRUCTURE_ALPHA_FIELDS>
            ;Clean up alpha variables
    <FIELD_LOOP>
      <IF ALPHA AND CUSTOM_NOT_REPLICATOR_EXCLUDE AND NOT FIRST_UNIQUE_KEY_SEGMENT>
            <structure_name>.<field_original_name_modified> = %atrim(<structure_name>.<field_original_name_modified>)+%char(0)
      </IF ALPHA>
    </FIELD_LOOP>

  </IF STRUCTURE_ALPHA_FIELDS>
  <IF STRUCTURE_DECIMAL_FIELDS>
            ;Clean up decimal variables
    <FIELD_LOOP>
      <IF DECIMAL AND CUSTOM_NOT_REPLICATOR_EXCLUDE>
            if ((!<structure_name>.<field_original_name_modified>)||(!<IF NEGATIVE_ALLOWED>%IsDecimalNegatives<ELSE>%IsDecimalNoNegatives</IF NEGATIVE_ALLOWED>(<structure_name>.<field_original_name_modified>)))
                clear <structure_name>.<field_original_name_modified>
      </IF DECIMAL>
    </FIELD_LOOP>

  </IF STRUCTURE_DECIMAL_FIELDS>
  <IF STRUCTURE_DATE_FIELDS>
            ;Clean up date variables
    <FIELD_LOOP>
      <IF DATE AND CUSTOM_NOT_REPLICATOR_EXCLUDE>
            if ((!<structure_name>.<field_original_name_modified>)||(!%IsDate(^a(<structure_name>.<field_original_name_modified>))))
        <IF FIRST_UNIQUE_KEY_SEGMENT>
                ^a(<structure_name>.<field_original_name_modified>) = "17530101"
        <ELSE>
                ^a(<structure_name>.<field_original_name_modified>(1:1))=%char(0)
        </IF FIRST_UNIQUE_KEY_SEGMENT>
      </IF DATE>
    </FIELD_LOOP>

  </IF STRUCTURE_DATE_FIELDS>
  <IF STRUCTURE_TIME_FIELDS>
            ;Clean up time variables
    <FIELD_LOOP>
      <IF TIME AND CUSTOM_NOT_REPLICATOR_EXCLUDE>
            if ((!<structure_name>.<field_original_name_modified>)||(!%IsTime(^a(<structure_name>.<field_original_name_modified>))))
                ^a(<structure_name>.<field_original_name_modified>(1:1))=%char(0)
      </IF TIME>
    </FIELD_LOOP>

  </IF STRUCTURE_TIME_FIELDS>
</IF DEFINED_CLEAN_DATA>
            ;Assign any time or user-defined timestamp fields
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

            if (Settings.SqlCommandReuse) then
            begin
                ;Bind data for the current record to the existing command parameters
<IF STRUCTURE_RELATIVE>
                command.Parameters["@RecordNumber"].Value = DblToNetConverter.NumberToInt(recordNumber)
</IF STRUCTURE_RELATIVE>
<FIELD_LOOP>
  <IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
    <IF CUSTOM_DBL_TYPE>
                command.Parameters["@<FieldSqlName>"].Value = tmp<FieldSqlName>
    <ELSE ALPHA OR DECIMAL OR INTEGER OR DATE OR TIME>
                command.Parameters["@<FieldSqlName>"].Value = <FIELD_DBL_TO_NET_CONVERTER>(<structure_name>.<field_original_name_modified>)
    <ELSE USER AND USERTIMESTAMP>
                command.Parameters["@<FieldSqlName>"].Value = tmp<FieldSqlName>
    <ELSE USER AND NOT USERTIMESTAMP AND NOT DEFINED_ASA_TIREMAX>
                command.Parameters["@<FieldSqlName>"].Value = <structure_name>.<field_original_name_modified>
    <ELSE USER AND NOT USERTIMESTAMP AND DEFINED_ASA_TIREMAX>
                command.Parameters["@<FieldSqlName>"].Value = tmp<FieldSqlName>
    </IF CUSTOM_DBL_TYPE>
  </IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
</FIELD_LOOP>
            end
            else
            begin
                ;Create the SqlCommand, add parameters and bind the data for the current record
                command = new SqlCommand(sql,Settings.DatabaseConnection) { CommandTimeout = Settings.DatabaseTimeout }
<IF STRUCTURE_RELATIVE>
                command.Parameters.AddWithValue(new SqlParameter("@RecordNumber",DblToNetConverter.NumberToInt(recordNumber)))
</IF STRUCTURE_RELATIVE>
<FIELD_LOOP>
  <IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
    <IF CUSTOM_DBL_TYPE>
                command.Parameters.AddWithValue("@<FieldSqlName>",tmp<FieldSqlName>)
    <ELSE ALPHA OR DECIMAL OR INTEGER OR DATE OR TIME>
                command.Parameters.AddWithValue("@<FieldSqlName>",<FIELD_DBL_TO_NET_CONVERTER>(<structure_name>.<field_original_name_modified>))
    <ELSE USER AND USERTIMESTAMP>
                command.Parameters.AddWithValue("@<FieldSqlName>",tmp<FieldSqlName>)
    <ELSE USER AND NOT USERTIMESTAMP AND NOT DEFINED_ASA_TIREMAX>
                command.Parameters.AddWithValue("@<FieldSqlName>",<structure_name>.<field_original_name_modified>)
    <ELSE USER AND NOT USERTIMESTAMP AND DEFINED_ASA_TIREMAX>
                command.Parameters.AddWithValue("@<FieldSqlName>",tmp<FieldSqlName>)
    </IF CUSTOM_DBL_TYPE>
  </IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
</FIELD_LOOP>
            end

            ; Execute the SQL statement

            try
            begin
                command.ExecuteNonQuery()
                errorMessage = ""
            end
            catch (ex, @SqlException)
            begin
                errorMessage = "Failed to insert row. Error was: " + ex.Message
                xcall ThrowOnSqlClientError(errorMessage,ex)

                clear continue

                ;Are we logging errors?
                if (Settings.TerminalChannel)
                begin
                    writes(Settings.TerminalChannel,errorMessage)
                    continue=1
                end

                ;Are we processing exceptions?
                if (^passed(a_exception))
                begin
                    if (ex_mc==ex_ms)
                    begin
                        if (!a_exception) then
                            a_exception = %mem_proc(DM_ALLOC|DM_STATIC,^size(inpbuf)*(ex_ms=EXCEPTION_BUFSZ))
                        else
                            a_exception = %mem_proc(DM_RESIZ,^size(inpbuf)*(ex_ms+=EXCEPTION_BUFSZ),a_exception)
                    end
                    ^m(inpbuf[ex_mc+=1],a_exception)=<structure_name>
                    continue=1
                end

                if (continue) then
                    nextloop
                else
                begin
                    ok = false
                    exitloop
                end
            end
            finally
            begin
                if (!Settings.SqlCommandReuse)
                begin
                    command.Dispose()
                    command = ^null
                end
            end
            endtry
        end
    end

    ;If we're binding once, dispose the SqlCommand

    if (Settings.SqlCommandReuse && (command != ^null))
    begin
        command.Dispose()
        command = ^null
    end

    ;Commit or rollback the transaction

    if (transaction != ^null)
    begin
        if (ok) then
        begin
            ;Success, commit the transaction
            transaction.Commit()
        end
        else
        begin
            ;There was an error, rollback the transaction
            transaction.Rollback()
        end
    end

    ;If necessary, re-enable auto-commit

    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Automatic)
    begin
        try
        begin
            disposable data command = new SqlCommand("SET IMPLICIT_TRANSACTIONS OFF",Settings.DatabaseConnection) { 
            &    CommandTimeout = Settings.DatabaseTimeout
            &    }
            command.ExecuteNonQuery()
        end
        catch (ex, @SqlException)
        begin
            errorMessage = "Failed to re-enable auto-commit. Error was: " + ex.Message
            ok = false
        end
        endtry
    end

    ;If we're returning exceptions then resize the buffer to the correct size

    if (^passed(a_exception) && a_exception)
        a_exception = %mem_proc(DM_RESIZ,^size(inpbuf)*ex_mc,a_exception)

    ;Return any error message to the calling routine
    aErrorMessage = ok ? String.Empty : errorMessage

    freturn ok

endfunction

;*****************************************************************************
;;; <summary>
;;; Updates a row in the <StructureName> table.
;;; </summary>
<IF STRUCTURE_RELATIVE>
;;; <param name="a_recnum">record number.</param>
</IF STRUCTURE_RELATIVE>
;;; <param name="a_data">Record containing data to update.</param>
;;; <param name="a_rows">Returned number of rows affected.</param>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_Update, ^val
<IF STRUCTURE_RELATIVE>
    required in  a_recnum, n
</IF STRUCTURE_RELATIVE>
    required in  a_data,   a
    optional out a_rows,   i
    required out aErrorMessage, a

<IF DEFINED_ASA_TIREMAX>
    external function
        TmJulianToYYYYMMDD, a
    endexternal

</IF DEFINED_ASA_TIREMAX>
    stack record local_data
        ok,             boolean     ;OK to continue
        length,         int         ;Length of a string
        rows,           int         ;Number of rows updated
        errorMessage,   string      ;Error message text
    endrecord

    literal
        sql, string, 'UPDATE <StructureName> SET '
<FIELD_LOOP>
  <IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
    <IF USERTIMESTAMP>
        & + '"<FieldSqlName>"=CONVERT(DATETIME2,@<FieldSqlName>,21)<,>'
    <ELSE>
        & + '"<FieldSqlName>"=@<FieldSqlName><,>'
    </IF USERTIMESTAMP>
  </IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
</FIELD_LOOP>
<IF STRUCTURE_ISAM>
        & + ' WHERE <UNIQUE_KEY><SEGMENT_LOOP>"<FieldSqlName>"=@<FieldSqlName> <AND> </SEGMENT_LOOP></UNIQUE_KEY>'
<ELSE STRUCTURE_RELATIVE>
        & + ' WHERE "RecordNumber"=@RecordNumber'
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

proc
    init local_data
    ok = true
    errorMessage = String.Empty

    if (^passed(a_rows))
        clear a_rows

    ;Load the data into the bound record
<IF STRUCTURE_MAPPED>
    <structure_name> = %<structure_name>_map(a_data)
<ELSE>
    <structure_name> = a_data
</IF STRUCTURE_MAPPED>

<IF DEFINED_CLEAN_DATA>
  <IF STRUCTURE_ALPHA_FIELDS>
    ;Clean up alpha fields
    <FIELD_LOOP>
      <IF ALPHA AND CUSTOM_NOT_REPLICATOR_EXCLUDE AND NOT FIRST_UNIQUE_KEY_SEGMENT>
    <structure_name>.<field_original_name_modified> = %atrim(<structure_name>.<field_original_name_modified>)+%char(0)
      </IF ALPHA>
    </FIELD_LOOP>

  </IF STRUCTURE_ALPHA_FIELDS>
  <IF STRUCTURE_DECIMAL_FIELDS>
    ;Clean up decimal fields
    <FIELD_LOOP>
      <IF DECIMAL AND CUSTOM_NOT_REPLICATOR_EXCLUDE>
    if ((!<structure_name>.<field_original_name_modified>)||(!<IF NEGATIVE_ALLOWED>%IsDecimalNegatives<ELSE>%IsDecimalNoNegatives</IF NEGATIVE_ALLOWED>(<structure_name>.<field_original_name_modified>)))
        clear <structure_name>.<field_original_name_modified>
      </IF DECIMAL>
    </FIELD_LOOP>

  </IF STRUCTURE_DECIMAL_FIELDS>
  <IF STRUCTURE_DATE_FIELDS>
    ;Clean up date fields
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
    ;Clean up time fields
    <FIELD_LOOP>
      <IF TIME AND CUSTOM_NOT_REPLICATOR_EXCLUDE>
    if ((!<structure_name>.<field_original_name_modified>)||(!%IsTime(^a(<structure_name>.<field_original_name_modified>))))
        ^a(<structure_name>.<field_original_name_modified>(1:1)) = %char(0)
      </IF TIME>
    </FIELD_LOOP>

  </IF STRUCTURE_TIME_FIELDS>
</IF DEFINED_CLEAN_DATA>
    ;Assign time and user-defined timestamp fields
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

    ;If we're in manual commit mode, start a transaction

    disposable data transaction, @SqlTransaction
    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        transaction = Settings.DatabaseConnection.BeginTransaction()
    end

    if (ok)
    begin
        try
        begin
            disposable data command = new SqlCommand(sql,Settings.DatabaseConnection) { 
            &    CommandTimeout = Settings.DatabaseTimeout
            &    }

            ;Bind the host variables for data to be updated
<FIELD_LOOP>
  <IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
    <IF CUSTOM_DBL_TYPE>
            command.Parameters.AddWithValue("@<FieldSqlName>",tmp<FieldSqlName>)
    <ELSE ALPHA OR DECIMAL OR INTEGER OR DATE OR TIME>
            command.Parameters.AddWithValue("@<FieldSqlName>",<FIELD_DBL_TO_NET_CONVERTER>(<structure_name>.<field_original_name_modified>))
    <ELSE USER AND USERTIMESTAMP>
            command.Parameters.AddWithValue("@<FieldSqlName>",tmp<FieldSqlName>
    <ELSE USER AND NOT USERTIMESTAMP AND NOT DEFINED_ASA_TIREMAX>
            command.Parameters.AddWithValue("@<FieldSqlName>",<structure_name>.<field_original_name_modified>)
    <ELSE USER AND NOT USERTIMESTAMP AND DEFINED_ASA_TIREMAX>
            command.Parameters.AddWithValue("@<FieldSqlName>",tmp<FieldSqlName>)
    </IF CUSTOM_DBL_TYPE>
  </IF CUSTOM_NOT_REPLICATOR_EXCLUDE>
</FIELD_LOOP>

            ;Bind the host variables for the key segments / WHERE clause
<IF STRUCTURE_ISAM>
  <UNIQUE_KEY>
    <SEGMENT_LOOP>
            command.Parameters.AddWithValue("@<FieldSqlName>",<IF DATEORTIME>^a(</IF DATEORTIME><structure_name>.<segment_name><IF DATEORTIME>)</IF DATEORTIME>)
    </SEGMENT_LOOP>
  </UNIQUE_KEY>
<ELSE STRUCTURE_RELATIVE>
            command.Parameters.AddWithValue("@RecordNumber",a_recnum)
</IF STRUCTURE_ISAM>

            rows = command.ExecuteNonQuery()

            if (^passed(a_rows))
                a_rows = rows
        end
        catch (ex, @SqlException)
        begin
            errorMessage = "Failed to update row. Error was: " + ex.Message
            xcall ThrowOnSqlClientError(errorMessage,ex)
            ok = false
        end
        endtry
    end

    ;If we're in manual commit mode, commit or rollback the transaction

    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        if (ok) then
        begin
            ;Success, commit the transaction
            transaction.Commit()
        end
        else
        begin
            ;There was an error, rollback the transaction
            transaction.Rollback()
        end
    end

    ;Return any error message to the calling routine
    aErrorMessage = ok ? String.Empty : errorMessage

    freturn ok

endfunction

<IF STRUCTURE_ISAM>
;*****************************************************************************
;;; <summary>
;;; Deletes a row from the <StructureName> table.
;;; </summary>
;;; <param name="a_key">Unique key of row to be deleted.</param>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_Delete, ^val
    required in  a_key,    a
    required out aErrorMessage, a

    .include "<STRUCTURE_NOALIAS>" repository, stack record="<structureName>"

    external function
        <StructureName>KeyToRecord, a
<IF DEFINED_ASA_TIREMAX>
        TmJulianToYYYYMMDD, a
</IF DEFINED_ASA_TIREMAX>
    endexternal

    .align
    stack record local_data
        ok,             boolean     ;Return status
        cursor,         int         ;Database cursor
        errorMessage,   string      ;Error message
        sql,            string      ;SQL statement
    endrecord

proc
    init local_data
    ok = true
    errorMessage = String.Empty

    ;Put the unique key value into the record
    <structureName> = %<StructureName>KeyToRecord(a_key)

    ;If we're in manual commit mode, start a transaction
    disposable data transaction, @SqlTransaction
    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        transaction = Settings.DatabaseConnection.BeginTransaction()
    end

    ;;Delete the row
    if (ok)
    begin
        sql = 'DELETE FROM "<StructureName>" WHERE'
<UNIQUE_KEY>
  <SEGMENT_LOOP>
    <IF ALPHA>
        & + ' "<FieldSqlName>"=' + "'" + %atrim(<structureName>.<segment_name>) + "' <AND>"
    <ELSE NOT DEFINED_ASA_TIREMAX>
        &    + ' "<FieldSqlName>"=' + "'" + %string(<structureName>.<segment_name>) + "' <AND>"
    <ELSE DEFINED_ASA_TIREMAX AND USER>
        &    + " <SegmentName>='" + %TmJulianToYYYYMMDD(<structureName>.<segment_name>) + "' <AND>"
    <ELSE DEFINED_ASA_TIREMAX AND NOT USER>
        &    + ' "<FieldSqlName>"=' + "'" + %string(<structureName>.<segment_name>) + "' <AND>"
    </IF>
  </SEGMENT_LOOP>
</UNIQUE_KEY>

        try
        begin
            disposable data command = new SqlCommand(sql,Settings.DatabaseConnection) { 
            &    CommandTimeout = Settings.DatabaseTimeout
            &    }
            command.ExecuteNonQuery()
        end
        catch (ex, @SqlException)
        begin
            errorMessage = "Failed to delete row. Error was: " + ex.Message
            xcall ThrowOnSqlClientError(errorMessage,ex)
            ok = false
        end
        endtry
    end

    ;If we're in manual commit mode, commit or rollback the transaction

    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        if (ok) then
        begin
            ;Success, commit the transaction
            transaction.Commit()
        end
        else
        begin
            ;There was an error, rollback the transaction
            transaction.Rollback()
        end
    end

    ;Return any error message to the calling routine
    aErrorMessage = ok ? String.Empty : errorMessage

    freturn ok

endfunction

</IF STRUCTURE_ISAM>
;*****************************************************************************
;;; <summary>
;;; Deletes all rows from the <StructureName> table.
;;; </summary>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_Clear, ^val
    required out aErrorMessage, a

    .align
    stack record local_data
        ok,             boolean ;Return status
        errorMessage,   string  ;Returned error message text
    endrecord

proc
    init local_data
    ok = true
    errorMessage = String.Empty

    ;If we're in manual commit mode, start a transaction
    disposable data transaction, @SqlTransaction
    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        transaction = Settings.DatabaseConnection.BeginTransaction()
    end

    ;;Truncate the table
    if (ok)
    begin
        try
        begin
            disposable data command = new SqlCommand('TRUNCATE TABLE "<StructureName>"',Settings.DatabaseConnection) { 
            &    CommandTimeout = Settings.DatabaseTimeout
            &    }
            command.ExecuteNonQuery()
        end
        catch (ex, @SqlException)
        begin
            errorMessage = "Failed to truncate table. Error was: " + ex.Message
            xcall ThrowOnSqlClientError(errorMessage,ex)
            ok = false
        end
        endtry
    end

    ;If we're in manual commit mode, commit or rollback the transaction
    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        if (ok) then
        begin
            ;Success, commit the transaction
            transaction.Commit()
        end
        else
        begin
            ;There was an error, rollback the transaction
            transaction.Rollback()
        end
    end

    ;Return any error message to the calling routine
    aErrorMessage = ok ? String.Empty : errorMessage

    freturn ok

endfunction

;*****************************************************************************
;;; <summary>
;;; Deletes the <StructureName> table from the database.
;;; </summary>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_Drop, ^val
    required out aErrorMessage, a

    .align
    stack record
        ok, boolean
        errorMessage, string
    endrecord

proc
    ok = true
    errorMessage = String.Empty

    ;If we're in manual commit mode, start a transaction
    disposable data transaction, @SqlTransaction
    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        transaction = Settings.DatabaseConnection.BeginTransaction()
    end

    ;Drop the database table and primary key constraint
    try
    begin
        disposable data command = new SqlCommand("DROP TABLE <StructureName>",Settings.DatabaseConnection) { 
        &   CommandTimeout = Settings.DatabaseTimeout
        & }
        command.ExecuteNonQuery()
    end
    catch (ex, @SqlException)
    begin
        using ex.Number select
        (3701), ;Cannot drop the table '<StructureName>', because it does not exist or you do not have permission.
            nop
        (),
        begin
            errorMessage = "Failed to drop table. Error was: " + ex.Message
            xcall ThrowOnSqlClientError(errorMessage,ex)
            ok = false
        end
        endusing
    end
    endtry 

    ;Commit or rollback the transaction

    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        if (ok) then
        begin
            ;Success, commit the transaction
            transaction.Commit()
        end
        else
        begin
            ;There was an error, rollback the transaction
            transaction.Rollback()
        end
    end

    ;Return any error message to the calling routine
    aErrorMessage = ok ? String.Empty : errorMessage

    freturn ok

endfunction

;*****************************************************************************
;;; <summary>
;;; Load all data from <IF STRUCTURE_MAPPED><MAPPED_FILE><ELSE><FILE_NAME></IF STRUCTURE_MAPPED> into the <StructureName> table.
;;; </summary>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <param name="a_added">Total number of successful inserts.</param>
;;; <param name="a_failed">Total number of failed inserts.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_Load, ^val
    required in  a_maxrows, n
    required out a_added, n
    required out a_failed, n
    required out aErrorMessage, a

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
        ok,             boolean     ;Return status
        firstRecord,    boolean     ;Is this the first record?
        filechn,        int         ;Data file channel
        mh,             D_HANDLE    ;Memory handle containing data to insert
        ms,             int         ;Size of memory buffer in rows
        mc,             int         ;Memory buffer rows currently used
        ex_mh,          D_HANDLE    ;Memory buffer for exception records
        ex_mc,          int         ;Number of records in returned exception array
        ex_ch,          int         ;Exception log file channel
        attempted,      int         ;Rows being attempted
        done_records,   int         ;Records loaded
        max_records,    int         ;Maximum records to load
        ttl_added,      int         ;Total rows added
        ttl_failed,     int         ;Total failed inserts
        errnum,         int         ;Error number
        tmperrmsg,      a512        ;Temporary error message
        errorMessage,   string      ;Error message text
        now,            a20        ;;Current date and time
        timer,          @Timer
<IF STRUCTURE_RELATIVE>
        recordNumber,   d28
</IF STRUCTURE_RELATIVE>
    endrecord

proc
    init local_data
    ok = true
    errorMessage = String.Empty

    timer = new Timer()
    timer.Start()

    ;If we are logging exceptions, delete any existing exceptions file.
    if (Settings.LogBulkLoadExceptions)
    begin
        xcall delet("REPLICATOR_LOGDIR:<structure_name>_data_exceptions.log")
    end

    ;Open the data file associated with the structure
    if (!(filechn = %<StructureName>OpenInput(tmperrmsg)))
    begin
        errorMessage = "Failed to open data file! Error was " + %atrimtostring(tmperrmsg)
        ok = false
    end

    if (ok)
    begin
        ;Were we passed a max # records to load
        max_records = a_maxrows > 0 ? a_maxrows : 0
        done_records = 0

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
                errorMessage = "Unexpected error while reading data file: " + ex.Message
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

        ;;Deallocate memory buffer
        mh = %mem_proc(DM_FREE,mh)
    end

    ;Close the file
    if (filechn && %chopen(filechn))
        close filechn

    ;Close the exceptions log file
    if (ex_ch && %chopen(ex_ch))
        close ex_ch

    ;Return totals
    a_added = ttl_added
    a_failed = ttl_failed

    ;Return any error message to the calling routine
    aErrorMessage = ok ? String.Empty : errorMessage

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

    if (!%<StructureName>_InsertRows(mh,tmperrmsg,ex_mh)) then
    begin
        errorMessage = %atrimtostring(tmperrmsg)
    end
    else
    begin
        ;;Any exceptions?
        if (ex_mh) then
        begin
            ;How many exceptions to log?
            ex_mc = %mem_proc(DM_GETSIZE,ex_mh) / ^size(inpbuf)

            ;Update totals
            ttl_failed += ex_mc
            ttl_added += (attempted-ex_mc)

            ;Are we logging exceptions?
            if (Settings.LogBulkLoadExceptions) then
            begin
                data cnt, int

                ;Open the log file
                if (!ex_ch)
                begin
                    open(ex_ch=0,o:s,"REPLICATOR_LOGDIR:<structure_name>_data_exceptions.log")
                end

                ;Log the exceptions
                for cnt from 1 thru ex_mc
                begin
                    writes(ex_ch,^m(inpbuf[cnt],ex_mh))
                end

                ;And maybe show them on the terminal
                if (Settings.TerminalChannel)
                begin
                    writes(Settings.TerminalChannel,"Exceptions were logged to REPLICATOR_LOGDIR:<structure_name>_data_exceptions.log")
                end
            end
            else
            begin
                ;No, report and error
                ok = false
            end

            ;Release the exception buffer
            ex_mh = %mem_proc(DM_FREE,ex_mh)
        end
        else
        begin
            ;No exceptions
            ttl_added += attempted
            if (Settings.TerminalChannel && Settings.LogLoadProgress)
            begin
                writes(Settings.TerminalChannel," - " + %string(ttl_added) + " rows inserted")
            end
        end
    end

    clear mc

    return

endfunction

;*****************************************************************************
;;; <summary>
;;; Bulk load data from <IF STRUCTURE_MAPPED><MAPPED_FILE><ELSE><FILE_NAME></IF STRUCTURE_MAPPED> into the <StructureName> table via a CSV file.
;;; </summary>
;;; <param name="recordsToLoad">Number of records to load (0=all)</param>
;;; <param name="a_records">Records loaded</param>
;;; <param name="a_exceptions">Records failes</param>
;;; <param name="aErrorMessage">Error message (if return value is false)</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_BulkLoad, ^val
    required in recordsToLoad,  n
    required out a_records,     n
    required out a_exceptions,  n
    required out aErrorMessage, a

     stack record local_data
        ok,                     boolean    ;;Return status
        remoteBulkLoad,         boolean
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
        recordCount,            int	        ;# records loaded
        exceptionCount,         int         ;# records failed
        errtxt,                 a512        ;Temp error message
        errorMessage,           string      ;Error message
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
            errorMessage = "No response from FileService, bulk load cancelled"
            now = %datetime
            writelog(errorMessage)
            writett(errorMessage)
            ok = false
        end
    end

    ;Define temp file names and make sure there are no local temp files left over from a previous operation

    if (ok)
    begin
        .ifdef OS_VMS
        localCsvFile = String.Format("{0}<StructureName>.csv",Settings.LocalExportPath)
        .else
        localCsvFile = Path.Combine(Settings.LocalExportPath,"<StructureName>.csv")
        .endc
        localExceptionsFile = String.Format("{0}_err",localCsvFile)
        localExceptionsLog = String.Format("{0}.Error.Txt",localExceptionsFile)

        if (remoteBulkLoad)
        begin
            remoteCsvFile = "<StructureName>.csv"
            remoteExceptionsFile = String.Format("{0}_err",remoteCsvFile)
            remoteExceptionsLog = String.Format("{0}.Error.Txt",remoteExceptionsFile)
        end

        now = %datetime
        writelog("Deleting local temp files")
        writett("Deleting local temp files")

        if (File.Exists(localCsvFile))
        begin
            try
            begin
                File.Delete(localCsvFile)
            end
            catch (ex)
            begin
                nop
            end
            endtry
        end

        if (File.Exists(localExceptionsFile))
        begin
            try
            begin
                File.Delete(localExceptionsFile)
            end
            catch (ex)
            begin
                nop
            end
            endtry
        end

        if (File.Exists(localExceptionsLog))
        begin
            try
            begin
                File.Delete(localExceptionsLog)
            end
            catch (ex)
            begin
                nop
            end
            endtry
        end

        ;Delete remote files

        if (remoteBulkLoad)
        begin
            now = %datetime
            writelog("Deleting remote temp files")
            writett("Deleting remote temp files")

            fsc.Delete(remoteCsvFile)
            fsc.Delete(remoteExceptionsFile)
            fsc.Delete(remoteExceptionsLog)
        end

        ;Were we asked to load a specific number of records?

        recordCount =  recordCount > 0 ? recordCount : 0

        ;And export the data

        now = %datetime
        writelog("Exporting data")
        writett("Exporting data")

        ok = %<StructureName>_Csv(localCsvFile,0,recordCount,errtxt)

        errorMessage = ok ? String.Empty : %atrimtostring(errtxt)
    end

    ;If necessary, upload the exported file to the database server

    if (ok)
    begin
        if (remoteBulkLoad) then
        begin
            now = %datetime
            writelog("Uploading data to database server")
            writett("Uploading data to database server")
            ok = fsc.UploadChunked(localCsvFile,remoteCsvFile,320,fileToLoad,errtxt)
            errorMessage = ok ? String.Empty : %atrimtostring(errtxt)
        end
        else
        begin
            fileToLoad  = localCsvFile
        end
    end

    ;If we're in manual commit mode, start a transaction

    disposable data transaction, @SqlTransaction
    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        transaction = Settings.DatabaseConnection.BeginTransaction()
    end

    ;Execute the BULK INSERT statement

    if (ok)
    begin
        data sql = String.Format("BULK INSERT <StructureName> FROM '{0}' WITH (FIRSTROW=2,FIELDTERMINATOR='|',ROWTERMINATOR='\n',MAXERRORS=100000000,ERRORFILE='{0}_err'",fileToLoad)

        if (Settings.BulkLoadBatchSize > 0)
        begin
            sql = String.Format("{0},BATCHSIZE={1}",sql,Settings.BulkLoadBatchSize)
        end

        sql = String.Format("{0})",sql)

        now = %datetime
        writelog("Executing BULK INSERT")
        writett("Executing BULK INSERT")

        try
        begin
            disposable data command = new SqlCommand(sql,Settings.DatabaseConnection) { 
            &    CommandTimeout = Settings.BulkLoadTimeout
            &    }
            command.ExecuteNonQuery()
        end
        catch (ex, @SqlException)
        begin
            errorMessage = "BULK INSERT failed. Error was: " + ex.Message
            xcall ThrowOnSqlClientError(errorMessage,ex)

            now = %datetime
            writelog("Bulk insert failed. " + ex.Message)
            writett("Bulk insert failed. " + ex.Message)

            using ex.Number select
            (-4864),
            begin
                ;Bulk load data conversion error
                now = %datetime
                writelog("Data conversion errors were reported")
                writett("Data conversion errors were reported")
                errorMessage = String.Empty

                ;------------------------------------------------------------------------------------------------------------
                ;This used to be an internal subroutine GetExceptionDetails but in .NET we can't call it from here! Sucks!

                ;If we get here the bulk load reported one or more "data conversion error" issues and there should be two log files on the server

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
                            ;Error file does not exist. This should not happen because we got here due to data conversion errors being reported
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
                            ;Error file does not exist. This should not happen because we got here due to data conversion errors being reported
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
                        ;Error file does not exist. This should not happen because we got here due to data conversion errors being reported
                        now = %datetime
                        writelog("Exceptions data file not found!")
                    end
                end

                ;------------------------------------------------------------------------------------------------------------
            end
            (),
            begin
                errorMessage = String.Format("{0} {1}",ex.Number,errorMessage)
                ok = false
            end
            endusing
        end
        endtry
    end

    ;Delete local temp files

    now = %datetime
    writelog("Deleting local temp files")
    writett("Deleting local temp files")

    if (File.Exists(localCsvFile))
    begin
        try
        begin
            File.Delete(localCsvFile)
        end
        catch (ex)
        begin
            nop
        end
        endtry
    end

    if (File.Exists(localExceptionsFile))
    begin
        try
        begin
            File.Delete(localExceptionsFile)
        end
        catch (ex)
        begin
            nop
        end
        endtry
    end

    if (File.Exists(localExceptionsLog))
    begin
        try
        begin
            File.Delete(localExceptionsLog)
        end
        catch (ex)
        begin
            nop
        end
        endtry
    end

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

    ;If we're in manual commit mode, commit or rollback the transaction
    if (Settings.DatabaseCommitMode == DatabaseCommitMode.Manual)
    begin
        if (ok) then
        begin
            ;Success, commit the transaction
            transaction.Commit()
        end
        else
        begin
            ;There was an error, rollback the transaction
            transaction.Rollback()
        end
    end

    ;Return the record and exceptions count
    a_records = recordCount
    a_exceptions = exceptionCount

    timer.Stop()
    now = %datetime

    if (ok) then
    begin
        writelog("Bulk load finished in " + timer.ElapsedTimeString)
        writett("Bulk load finished in " + timer.ElapsedTimeString)
    end
    else
    begin
        aErrorMessage = errorMessage
        writelog("Bulk load failed after " + timer.ElapsedTimeString)
        writett("Bulk load failed after " + timer.ElapsedTimeString)
    end

    freturn ok

endfunction

;*****************************************************************************
;;; <summary>
;;; Exports <IF STRUCTURE_MAPPED><MAPPED_FILE><ELSE><FILE_NAME></IF> to a CSV file.
;;; </summary>
;;; <param name="fileSpec">File to create</param>
;;; <param name="maxRecords">Mumber of records to export.</param>
;;; <param name="recordCount">Returned number of records exported.</param>
;;; <param name="errorMessage">Returned error text.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_Csv, boolean
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
        errtxt,     a512    ;Error message text
        now,        a20     ;The time now
        timer,      @Timer  ;A timer
    endrecord

proc
    init local_data
    ok = true
    recordCount = 0
    errorMessage = ""

    timer = new Timer()
    timer.Start()

    ;;Open the data file associated with the structure

    if (!(filechn=%<StructureName>OpenInput(errtxt)))
    begin
        errtxt = "Failed to open data file! Error was: " + errtxt
        ok = false
    end

    ;;Create the local CSV file

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

        ;;Add a row of column headers
.ifdef OS_WINDOWS7
        writes(outchn,"<IF STRUCTURE_RELATIVE>RecordNumber|</IF><FIELD_LOOP><IF CUSTOM_NOT_REPLICATOR_EXCLUDE><FieldSqlName><IF MORE>|</IF></IF></FIELD_LOOP>")
.else
        puts(outchn,"<IF STRUCTURE_RELATIVE>RecordNumber|</IF><FIELD_LOOP><IF CUSTOM_NOT_REPLICATOR_EXCLUDE><FieldSqlName><IF MORE>|</IF></IF></FIELD_LOOP>" + %char(13) + %char(10))
.endc

        ;;Read and add data file records
        foreach <structure_name> in new Select(new From(filechn,Q_NO_GRFA,0,<structure_name>)<IF STRUCTURE_TAGS>,(Where)(<TAG_LOOP><TAGLOOP_CONNECTOR_C>(<structure_name>.<tagloop_field_name><TAGLOOP_OPERATOR_DBL><TAGLOOP_TAG_VALUE>)</TAG_LOOP>)</IF>)
        begin
            ;;Make sure there are no | characters in the data
            data pos, int
            while (pos = %instr(1,<structure_name>,"|"))
            begin
                clear <structure_name>(pos:1)
            end

            incr records

            if (maxRecords && (records > maxRecords))
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

    ;Return any error message to the calling routine
    errorMessage = %atrim(errtxt)

    timer.Stop()
    now = %datetime

    if (ok)
    begin
        writelog("Export took " + timer.ElapsedTimeString)
        writett("Export took " + timer.ElapsedTimeString)
    end

    freturn ok

endfunction

.endc

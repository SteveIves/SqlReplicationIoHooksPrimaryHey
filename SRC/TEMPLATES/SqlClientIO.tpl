<CODEGEN_FILENAME><StructureName>_SqlIO.dbl</CODEGEN_FILENAME>
<REQUIRES_CODEGEN_VERSION>5.6.3</REQUIRES_CODEGEN_VERSION>
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
;//              The code produced by this template uses the .NET System.Data.SqlClient classes
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
;;*****************************************************************************
;;
;; File:        <StructureName>_SqlIO.dbl
;;
;; Description: Various functions that performs SQL I/O for <STRUCTURE_NAME>
;;
;;*****************************************************************************
;; WARNING: THIS CODE WAS CODE GENERATED AND WILL BE OVERWRITTEN IF CODE
;;          GENERATION IS RE-EXECUTED FOR THIS PROJECT.
;;*****************************************************************************

.ifndef DBLNET
 ;This code was generated from the SqlClientIO template and can only be used
 ;in .NET. For traditional DBL environments use the SqlIO template
.else

import ReplicationLibrary
import Synergex.SynergyDE.Select
import System.Data.SqlClient

.ifndef str<StructureName>
.include "<STRUCTURE_NOALIAS>" repository, structure="str<StructureName>", end
.endc

.define writelog(x) if Settings.LogFileChannel && %chopen(Settings.LogFileChannel) writes(Settings.LogFileChannel,%string(^d(now(1:14)),"XXXX-XX-XX XX:XX:XX ") + x)
.define writett(x)  if Settings.TerminalChannel writes(Settings.TerminalChannel,"   - " + %string(^d(now(9:8)),"XX:XX:XX.XX ") + x)

;;*****************************************************************************
;;; <summary>
;;; Determines if the <StructureName> table exists in the database.
;;; </summary>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <returns>Returns 1 if the table exists, otherwise a number indicating the type of error.</returns>

function <StructureName>_Exists, ^val
    optional out aErrorMessage, a
    endparams
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
            ; Table exists
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
    end
    endtry

    if (^passed(aErrorMessage) && error)
    begin
        aErrorMessage = errorMessage
    end

    ;TODO: Old code included xcall ThrowOnCommunicationError(dberror,errtxt)

    freturn error

endfunction

;;*****************************************************************************
;;; <summary>
;;; Creates the <StructureName> table in the database.
;;; </summary>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_Create, ^val
    optional out aErrorMessage, a
    endparams

    .align
    stack record
        ok, boolean
        transactionInProgress, boolean
        errorMessage, string
    endrecord
    static record
        createTableCommand, string
    endrecord
proc
    ok = true
    transactionInProgress = false
    errorMessage = String.Empty

    ;Define the CREATE TABLE statement

    if (createTableCommand == ^null)
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

    ;;Create the database table and primary key constraint

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

    ;;Grant access permissions

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

    ;;Commit or rollback the transaction

    if (Settings.CommitMode == DatabaseCommitMode.Manual)
    begin
        if (ok) then
        begin
            ;;Success, commit the transaction
            try
            begin
                disposable data command = new SqlCommand("COMMIT",Settings.DatabaseConnection) { 
                &   CommandTimeout = Settings.DatabaseTimeout
                & }
                command.ExecuteNonQuery()
            end
            catch (ex, @SqlException)
            begin
                ok = false
                errorMessage = "Failed to commit transaction. Error was: " + ex.Message
                ;TODO: xcall ThrowOnCommunicationError(dberror,errtxt)
            end
            endtry
        end
        else
        begin
            ;;There was an error, rollback the transaction
            try
            begin
                disposable data command = new SqlCommand("ROLLBACK",Settings.DatabaseConnection) { 
                &   CommandTimeout = Settings.DatabaseTimeout
                & }
                command.ExecuteNonQuery()
            end
            catch (ex, @SqlException)
            begin
                ok = false
                errorMessage = "Failed to roll back transaction. Error was: " + ex.Message
                ;TODO: xcall ThrowOnCommunicationError(dberror,errtxt)
            end
            endtry
        end
    end

    ;;If there was an error message, return it to the calling routine

    if (^passed(aErrorMessage))
    begin
        if (ok) then
            clear aErrorMessage
        else
            aErrorMessage = errorMessage
    end

    freturn ok

endfunction

<IF STRUCTURE_ISAM>
;;*****************************************************************************
;;; <summary>
;;; Add alternate key indexes to the <StructureName> table if they do not exist.
;;; </summary>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_Index, ^val
    optional out aErrorMessage, a
    endparams

    .align
    stack record
        ok, boolean
        errorMessage, string
        now, a20
    endrecord

proc
    ok = false
    errorMessage = String.Empty

  <IF NOT STRUCTURE_HAS_UNIQUE_PK>
;    ;;The structure has no unique primary key, so no primary key constraint was added to the table. Create an index instead.
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
    ;;Create index <KEY_NUMBER> (<KEY_DESCRIPTION>)

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
    ;;Commit or rollback the transaction

    if (Settings.CommitMode == DatabaseCommitMode.Manual)
    begin
        if (ok) then
        begin
            ;;Success, commit the transaction
            try
            begin
                disposable data command = new SqlCommand("COMMIT",Settings.DatabaseConnection) { 
                &   CommandTimeout = Settings.DatabaseTimeout
                & }
                command.ExecuteNonQuery()
            end
            catch (ex, @SqlException)
            begin
                ok = false
                errorMessage = "Failed to commit transaction. Error was: " + ex.Message
                ;TODO: xcall ThrowOnCommunicationError(dberror,errtxt)
            end
            endtry
        end
        else
        begin
            ;;There was an error, rollback the transaction
            try
            begin
                disposable data command = new SqlCommand("ROLLBACK",Settings.DatabaseConnection) { 
                &   CommandTimeout = Settings.DatabaseTimeout
                & }
                command.ExecuteNonQuery()
            end
            catch (ex, @SqlException)
            begin
                ok = false
                errorMessage = "Failed to roll back transaction. Error was: " + ex.Message
                ;TODO: xcall ThrowOnCommunicationError(dberror,errtxt)
            end
            endtry
        end
    end

    if (^passed(aErrorMessage) && !ok)
    begin
        aErrorMessage = errorMessage
    end

    freturn ok

endfunction

;;*****************************************************************************
;;; <summary>
;;; Removes alternate key indexes from the <StructureName> table in the database.
;;; </summary>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_UnIndex, ^val
    optional out aErrorMessage, a
    endparams

    .align
    stack record
        ok, boolean
        errorMessage, string
    endrecord

proc
    ok = false
    errorMessage = String.Empty





    if (!ok && ^passed(aErrorMessage))
    begin
        aErrorMessage = errorMessage
    end

    freturn ok

endfunction

</IF STRUCTURE_ISAM>
;;*****************************************************************************
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
    optional out aErrorMessage, a
    endparams

    .align
    stack record
        ok, boolean
        errorMessage, string
        sts, int
    endrecord

proc
    ok = false
    errorMessage = String.Empty


    if (!ok && ^passed(aErrorMessage))
    begin
        aErrorMessage = errorMessage
    end

    freturn sts

endfunction

;;*****************************************************************************
;;; <summary>
;;; Inserts multiple rows into the <StructureName> table.
;;; </summary>
;;; <param name="a_data">Memory handle containing one or more rows to insert.</param>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <param name="a_exception">Memory handle to load exception data records into.</param>
;;; <param name="a_terminal">Terminal number channel to log errors on.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_InsertRows, ^val
    required in  a_data, i
    optional out aErrorMessage, a
    optional out a_exception, i
    optional in  a_terminal, i
    endparams

    .align
    stack record
        ok, boolean
        errorMessage, string
    endrecord

proc
    ok = false
    errorMessage = String.Empty




    if (!ok && ^passed(aErrorMessage))
    begin
        aErrorMessage = errorMessage
    end

    freturn ok

endfunction

;;*****************************************************************************
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
    optional out aErrorMessage, a
    endparams

    .align
    stack record
        ok, boolean
        errorMessage, string
    endrecord

proc
    ok = false
    errorMessage = String.Empty




    if (!ok && ^passed(aErrorMessage))
    begin
        aErrorMessage = errorMessage
    end

    freturn ok

endfunction

<IF STRUCTURE_ISAM>
;;*****************************************************************************
;;; <summary>
;;; Deletes a row from the <StructureName> table.
;;; </summary>
;;; <param name="a_key">Unique key of row to be deleted.</param>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_Delete, ^val
    required in  a_key,    a
    optional out aErrorMessage, a
    endparams

    .align
    stack record
        ok, boolean
        errorMessage, string
    endrecord

proc
    ok = false
    errorMessage = String.Empty





    if (!ok && ^passed(aErrorMessage))
    begin
        aErrorMessage = errorMessage
    end

    freturn ok

endfunction

</IF STRUCTURE_ISAM>
;;*****************************************************************************
;;; <summary>
;;; Deletes all rows from the <StructureName> table.
;;; </summary>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_Clear, ^val
    optional out aErrorMessage, a
    endparams

    .align
    stack record
        ok, boolean
        errorMessage, string
    endrecord

proc
    ok = false
    errorMessage = String.Empty






    if (!ok && ^passed(aErrorMessage))
    begin
        aErrorMessage = errorMessage
    end

    freturn ok

endfunction

;;*****************************************************************************
;;; <summary>
;;; Deletes the <StructureName> table from the database.
;;; </summary>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_Drop, ^val
    optional out aErrorMessage, a
    endparams

    .align
    stack record
        ok, boolean
        errorMessage, string
    endrecord

proc
    ok = false
    errorMessage = String.Empty







    if (!ok && ^passed(aErrorMessage))
    begin
        aErrorMessage = errorMessage
    end

    freturn ok

endfunction

;;*****************************************************************************
;;; <summary>
;;; Load all data from <IF STRUCTURE_MAPPED><MAPPED_FILE><ELSE><FILE_NAME></IF STRUCTURE_MAPPED> into the <StructureName> table.
;;; </summary>
;;; <param name="aErrorMessage">Returned error text.</param>
;;; <param name="a_added">Total number of successful inserts.</param>
;;; <param name="a_failed">Total number of failed inserts.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_Load, ^val
    optional out   aErrorMessage, a
    optional inout a_added, n
    optional out   a_failed, n
    endparams

    .align
    stack record
        ok, boolean
        errorMessage, string
    endrecord

proc
    ok = false
    errorMessage = String.Empty








    if (!ok && ^passed(aErrorMessage))
    begin
        aErrorMessage = errorMessage
    end

    freturn ok

endfunction

;;*****************************************************************************
;;; <summary>
;;; Bulk load data from <IF STRUCTURE_MAPPED><MAPPED_FILE><ELSE><FILE_NAME></IF STRUCTURE_MAPPED> into the <StructureName> table via a CSV file.
;;; </summary>
;;; <param name="a_connection">Established database connection.</param>
;;; <param name="a_commit_mode">What commit mode are we using?</param>
;;; <param name="a_localpath">Path to local export directory</param>
;;; <param name="a_remotepath">Remote export directory or URL</param>
;;; <param name="a_db_timeout">Database timeout in seconds.</param>
;;; <param name="a_bl_timeout">Bulk load timeout in seconds.</param>
;;; <param name="a_bl_batchsz">Bulk load batch size in rows.</param>
;;; <param name="a_logchannel">Log file channel to log messages on.</param>
;;; <param name="a_records">Total number of records processed</param>
;;; <param name="a_exceptions">Total number of exception records detected</param>
;;; <param name="a_errtxt">Returned error text.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_BulkLoad, ^val
    required in  a_connection, @SqlConnection
    required in  a_commit_mode,i
    required in  a_localpath,  a
    required in  a_server,     a
    required in  a_port,       i
    required in  a_db_timeout, n
    required in  a_bl_timeout, n
    required in  a_bl_batchsz, n
    optional in  a_logchannel, n
    optional in  a_ttchannel,  n
    optional out a_records,    n
    optional out a_exceptions, n
    optional out a_errtxt,     a
    endparams

    .align
    stack record local_data
        ok, boolean
    endrecord

proc
    init local_data
    ok = false

    freturn ok

endfunction

;;*****************************************************************************
;;; <summary>
;;; Close cursors associated with the <StructureName> table.
;;; </summary>
;;; <param name="a_connection">Established database connection.</param>
;;; <param name="a_commit_mode">What commit mode are we using?</param>

subroutine <StructureName>_Close
    required in a_connection, @SqlConnection
    endparams

proc

    xreturn

endsubroutine

;;*****************************************************************************
;;; <summary>
;;; Exports <IF STRUCTURE_MAPPED><MAPPED_FILE><ELSE><FILE_NAME></IF STRUCTURE_MAPPED> to a CSV file.
;;; </summary>
;;; <param name="fileSpec">File to create</param>
;;; <param name="recordCount">Passed number of records to export, returned number of records exported.</param>
;;; <param name="errorMessage">Returned error text.</param>
;;; <returns>Returns true on success, otherwise false.</returns>

function <StructureName>_Csv, boolean
    required in    fileSpec, a
    optional inout recordCount, n
    optional out   errorMessage, a
    endparams

    .include "<STRUCTURE_NOALIAS>" repository, record="<structure_name>", end

    .align
    stack record local_data
        ok,                             boolean     ;;Return status
    endrecord

proc
    init local_data
    ok = false

    freturn ok

endfunction

.endc

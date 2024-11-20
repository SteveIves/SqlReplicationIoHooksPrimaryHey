<CODEGEN_FILENAME>GetReplicatedTables.dbl</CODEGEN_FILENAME>
;//*****************************************************************************
;//
;// Title:      GetReplicatedTables.tpl
;//
;// Description:Creates a subroutine to return a collection of table names that
;//             are included in the replication environment.
;//
;// Author:     Steve Ives, Synergex Professional Services Group
;//
;// Copyright   � 2018 Synergex International Corporation.  All rights reserved.
;//
;;*****************************************************************************
;;
;; File:        GetReplicatedTables.dbl
;;
;; Description: Returns a collection of replicated table names
;;
;; Author:      Steve Ives, Synergex Professional Services Group
;;
;;*****************************************************************************
;;
;; Copyright (c) 2018, Synergex International, Inc.
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are met:
;;
;; * Redistributions of source code must retain the above copyright notice,
;;   this list of conditions and the following disclaimer.
;;
;; * Redistributions in binary form must reproduce the above copyright notice,
;;   this list of conditions and the following disclaimer in the documentation
;;   and/or other materials provided with the distribution.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;; POSSIBILITY OF SUCH DAMAGE.
;;
;;*****************************************************************************
;; WARNING: THIS CODE WAS CODE GENERATED AND WILL BE OVERWRITTEN IF CODE
;;          GENERATION IS RE-EXECUTED FOR THIS PROJECT.
;;*****************************************************************************

import System.Collections

subroutine GetReplicatedTables
    required in instanceName, string
    required out tables, @ArrayList
    static record
        defaultTables, @ArrayList
    endrecord
proc
    using instanceName select
    ("DEFAULT"),
    begin
        if (defaultTables == ^null)
        begin
            defaultTables = new ArrayList()
            <STRUCTURE_LOOP>
            defaultTables.Add((string)"<StructureName>")
            </STRUCTURE_LOOP>
        end
        tables = defaultTables
    end
    endusing

    xreturn

endsubroutine

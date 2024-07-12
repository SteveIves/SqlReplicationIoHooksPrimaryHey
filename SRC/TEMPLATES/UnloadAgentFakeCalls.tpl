<CODEGEN_FILENAME>UnloadAgentFakeCalls.dbl</CODEGEN_FILENAME>
<REQUIRES_OPTION>MS</REQUIRES_OPTION>

subroutine UnloadAgentFakeCalls
    stack record
        tmpa, a1
    endrecord
    external function
        <StructureName>File, ^val
        <StructureName>Length, ^val
        <StructureName>OpenInput, ^val
        <StructureName>Type, ^val
    endexternal
proc
<STRUCTURE_LOOP>
    xcall <StructureName>File(tmpa)
    xcall <StructureName>Length
    xcall <StructureName>OpenInput(tmpa)
    xcall <StructureName>Type(tmpa)
</STRUCTURE_LOOP>
	xreturn
endsubroutine
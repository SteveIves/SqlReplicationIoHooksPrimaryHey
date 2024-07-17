$!=============================================================================
$!
$! Title:   COMPRESS.COM
$!
$! Author:  Steve Ives, Synergex Professional Services Group, July 2024
$!
$! Usage:   @COMPRESS <file-to-compress> <zip-file-spec> [VERBOSE]
$!
$!=============================================================================
$!
$! Check we have two parameters
$!
$ if p3.eqs."VERBOSE" then write sys$output "COMPRESS.COM: Checking parameters"
$!
$ if (p1.eqs."") .or. (p2.eqs."")
$ then
$    write sys$output "ERROR: Invalid parameters, specify input and output files"
$    exit
$ endif
$!
$! Check the first parameter is a valid file spec and the file exists
$!
$ if p3.eqs."VERBOSE" then write sys$output "COMPRESS.COM: Checking input file exists"
$!
$ if (f$parse(P1).eqs."") .or. (f$search(P1).eqs."")
$ then
$    write sys$output "ERROR: Invalid input file spec or file not found  ''P1'"
$    exit
$ endif
$!
$! Check the second parameter is a valid file spec
$!
$ if p3.eqs."VERBOSE" then write sys$output "COMPRESS.COM: Checking zip file spec"
$!
$ if (f$parse(P2).eqs."")
$ then
$    write sys$output "ERROR: Invalid output file spec ''P2'"
$ endif
$!
$! If the zip file exists, delete it
$!
$ if (f$search(P2).nes."")
$ then
$    if p3.eqs."VERBOSE" then write sys$output "COMPRESS.COM: Deleting existing zip file(s)"
$    delete/nolog/noconfirm 'P2;*
$ endif
$!
$! Zip the file
$!
$ if p3.eqs."VERBOSE" then write sys$output "COMPRESS.COM: Creating ZIP file"
$!
$ zip:==$DKA100:[USR.BIN]ZIP30_I64.EXE
$ zip -j -q "''P2'" 'P1
$!
$ if ($severity.ne.1) .or. (f$search(P2).eqs."")
$ then
$	write sys$output "ERROR: Failed to compress file"
$	exit
$ endif
$!
$ if p3.eqs."VERBOSE" then write sys$output "COMPRESS.COM: Deleting export file"
$!
$ delete/noconfirm/nolog 'p1;*
$!
$! All done
$!
$ if p3.eqs."VERBOSE" then write sys$output "COMPRESS.COM: All done"
$!
$ write sys$output "SUCCESS"
$!
$ exit

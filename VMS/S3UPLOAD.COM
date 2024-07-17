$!=============================================================================
$!
$! Title:   S3UPLOAD.COM
$!
$! Author:  Steve Ives, Synergex Professional Services Group, July 2024
$!
$! Usage:   @S3UPLOAD <zip-file-spec> [VERBOSE]
$!
$!=============================================================================
$!
$! Check we have a valid file in parameter 1
$!
$ if p2.eqs."VERBOSE" then write sys$output "S3UPLOAD.COM: Checking input file"
$!
$ if ((p1.eqs."") .or. (f$parse(p1).eqs."") .or. (f$search(p1).eqs.""))
$ then
$    write sys$output "ERROR: Invalid input file or file not found"
$    exit
$ endif
$!
$!-----------------------------------------------------------------------------
$! Check we have Python and define the PYTHON symbol
$!
$ if p2.eqs."VERBOSE" then write sys$output "S3UPLOAD.COM: Checking Python runtime"
$!
$ if (f$search("PYTHON$ROOT:[BIN]PYTHON3.EXE").eqs."")
$ then
$     write sys$output "ERROR: Python 3 is not installed"
$     exit
$ endif
$!
$ PYTHON:==$PYTHON$ROOT:[BIN]PYTHON3.EXE
$!
$!-----------------------------------------------------------------------------
$! Check the Python script has correct record attributes
$!
$ if p2.eqs."VERBOSE" then write sys$output "S3UPLOAD.COM: Checking Python script"
$!
$ if (f$search("STREAMLF.FDL").eqs."")
$ then
$    write sys$output "ERROR: STREAMLF.FDL not found"
$    exit
$ endif
$!
$ if (f$file_attributes("S3UPLOAD.PY","RFM").nes."STMLF")
$ then
$   convert/fdl=STREAMLF.FDL S3UPLOAD.PY S3UPLOAD.PY
$   purge/nolog S3UPLOAD.PY
$ endif
$!
$!-----------------------------------------------------------------------------
$! Upload the file
$!
$ if p2.eqs."VERBOSE" then write sys$output "S3UPLOAD.COM: Uploading file"
$!
$ PYTHON S3UPLOAD.PY 'p1
$!
$!******
$!    It would be nice to do more here, but apparently we never get back here
$!    after the Pythin script completes, so the code below never runs!
$!******
$!
$ if ($severity.ne.1)
$ then
$	write sys$output "ERROR: Failed to upload file"
$	exit
$ endif
$!
$! Delete the ZIP file
$!
$ if p2.eqs."VERBOSE" then write sys$output "S3UPLOAD.COM: Deleting ZIP file"
$!
$ delete/noconf/nolog 'p1;*
$!
$! All done
$!
$ if p2.eqs."VERBOSE" then write sys$output "S3UPLOAD.COM: All done"
$!
$ exit

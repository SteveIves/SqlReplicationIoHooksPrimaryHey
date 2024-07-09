$ !
$ HERE = F$PARSE(F$ENVIRONMENT("PROCEDURE"),,,"DEVICE") + F$PARSE(F$ENVIRONMENT("PROCEDURE"),,,"DIRECTORY")
$ SET DEF 'HERE
$ !
$ @SETUP.COM
$ !
$ WRITE SYS$OUTPUT "-------------------------------------------------------------------------------"
$ WRITE SYS$OUTPUT "Loading repository schema..."
$ WRITE SYS$OUTPUT ""
$ !
$ RPSUTL:==$RPS:RPSUTL.EXE
$ !
$ RPSUTL -i [.REPOSITORY]REPLICATION.SCH -ia -ir
$ !
$ WRITE SYS$OUTPUT "-------------------------------------------------------------------------------"
$ WRITE SYS$OUTPUT "Building library routines..."
$ WRITE SYS$OUTPUT ""
$ !
$ DBLPROTO -OUT LIBRARY LIBSRC:*.dbl
$ !
$ DIBOL/OPT/OBJ=OBJ:LIBRARY.OBJ -
   LIBSRC:CommandLineParser.dbl -
 + LIBSRC:CommitTransactionSqlConnection.dbl -
 + LIBSRC:ConfigureEnvironment.dbl -
 + LIBSRC:ConfigureReplication.dbl -
 + LIBSRC:Counters.dbl -
 + LIBSRC:DatabaseCommunicationException.dbl -
 + LIBSRC:DatabaseConnect.dbl -
 + LIBSRC:DatabaseConnection.dbl -
 + LIBSRC:DatabaseDisconnect.dbl -
 + LIBSRC:DatabaseReconnect.dbl -
 + LIBSRC:DatabaseTransform.dbl -
 + LIBSRC:DataConversionTools.dbl -
 + LIBSRC:DepartmentSqlIO.dbl -
 + LIBSRC:EmailSettings.dbl -
 + LIBSRC:EmployeeSqlIO.dbl -
 + LIBSRC:File.dbl -
 + LIBSRC:FileChunkReader.dbl -
 + LIBSRC:FileServiceClient.dbl -
 + LIBSRC:GenerateDepartmentData.dbl -
 + LIBSRC:GenerateEmployeeData.dbl -
 + LIBSRC:GetDateTimeString.dbl -
 + LIBSRC:IndexExists.dbl -
 + LIBSRC:InstanceDefaultSettings.dbl -
 + LIBSRC:InstanceInfo.dbl -
 + LIBSRC:IOHooksISAM.dbl -
 + LIBSRC:IOHooksKAFKA.dbl -
 + LIBSRC:IOHooksRELATIVE.dbl -
 + LIBSRC:IsDate.dbl -
 + LIBSRC:IsDecimal.dbl -
 + LIBSRC:IsEmailAddress.dbl -
 + LIBSRC:IsTime.dbl -
 + LIBSRC:Json.dbl -
 + LIBSRC:KafkaConsumeAPI.dbl -
 + LIBSRC:LastRecordCache.dbl -
 + LIBSRC:Logger.dbl -
 + LIBSRC:MakeDateForCsv.dbl -
 + LIBSRC:MakeDecimalForCsv.dbl -
 + LIBSRC:MakeTimeForCsv.dbl -
 + LIBSRC:OpenOrCreateQueueFile.dbl -
 + LIBSRC:OpenQueueFile.dbl -
 + LIBSRC:PopulateReplicationKey.dbl -
 + LIBSRC:ReOpenQueueFile.dbl -
 + LIBSRC:Replicate.dbl -
 + LIBSRC:ReplicatorShutdown.dbl -
 + LIBSRC:RollbackSqlConnection.dbl -
 + LIBSRC:SendEmail.dbl -
 + LIBSRC:Settings.dbl -
 + LIBSRC:SmtpMail.dbl -
 + LIBSRC:StartTransactionSqlConnection.dbl -
 + LIBSRC:StringDictionary.dbl -
 + LIBSRC:StringTools.dbl -
 + LIBSRC:ThrowOnCommunicationError.dbl -
 + LIBSRC:TimeNow.dbl -
 + LIBSRC:Timer.dbl -
 + LIBSRC:UnloadAgentSettings.dbl -
 + LIBSRC:ValidateBasicEnvironment.dbl
$ !
$ WRITE SYS$OUTPUT "-------------------------------------------------------------------------------"
$ WRITE SYS$OUTPUT "Building object library..."
$ WRITE SYS$OUTPUT ""
$ !
$ LIB/CREATE OBJ:LIBRARY.OLB OBJ:LIBRARY.OBJ
$ DELETE/NOLOG OBJ:library.OBJ;*
$ !
$ ! We can't use a shared image because of the issue with destructors
$ ! so unless we find a solution to that problem we'll use an object library.
$ ! WRITE SYS$OUTPUT "Creating shared image LIBRARY.EXE..."
$ ! MAKESHARE -L OBJ:LIBRARY.OLB -E REPLICATOR_EXE: -Q -SQL -XD
$ ! @LIBRARY.COM
$ !
$ WRITE SYS$OUTPUT "-------------------------------------------------------------------------------"
$ WRITE SYS$OUTPUT "Building ZeroMQ interface..."
$ WRITE SYS$OUTPUT ""
$ !
$ CC /INCLUDE=(ZMQ$ROOT:[INCLUDE]) /NAMES=(AS_IS,SHORTENED) /OBJECT=OBJ: VMSCSRC:DBL_UTILS.C
$ CC /INCLUDE=(ZMQ$ROOT:[INCLUDE]) /NAMES=(AS_IS,SHORTENED) /OBJECT=OBJ: VMSCSRC:MESSAGE_UTILS.C
$ CC /INCLUDE=(ZMQ$ROOT:[INCLUDE]) /NAMES=(AS_IS,SHORTENED) /OBJECT=OBJ: VMSCSRC:PACKET_UTILS.C
$ CC /INCLUDE=(ZMQ$ROOT:[INCLUDE]) /NAMES=(AS_IS,SHORTENED) /OBJECT=OBJ: VMSCSRC:ZMQ_HOOKS.C
$ !
$ LIB/INSERT OBJ:LIBRARY.OLB OBJ:DBL_UTILS.OBJ
$ LIB/INSERT OBJ:LIBRARY.OLB OBJ:MESSAGE_UTILS.OBJ
$ LIB/INSERT OBJ:LIBRARY.OLB OBJ:PACKET_UTILS.OBJ
$ LIB/INSERT OBJ:LIBRARY.OLB OBJ:ZMQ_HOOKS.OBJ
$ !
$ DELETE/NOLOG OBJ:DBL_UTILS.OBJ;*
$ DELETE/NOLOG OBJ:MESSAGE_UTILS.OBJ;*
$ DELETE/NOLOG OBJ:PACKET_UTILS.OBJ;*
$ DELETE/NOLOG OBJ:ZMQ_HOOKS.OBJ;*
$ !
$ WRITE SYS$OUTPUT "-------------------------------------------------------------------------------"
$ WRITE SYS$OUTPUT "Building replicator..."
$ WRITE SYS$OUTPUT ""
$ !
$ DIBOL/OPT/OBJ=OBJ: REPSRC:replicator.dbl
$ LINK/THREADS/EXE=REPLICATOR_EXE:REPLICATOR.EXE OBJ:REPLICATOR.OBJ,[]REPLICATOR.OPT
$ !
$! WRITE SYS$OUTPUT "-------------------------------------------------------------------------------"
$! WRITE SYS$OUTPUT "Building ChangeEveryEmployee..."
$! WRITE SYS$OUTPUT ""
$!
$! DIBOL/OPT/OBJ=OBJ: TOOLSRC:ChangeEveryEmployee.dbl
$! LINK/THREADS/EXE=REPLICATOR_EXE:ChangeEveryEmployee.exe OBJ:ChangeEveryEmployee.obj,[]REPLICATOR/OPT
$ !
$ WRITE SYS$OUTPUT "-------------------------------------------------------------------------------"
$ WRITE SYS$OUTPUT "Building DepartmentMaintenance..."
$ WRITE SYS$OUTPUT ""
$ !
$ DIBOL/OPT/OBJ=OBJ: TOOLSRC:DepartmentMaintenance.dbl
$ LINK/THREADS/EXE=REPLICATOR_EXE:DepartmentMaintenance.exe OBJ:DepartmentMaintenance.obj,[]REPLICATOR/OPT
$ !
$! WRITE SYS$OUTPUT "-------------------------------------------------------------------------------"
$! WRITE SYS$OUTPUT "Building EmployeeDataReport..."
$! WRITE SYS$OUTPUT ""
$!
$! DIBOL/OPT/OBJ=OBJ: TOOLSRC:EmployeeDataReport.dbl
$! LINK/THREADS/EXE=REPLICATOR_EXE:EmployeeDataReport.exe OBJ:EmployeeDataReport.obj,[]REPLICATOR/OPT
$ !
$ WRITE SYS$OUTPUT "-------------------------------------------------------------------------------"
$ WRITE SYS$OUTPUT "Building EmployeeMaintenance..."
$ WRITE SYS$OUTPUT ""
$ !
$ DIBOL/OPT/OBJ=OBJ: TOOLSRC:EmployeeMaintenance.dbl
$ LINK/THREADS/EXE=REPLICATOR_EXE:EmployeeMaintenance.exe OBJ:EmployeeMaintenance.obj,[]REPLICATOR/OPT
$ !
$! WRITE SYS$OUTPUT "-------------------------------------------------------------------------------"
$! WRITE SYS$OUTPUT "Building InstructionCount..."
$! WRITE SYS$OUTPUT ""
$!
$! DIBOL/OPT/OBJ=OBJ: TOOLSRC:InstructionCount.dbl
$! LINK/THREADS/EXE=REPLICATOR_EXE:InstructionCount.exe OBJ:InstructionCount.obj,[]REPLICATOR/OPT
$ !
$! WRITE SYS$OUTPUT "-------------------------------------------------------------------------------"
$! WRITE SYS$OUTPUT "Building QueueMonitor..."
$! WRITE SYS$OUTPUT ""
$!
$! DIBOL/OPT/OBJ=OBJ: TOOLSRC:QueueMonitor.dbl
$! LINK/THREADS/EXE=REPLICATOR_EXE:QueueMonitor.exe OBJ:QueueMonitor.obj,[]REPLICATOR/OPT
$ !
$ WRITE SYS$OUTPUT "-------------------------------------------------------------------------------"
$ WRITE SYS$OUTPUT "Building ReplicatorMenu..."
$ WRITE SYS$OUTPUT ""
$ !
$ DIBOL/OPT/OBJ=OBJ: TOOLSRC:ReplicatorMenu.dbl
$ LINK/THREADS/EXE=REPLICATOR_EXE:ReplicatorMenu.exe OBJ:ReplicatorMenu.obj,[]REPLICATOR/OPT
$ !
$! WRITE SYS$OUTPUT "-------------------------------------------------------------------------------"
$! WRITE SYS$OUTPUT "Building ReplicatorStop..."
$! WRITE SYS$OUTPUT ""
$!
$! DIBOL/OPT/OBJ=OBJ: TOOLSRC:ReplicatorStop.dbl
$! LINK/THREADS/EXE=REPLICATOR_EXE:ReplicatorStop.exe OBJ:ReplicatorStop.obj,[]REPLICATOR/OPT
$ !
$ WRITE SYS$OUTPUT "-------------------------------------------------------------------------------"
$ WRITE SYS$OUTPUT "Building UnloadAgent..."
$ WRITE SYS$OUTPUT ""
$ !
$ DIBOL/OPT/OBJ=OBJ: TOOLSRC:UnloadAgent.dbl
$ LINK/THREADS/EXE=REPLICATOR_EXE:UnloadAgent.exe OBJ:UnloadAgent.obj,[]REPLICATOR/OPT
$ !
$ !------------------------------------------------------------------------------------
$ !
$ PURGE/NOCONFIRM/NOLOG [...]
$ !
$ EXIT

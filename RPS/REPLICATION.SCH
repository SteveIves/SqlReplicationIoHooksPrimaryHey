 
;  SYNERGY DATA LANGUAGE OUTPUT
;
;  REPOSITORY     : C:\DEV_SYNERGEX\SqlReplication\RPS\rpsmain.ism
;                 : C:\DEV_SYNERGEX\SqlReplication\RPS\rpstext.ism
;                 : Version 12.2.1
;
;  GENERATED      : 07-MAR-2024, 14:42:22
;                 : Version 12.2.1
;  EXPORT OPTIONS : [ALL] 
 
 
Format PHONE   Type NUMERIC   "(XXX) XXX-XXXX"   Justify LEFT
 
Enumeration REPLICATION_INSTRUCTION
   Description "SQL Replication Instruction"
   Members CREATE_ROW 1, UPDATE_ROW 2, DELETE_ROW 3, CREATE_TABLE 4,
          LOAD_TABLE 5, CREATE_AND_LOAD_TABLE 6, DELETE_ALL_ROWS 7,
          DELETE_TABLE 8, SHUTDOWN 9, INSERT_RELATIVE 10,
          UPDATE_RELATIVE 11, ADD_INDEXES 12, DELETE_INDEXES 13,
          BULK_LOAD_TABLE 14, BULK_LOAD_FIRST_1000,
          DELETE_ALL_INSTRUCTIONS 20, CLOSE_FILE 21, CHANGE_INTERVAL 22,
          CREATE_CSV 23, CYCLE_LOG 24, OPEN_FILE 25,
          DELETE_FIRST_INSTRUCTION 26
 
Template DEPARTMENT_ID   Type ALPHA   Size 15
   Description "Department ID"
   Prompt "Department"
   Uppercase
   Required
   Drill Method "department_drill"   Change Method "department_change"
 
Template DEPARTMENT_NAME   Type ALPHA   Size 50
   Description "Department name"
   Required
 
Template EMPLOYEE_ID   Type DECIMAL   Size 8
   Description "Employee ID"
   Prompt "Employee ID"
   Required
 
Template PERSON_FIRST_NAME   Type ALPHA   Size 20
   Description "First name"
   Prompt "First name"
   Required
 
Template PERSON_LAST_NAME   Type ALPHA   Size 20
   Description "Last name"
   Prompt "Last name"
   Required
 
Template PHONE_NUMBER   Type DECIMAL   Size 10
   Description "Phone Number"
   Prompt "Phone"   Info Line "Enter a telephone number"   Format PHONE
   Report Just LEFT   Input Just LEFT   Blankifzero
 
Structure DEPARTMENT   DBL ISAM
   Description "Department Master File"
 
Field DEPT_ID   Template DEPARTMENT_ID
   Prompt "Department"
 
Field DEPT_NAME   Template DEPARTMENT_NAME   Dimension 1
   Prompt "Description"   User Text "@CODEGEN_DISPLAY_FIELD"
 
Field DEPT_MANAGER   Template EMPLOYEE_ID
   Description "Department manager"
   Prompt "Manager"
 
Field MONAME_001   Type ALPHA   Size 27   Language Noview   Script Noview
   Report Noview   Nonamelink
   Description "Spare space"
 
Key DEPT_ID   ACCESS   Order ASCENDING   Dups NO
   Description "Department ID"
   Segment FIELD   DEPT_ID
 
Key DEPT_MANAGER   ACCESS   Order ASCENDING   Dups YES   Insert END
   Modifiable YES   Krf 001
   Description "Department manager"
   Segment FIELD   DEPT_MANAGER  SegType ALPHA
 
Structure EMPLOYEE   DBL ISAM
   Description "Employee Master File"
 
Field EMP_ID   Template EMPLOYEE_ID
   Info Line "Enter an employee ID"   ODBC Name EMPLOYEE_ID
 
Field EMP_FIRST_NAME   Template PERSON_FIRST_NAME
   Prompt "First name"   Info Line "Enter the employees first name"
   ODBC Name FIRST_NAME
   Required
 
Field EMP_LAST_NAME   Template PERSON_LAST_NAME
   Info Line "Enter the employees last name"
   User Text "@CODEGEN_DISPLAY_FIELD"   ODBC Name LAST_NAME
 
Field EMP_DEPT   Template DEPARTMENT_ID
   Description "Employee's department ID"
   Info Line "Enter a department ID"   ODBC Name DEPARTMENT_ID   Nodisabled
 
Field EMP_HIRE_DATE   Type DATE   Size 8   Stored YYYYMMDD
   Coerced Type NULLABLE_DATETIME
   Description "Date hired"
   Prompt "Hire Date"   Info Line "Enter the employees date of hire"
   ODBC Name HIRE_DATE
   Date Today
 
Field EMP_PHONE_WORK   Type ALPHA   Size 14
   Description "Work phone number"
   Prompt "Work phone"   ODBC Name WORK_PHONE
 
Field EMP_PHONE_HOME   Type ALPHA   Size 14
   Description "Home phone number"
   Long Description
      "REPLICATOR_EXCLUDE"
   Prompt "Home phone"   ODBC Name HOME_PHONE
 
Field EMP_PHONE_CELL   Type ALPHA   Size 14
   Description "Cell phone number"
   Prompt "Cell phone"   ODBC Name CELL_PHONE
 
Field EMP_PAID   Type DECIMAL   Size 1
   Description "Employee pay method"
   Prompt "Paid"   Info Line "Is the employee paid hourly or salaried"
   ODBC Name PAY_FREQUENCY
   Default "1"   Automatic
   Selection List 0 0 0  Entries "Hourly", "Salaried"
   Enumerated 8 1 1
 
Field EMP_HOME_OK   Type DECIMAL   Size 1
   Description "OK to call at home"
   Long Description
      "REPLICATOR_EXCLUDE"
   Prompt "Call home OK"   Info Line "Is it OK to call this employee at home"
   ODBC Name OK_TO_CALL_HOME   Checkbox
   Default "1"   Automatic
 
Field EMP_DATE_OF_BIRTH   Type DATE   Size 8   Stored YYYYMMDD
   Coerced Type NULLABLE_DATETIME
   Description "Date of birth"
   Prompt "Date of birth"   Info Line "Enter the employees date of birth"
   ODBC Name DATE_OF_BIRTH
 
Field EMP_HIRE_TIME   Type TIME   Size 4   Stored HHMM
   Description "Hire time"
   Prompt "Hire time"   Info Line "Enter the time the employee was hired"
   ODBC Name HIRE_TIME
   Time Now
 
Field EMP_EMAIL   Type ALPHA   Size 40
   Description "Email address"
   Prompt "Email"   ODBC Name EMAIL_ADDRESS
 
Field EMP_ADDRESS_STREET   Type ALPHA   Size 30
   Description "Street address"
   Prompt "Address"   Info Line "What is the employees street address?"
   ODBC Name STREET_ADDRESS
 
Field EMP_ADDRESS_CITY   Type ALPHA   Size 20
   Description "City"
   Prompt "City"   Info Line "What city does the employee live in?"
   ODBC Name CITY
 
Field EMP_ADDRESS_STATE   Type ALPHA   Size 2
   Description "State"
   Prompt "State"   User Text "Which state does the employee live in?"
   ODBC Name STATE
   Uppercase
 
Field EMP_ADDRESS_ZIP   Type DECIMAL   Size 5
   Description "Zip code"
   Prompt "Zip code"   Info Line "What is the employees home ZIP code?"
   ODBC Name ZIP_CODE
 
Field NONAME_001   Type ALPHA   Size 76   Language Noview   Script Noview
   Report Noview   Nonamelink
   Description "Spare space"
   ODBC Name SPARE_SPACE_1
 
Key EMP_ID   ACCESS   Order ASCENDING   Dups NO
   Segment FIELD   EMP_ID  SegType ALPHA
 
Key EMP_DEPT   ACCESS   Order ASCENDING   Dups YES   Insert END
   Modifiable YES   Krf 001
   Description "Department ID"
   Segment FIELD   EMP_DEPT
 
Key EMP_LAST_NAME   ACCESS   Order ASCENDING   Dups YES   Insert END
   Modifiable YES   Krf 002
   Description "Last name"
   Segment FIELD   EMP_LAST_NAME  SegType NOCASE  SegOrder ASCENDING
 
Key STATE_CODE   ACCESS   Order ASCENDING   Dups YES   Insert END
   Modifiable YES   Krf 003
   Description "State"
   Segment FIELD   EMP_ADDRESS_STATE  SegType ALPHA  SegOrder ASCENDING
 
Key ZIP_CODE   ACCESS   Order ASCENDING   Dups YES   Insert END
   Modifiable YES   Krf 004
   Description "Zip code"
   Segment FIELD   EMP_ADDRESS_ZIP  SegType ALPHA  SegOrder ASCENDING
 
Structure RELSTR   RELATIVE
   Description "Relative structure"
 
Field FIELD1   Type ALPHA   Size 1
   Description "Field 1"
 
Field FIELD2   Type DECIMAL   Size 2
   Description "Field 2"
 
Field FIELD3   Type DATE   Size 8   Stored YYYYMMDD
   Description "Field 3"
 
Field FIELD4   Type TIME   Size 6   Stored HHMMSS
   Description "Field 4"
 
Key RECORD_NUMBER   ACCESS   Order ASCENDING   Dups NO
   Segment RECORD NUMBER
 
Structure REPLICATION   DBL ISAM
   Description "Replication request queue"
 
Field TRANSACTION_ID   Type AUTOSEQ   Size 8
   Description "Unique transaction ID (I8 timestamp)"
   Report Just LEFT   Input Just LEFT   Readonly
   Nonull
 
Field ACTION   Type DECIMAL   Size 2
   Description "Replicator action"
   Negative
 
Field STRUCTURE_NAME   Type ALPHA   Size 32
   Description "the SDMS structure name"
 
Field RECORD   Type ALPHA   Size 65000
   Description "Record affected"
 
Key TRANSACTION_ID   ACCESS   Order ASCENDING   Dups NO   Density 100
   Description "Transaction ID (I8 timestamp)"
   Segment FIELD   TRANSACTION_ID  SegType SEQUENCE
 
Structure REPLICATION_VMS   DBL ISAM
   Description "Replication request queue (OpenVMS)"
 
Field TRANSACTION_ID   Type ALPHA   Size 20
   Description "Unique transaction ID (timestamp)"
   Readonly
   Nonull
 
Field ACTION   Type DECIMAL   Size 2
   Description "Replicator action"
   Negative
 
Field STRUCTURE_NAME   Type ALPHA   Size 32
   Description "the SDMS structure name"
 
Field RECORD   Type ALPHA   Size 32000
   Description "Record affected"
 
Key TRANSACTION_ID   ACCESS   Order ASCENDING   Dups NO   Density 100
   Description "Transaction ID (timestamp)"
   Segment FIELD   TRANSACTION_ID  SegType ALPHA  SegOrder ASCENDING
 
File DEPARTMENT   DBL ISAM   "REPLICATOR_DATA:DEPARTMENT.ISM"
   Description "Department master file"
   Compress
   Assign DEPARTMENT
 
File EMPLOYEE   DBL ISAM   "REPLICATOR_DATA:EMPLOYEE.ISM"
   Description "Employee master file"
   Compress
   Assign EMPLOYEE
 
File RELFILE   RELATIVE   "REPLICATOR_DATA:RELFILE.DDF"
   Description "Relative file"
   Assign RELSTR
 
File REPLICATION   DBL ISAM   "REPLICATOR_DATA:REPLICATION.ISM"
   Description "SQL replication request queue file"
   Addressing 40BIT   Compress   Terabyte
   Assign REPLICATION
 
File REPLICATION_VMS   DBL ISAM   "REPLICATOR_DATA:REPLICATION.ISM"
   Description "SQL replication request queue file (VMS)"
   Addressing 40BIT
   Assign REPLICATION_VMS
 

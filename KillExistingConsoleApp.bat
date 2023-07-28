REM KillExistingConsoleApp.bat
REM This batch script kills a running instance of a console application specified by the user. 
REM The script uses the "taskkill" command to forcefully terminate the process. 
REM This script can be used to ensure that the console application is not running before starting a new instance of it. 

REM To use this script, the user must replace "<your-process>" with the name of the console application they want to kill. 
REM The script can be run from the command prompt or as a scheduled task.

REM The following line of code kills the specified console application:

taskkill /f /im "<your-process>.exe"
@ECHO OFF

REM ===========================================================
REM 20210316
REM ===========================================================

REM This script executes a queue of tasks in parallel.

REM Show help:
REM ```
REM taskq.cmd
REM taskq.cmd /?
REM ```

REM This script starts a number of tasks in parallel.
REM The number of running tasks are stored in a shared `counter`.
REM The shared `counter` is incremented each time a task is started,
REM and decremented each time after a task has finished.

REM The shared `counter` is accessed by several processes.
REM The shared `counter` is implemented by a shared batch file that looks like:
REM ``` SET Cnt = n ```
REM The shared `counter` can be retrieved by calling the batch file.
REM And the shared `counter` can be updated by overwriting the batch file.

REM A `lock` is used guard the access to shared batch file.
REM One method is to use a `lock` file:
REM https://www.dostips.com/forum/viewtopic.php?t=2729.
REM However, this method makes the script harder to debug,
REM since the messages are redirected and written into the lock file.
REM This script uses the traditional directory-based lock.
REM It is more disk-friendly, since no data has to be written.

REM This script does the following:
REM * For each task.
REM   * Acquire lock.
REM   * Read the shared counter, and its value is stored locally.
REM     * Increment the local counter.
REM     * If the incremented local counter is not above the threshold
REM       * Update the shared counter to the incremented local value.
REM     * Release lock.
REM   * If the incremented local counter is not above the threshold
REM     * Start the task.
REM   * Else
REM     * Wait for some time.
REM     * Try again.
REM * Wait for all tasks to finish.

REM To run a task, the script does the following:
REM * Start and wait for the task to finish.
REM * Acquire lock.
REM   * Read the shared counter, and its value is stored locally.
REM   * Decrement the local counter.
REM   * Update the shared counter to the decremented local value.
REM * Release lock.

REM * queue.txt
REM   Each line is a task to run.
REM * cnt.cmd
REM   The counter is shared among several processes.
REM   The script stores the counter:
REM   `SET cnt=n`
REM   A process can read the counter by invoking the script.
REM   A process can modify the script to set a new counter.
REM * run-task.cmd
REM   The script to run task.


REM The filename of this script.
SET __TASKQ_SCRIPT__=%~nx0

REM Show help message if necessary.
IF [%1] EQU [] (
  GOTO :ShowHelp
) ELSE IF [%1] EQU [/?] (
  GOTO :ShowHelp
)

REM ============================================================================
REM When this script is called to run a task.
REM This usage is used internally.
IF [%1] EQU [__TASK__] (
  GOTO :RunTaskSection
)

REM ============================================================================
REM When this script is called to run a task queue.
REM The current number of tasks.
SET __TASKQ_CNT__=0
REM The maximum number of tasks in parallel.
SET __TASKQ_CNT_MAX__=1
REM The detection interval in seconds.
SET __TASKQ_DT__=1
REM A random number to prevent naming collision.
SET __TASKQ_ID__=%RANDOM%
REM The name of the lock directory.
SET __TASKQ_LOCK__=lock%__TASKQ_ID__%
REM The name of the shared counter batch file.
SET __TASKQ_CNT_FILE__=taskq%__TASKQ_ID__%.cmd
REM The index of task.
SET __TASKQ_INDEX__=0
REM The switch to close task console when the task has finished.
SET __TASKQ_NOCLOSE__=

:ParseArgs
IF /I [%1] EQU [-j] (
  IF [%2] EQU [] (
    GOTO :ShowHelp
  )
  SET __TASKQ_CNT_MAX__=%2
  SHIFT
  SHIFT
)
IF /I [%1] EQU [-i] (
  IF [%2] EQU [] (
    GOTO :ShowHelp
  )
  SET __TASKQ_DT__=%2
  SHIFT
  SHIFT
)
IF /I [%1] EQU [-k] (
  SET __TASKQ_NOCLOSE__=-k
  SHIFT
)
REM Positional argument.
IF [%1] NEQ [] (
  SET __TASKQ_QFILE__=%1
  SHIFT
)
IF [%1] NEQ [] (
  GOTO :ParseArgs
)

CALL :RunQueue

SET __TASKQ_CNT__=
SET __TASKQ_CNT_MAX__=
SET __TASKQ_DT__=
SET __TASKQ_ID__=
SET __TASKQ_LOCK__=
SET __TASKQ_CNT_FILE__=
SET __TASKQ_QFILE__=
SET __TASKQ_INDEX__=
SET __TASKQ_NOCLOSE__=
EXIT /B


REM ============================================================================
:RunTaskSection
REM The taskq id.
SET __TASKQ_ID__=%2
REM The name of the lock directory.
SET __TASKQ_LOCK__=lock%__TASKQ_ID__%
REM The name of the shared counter batch file.
SET __TASKQ_CNT_FILE__=taskq%__TASKQ_ID__%.cmd
REM The switch to close task console when the task has finished.
SET __TASKQ_NOCLOSE__=
REM The number of arguments to skip.
SET __TASKQ_ARGS_SHIFT__=0
REM The command line of the task.
SET __TASKQ_TASK_ARGS__=

SET /A __TASKQ_ARGS_SHIFT__+=2
SHIFT
SHIFT
IF /I [%1] EQU [-k] (
  SET __TASKQ_NOCLOSE__=-k
  SET /A __TASKQ_ARGS_SHIFT__+=1
  SHIFT
)
CALL :ShiftArgs __TASKQ_TASK_ARGS__ %%__TASKQ_ARGS_SHIFT__%% %*
CALL :RunTask
CALL :RunTaskExit %%__TASKQ_NOCLOSE__%%
EXIT /B

REM @param[in] %1 Do not close console?
:RunTaskExit
SET __TASKQ_ID__=
SET __TASKQ_LOCK__=
SET __TASKQ_CNT_FILE__=
SET __TASKQ_NOCLOSE__=
SET __TASKQ_ARGS_SHIFT__=
SET __TASKQ_TASK_ARGS__=

IF [%1] NEQ [] EXIT /B
EXIT

REM ========= ShowHelp =========
REM @param[in] %1
:ShowHelp
ECHO Usage:
ECHO   %__TASKQ_SCRIPT__% [-j ^<n^>] [-i ^<t^>] [-k] ^<queue^>
ECHO   -j ^<n^> : ^<n^> is the maximum number of tasks in parallel.
ECHO            ^<n^> is 1 by default.
ECHO   -i ^<t^> : ^<t^> is the interval of detection.
ECHO            ^<t^> is 1 second by default.
ECHO   -k     : Keep console from being closed after the task has finished.
ECHO   ^<queue^>: A text file that specifies tasks.
ECHO            Each line is the command line of a task.
ECHO            The lines start with semicolon ';' are ignored.
EXIT /B

REM ========= RunQueue =========
:RunQueue
IF %__TASKQ_CNT_MAX__% EQU 0 (
  ECHO Invalid maximum number of tasks: %__TASKQ_CNT_MAX__%
  GOTO :ShowHelp
)
IF %__TASKQ_DT__% EQU 0 (
  ECHO Invalid interval of detection: %__TASKQ_CNT_MAX__%
  GOTO :ShowHelp
)
IF NOT DEFINED __TASKQ_QFILE__ (
  ECHO Task queue file is not specified.
  GOTO :ShowHelp
)
IF NOT EXIST "%__TASKQ_QFILE__%" (
  ECHO Task queue file does not exists: %__TASKQ_QFILE__%
  GOTO :ShowHelp
)
REM Initially, the counter is 0.
>%__TASKQ_CNT_FILE__% ( ECHO SET __TASKQ_CNT__=0 )
FOR /F "eol=; delims=" %%d IN (%__TASKQ_QFILE__%) DO (
  SET /A __TASKQ_INDEX__+=1
  CALL :TryTask %%d
)
CALL :FinQueue
ECHO Done.
EXIT /B

REM ========= FinQueue =========
REM Wait for all tasks to finish, then delete counter file.
:FinQueue
CALL :AcquireLock
REM Read counter.
CALL %__TASKQ_CNT_FILE__%
CALL :ReleaseLock
REM Check counter.
CALL :CounterIsZero
REM If counter is above 0.
IF ERRORLEVEL 1 (
  REM Wait for some time.
  TIMEOUT /T %__TASKQ_DT__% >NUL
  GOTO :FinQueue
)
REM Delete counter.
DEL %__TASKQ_CNT_FILE__%
EXIT /B

REM ========= TryTask =========
REM @param[in] %1.. Task command.
:TryTask
CALL :AcquireLock
REM Read counter.
CALL %__TASKQ_CNT_FILE__%
REM Increment counter, write counter if feasible.
CALL :IncrementCounter
CALL :ReleaseLock
REM Check counter.
CALL :CounterAvailable
REM If incremented counter exceeds threshold.
IF ERRORLEVEL 1 (
  REM Wait for some time.
  TIMEOUT /T %__TASKQ_DT__% >NUL
  GOTO :TryTask
)
ECHO %__TASKQ_INDEX__%: %*
REM __TASK__ <Id> [-k] <task command line>
START %__TASKQ_SCRIPT__% __TASK__ %__TASKQ_ID__% %__TASKQ_NOCLOSE__% %*
EXIT /B

REM ========= RunTask =========
:RunTask
ECHO %__TASKQ_TASK_ARGS__%
CMD /C %__TASKQ_TASK_ARGS__%
CALL :AcquireLock
REM Read counter.
CALL %__TASKQ_CNT_FILE__%
REM Decrement counter, write counter if feasible.
CALL :DecrementCounter
CALL :ReleaseLock
EXIT /B

REM ========= IncrementCounter =========
REM @pre Lock acquired.
:IncrementCounter
REM Increment counter.
IF %__TASKQ_CNT__% LSS %__TASKQ_CNT_MAX__% (
  SET /A __TASKQ_CNT__+=1
  CALL :WriteCounter
) ELSE (
  REM Let counter above threshold.
  SET /A __TASKQ_CNT__+=1
)
EXIT /B

REM ========= DecrementCounter =========
REM @pre Lock acquired.
:DecrementCounter
REM Decrement counter.
IF %__TASKQ_CNT__% GTR 0 (
  SET /A __TASKQ_CNT__-=1
  CALL :WriteCounter
)
EXIT /B

REM ========= WriteCounter =========
REM @pre Lock acquired.
:WriteCounter
>%__TASKQ_CNT_FILE__% ( ECHO SET __TASKQ_CNT__=%__TASKQ_CNT__% )
EXIT /B

REM ========= CounterAvailable =========
:CounterAvailable
IF %__TASKQ_CNT__% LEQ %__TASKQ_CNT_MAX__% ( EXIT /B 0 )
EXIT /B 1

REM ========= CounterIsZero =========
:CounterIsZero
IF %__TASKQ_CNT__% EQU 0 ( EXIT /B 0 )
EXIT /B 1

REM ============================================================================
REM ========= AcquireLock =========
:AcquireLock
2>NUL MKDIR %__TASKQ_LOCK__%
IF ERRORLEVEL 1 (
  TIMEOUT /T %__TASKQ_DT__% >NUL
  GOTO :AcquireLock
)
EXIT /B

REM ========= ReleaseLock =========
:ReleaseLock
RMDIR %__TASKQ_LOCK__%
EXIT /B

REM ============================================================================
REM ========= ShiftArgs =========
REM @param[in] %1   The name variable to store the shifted arguments.
REM @param[in] %2   The number of arguments to shift.
REM @param[in] %3.. The arguments to shift.
REM @see https://stackoverflow.com/questions/935609/batch-parameters-everything-after-1
REM @see https://stackoverflow.com/questions/761615/is-there-a-way-to-indicate-the-last-n-parameters-in-a-batch-file/761658
:ShiftArgs
SET __SHIFT_ARGS_NAME__=%1
SET __SHIFT_ARGS_COUNT__=%2
SHIFT
SHIFT
REM Skip specified number of arguments.
:ShiftArgsSkip
CALL :ShiftArgsDecrementCount
IF ERRORLEVEL 1 (
  SHIFT
  GOTO :ShiftArgsSkip
)
SET __SHIFT_ARGS_VALUE__=%1
SHIFT
REM Append the remaining arguments.
:ShiftArgsLoop
IF [%1] NEQ [] (
  CALL :ShiftArgsAppendValue %1
  SHIFT
  GOTO :ShiftArgsLoop
)
REM Store the shifted arguments in the specified variable.
CALL :ShiftArgsStoreValue %__SHIFT_ARGS_NAME__%
REM Clean up.
SET __SHIFT_ARGS_NAME__=
SET __SHIFT_ARGS_COUNT__=
SET __SHIFT_ARGS_VALUE__=
EXIT /B

:ShiftArgsDecrementCount
IF %__SHIFT_ARGS_COUNT__% GTR 0 (
  SET /A __SHIFT_ARGS_COUNT__-=1
  EXIT /B 1
)
EXIT /B 0

:ShiftArgsAppendValue
SET __SHIFT_ARGS_VALUE__=%__SHIFT_ARGS_VALUE__% %1
EXIT /B

:ShiftArgsStoreValue
SET %1=%__SHIFT_ARGS_VALUE__%
EXIT /B

REM ============================================================================
REM ========= UniformInt =========
REM @brief Generate a random timeout within [lb, ub]
REM @param[out] %1 The variable name.
REM @param[in]  %2 The lower bound (lb).
REM @param[in]  %3 The upper bound (ub).
REM %RANDOM% ~ U[0, 32767].
:UniformInt
SET /A %1=%RANDOM% * (%3 - %2 + 1) / 32768 + %2
EXIT /B


A set of batch scripts for development under Windows
====================================================

sudow.cmd : `sudo` for Windows.
-------------------------------

Run application with Administrative privileges.

* Start a console with Administrative privileges.

  ```batch
  sudow
  ```

* Run application with Administrative privileges.

  ```batch
  sudow myapp.exe -t 0 -n 10
  ```

MakeLink.cmd : make links.
--------------------------

`gpedit.msc` shall be used to grand the user the privilege to create links.

If the link exists, the link is removed first, then a new link is created.

* Make symbolic link
  ```batch
  CALL MakeLink :MakeSymboliclink  "path-of-sym-link"  "path-to-target-file"
  ```

* Make hard link
  ```batch
  CALL MakeLink :MakeHardlink  "path-of-hard-link"  "path-to-target-file"
  ```

* Make junction
  ```batch
  CALL MakeLink :MakeJunction  "path-of-junction"  "path-to-target-directory"
  ```

add-path.ps1 : append path to the `PATH` environment variable.
--------------------------------------------------------------

* Add the current directory to the user's `PATH`

  ```batch
  add-path.ps1
  ```

* Add the current directory to the system `PATH`

  ```batch
  add-path.ps1 -sys
  ```

wtd : start Windows Terminal in a given directory.
--------------------------------------------------

1. Install (Windows Terminal)[https://github.com/microsoft/terminal].

2. Build `wtd.c` to `wtd.exe`.

3. Added the path to `wtd.exe` into the `PATH` environment variable.

* Start Windows Terminal in the current directory

  In the Windows explorer, press `Alt-d`, input `wtd`, then `Enter`.

SetVcEnv.cmd : setup environment for Visual Studio tool chain.
--------------------------------------------------------------

* Use the latest version of Visual Studio.

  ```batch
  SetVcEnv
  ```

* Use specific version of Visual Studio.

  ```batch
  SetVcEnv 16 x86
  ```

* Show help

  ```batch
  SetVcEnv /?
  ```

* Provided environment variables

  ```batch
  VC_VER_FULL     e.g., 193431935
  VC_VER_STD      e.g., 1934
  VC_VER_MAJOR    e.g., 19
  VC_VER_MINOR    e.g.,   34
  VC_VER_BUILD    e.g.,     31935
  VC_VER_STRING   e.g., 19.34.31935
  
  OS_CAPTION      e.g., Microsoft Windows 10
  OS_ARCH         e.g., 64-bit
  OS_VER          e.g., 10.0.19045
  OS_BUILD        e.g., 19045
  ```

Envvar.cmd: manipulate environment variables.
---------------------------------------------

### Mechanisms

See [higher-level function invocation for Windows batch script](https://github.com/Fuzzier/Envvar).

### Value functions

* ValueEcho

  Echo a value.

* ValueEq

  Test the equality of two values.
  ```batch
  SET A=xxx
  SET B=xxx
  CALL Envvar :ValueEq  "%%A%%"  "%%B%%"
  ```
  Then `ERRORLEVEL` becomes `1`.

* ValueFind

  Find a substring in a value.

* ValueTokenize

  Tokenize a value, and process each token.

### Envvar functions

* EnvvarEcho

  Echo the value of an environment variable.

* EnvvarIs

  Check the value of an environment variable.
  ```batch
  SET A=xxx
  SET B=xxx
  CALL Envvar :EnvvarIs  "B"  "%%A%%"
  ```
  Then `ERRORLEVEL` becomes `1`.

* EnvvarFind

  Find a substring in an environment variable.

* EnvvarClear

  Undefine an environment variable.

* EnvvarSet

  Set the value of an environment variable.
  ```batch
  SET A=0123
  CALL Envvar :EnvvarSet  "B"  "%%A:~0,-1%%"
  ```
  Then the value of `B` becomes `012`.

* EnvvarCopy

  Set the value of an environment variable to another.
  ```batch
  SET A=xxx
  CALL Envvar :EnvvarCopy  "A"  "B"
  ```
  Then the value of `B` becomes `xxx`.

* EnvvarPrepend

  Prepend a string to the value of an environment variable.

* EnvvarAppend

  Append a string to the value of an environment variable.

* EnvvarTokenize

  Tokenize an environment variable, and process each token.

* EnvvarPathPrepend

  Prepend a path to an environment variable.
  ```batch
  SET INCLUDE=C:\MyLib\include
  CALL Envvar :EnvvarPathPrepend  "INCLUDE"  "C:\Lua-5.4\include"
  ```
  Then the value of `INCLUDE` becomes `C:\Lua-5.4\include;C:\MyLib\include`.

* EnvvarPathAppend

  Append a path to an environment variable.
  ```batch
  SET INCLUDE=C:\Lua-5.4\include;C:\MyLib\include
  CALL Envvar :EnvvarPathAppend  "INCLUDE"  "C:\Python-3.11\include"
  ```
  Then the value of `INCLUDE` becomes `C:\Lua-5.4\include;C:\MyLib\include;C:\Python-3.11\include`.

* EnvvarPathRemove

  Remove a path from an environment variable.
  ```batch
  SET INCLUDE=C:\Lua-5.4\include;C:\MyLib\include;C:\Python-3.11\include
  CALL Envvar :EnvvarPathRemove  "INCLUDE"  "C:\MyLib\include"
  ```
  Then the value of `INCLUDE` becomes `C:\Lua-5.4\include;C:\Python-3.11\include`.

* EnvvarPathWin

  Use Windows path separator (a.k.a. backslash).<br/>
  The trailing backslash is also removed.

  ```batch
  CALL Envvar :EnvvarPathWin  "PUB"  "C:/pub/bin/"
  ```
  Then the value of `PUB` becomes ```C:\pub\bin```.

* EnvvarPathNix

  Use Unix/Linux path separator (a.k.a. slash).<br/>
  The trailing slash is also removed.

  ```batch
  CALL Envvar :EnvvarPathNix  "PUB"  "C:\pub\bin\"
  ```
  Then the value of `PUB` becomes ```C:/pub/bin```.


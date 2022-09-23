#define UNICODE
#define _UNICODE

#include <windows.h>
#include <stdio.h>
#include <tchar.h>

#pragma comment(lib, "advapi32")  // RegXxx()

int main(void)
{
    DWORD retval = 0;
    LPTSTR cmdline = NULL;
    HKEY hkey = NULL;
    LPTSTR app = NULL;
    do // while (false)
    {
        ////////////////////
        // The current directory.
        DWORD n = GetCurrentDirectory(0, NULL);
        if (n == 0)
        {
            retval = GetLastError();
            _ftprintf(stderr, _T("Cannot get length of current directory 0x%08lx.\n"), retval);
            break;
        }
        n += 50; // Allocate extra characters.
        cmdline = (LPTSTR)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, n * sizeof(TCHAR));
        if (cmdline == NULL)
        {
            retval = GetLastError();
            _ftprintf(stderr, _T("Cannot allocate heap memory 0x%08lx.\n"), retval);
            break;
        }
        // " -d <directory>"
        LPTSTR p = cmdline;
        *p++ = ' '; // Need one more space, or "wt.exe" would compliant that it cannot launch the path.
        *p++ = '-';
        *p++ = 'd';
        *p++ = ' ';
        *p++ = '"';
        n = GetCurrentDirectory(n, p);
        if (n == 0)
        {
            retval = GetLastError();
            _ftprintf(stderr, _T("Cannot get current directory 0x%08lx.\n"), retval);
            break;
        }
        p += n;
        // Remove the trailing backslash, if any.
        if (*(p - 1) == '\\')
        {
            --p;
        }
        *p++ = '"';
        *p++ = '\0';
        ////////////////////
        // Query registry for "wt.exe".
        retval = RegOpenKeyEx(HKEY_CURRENT_USER,
                              _T("Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\wt.exe"),
                              0, // Options
                              KEY_QUERY_VALUE,
                              &hkey);
        if (retval != ERROR_SUCCESS)
        {
            retval = GetLastError();
            _ftprintf(stderr, _T("Cannot open registry '%s', 0x%08lx.\n"),
                      _T("HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\wt.exe"),
                      retval);
            break;
        }
        LONG length = 0;
        retval = RegQueryValue(hkey, NULL, NULL, &length);
        if (retval != ERROR_SUCCESS)
        {
            break;
        }
        app = HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, length);
        if (app == NULL)
        {
            retval = GetLastError();
            _ftprintf(stderr, _T("Cannot allocate heap memory 0x%08lx.\n"), retval);
            break;
        }
        retval = RegQueryValue(hkey, NULL, app, &length);
        if (retval != ERROR_SUCCESS)
        {
            break;
        }
        ////////////////////
        // Output diagnostic information.
#if !defined(NDEBUG)
        _ftprintf(stdout, _T("%s %s\n"), app, cmdline);
#endif // !defined(NDEBUG)
        ////////////////////
        // Run Windows Terminmal.
        STARTUPINFO startupInfo;
        memset(&startupInfo, 0, sizeof(startupInfo));
        startupInfo.cb = sizeof(STARTUPINFO);
        PROCESS_INFORMATION processInfo;
        memset(&processInfo, 0, sizeof(processInfo));
        n = CreateProcess(app,           // Application
                          cmdline,       // Command line arguments
                          NULL,          // Process attributes
                          NULL,          // Thread attributes
                          FALSE,         // Inherit handles
                          0,             // Flags
                          NULL,          // Environment
                          NULL,          // Current directory
                          &startupInfo,  // Startup info
                          &processInfo); // Process info
        if (n == 0)
        {
            retval = GetLastError();
            _ftprintf(stderr, _T("Cannot create process 0x%08lx.\n"), retval);
            break;
        }
        CloseHandle(processInfo.hThread);
        CloseHandle(processInfo.hProcess);
    }
    while (0);
    HeapFree(GetProcessHeap(), 0, cmdline);
    RegCloseKey(hkey);
    HeapFree(GetProcessHeap(), 0, app);
    return retval;
}

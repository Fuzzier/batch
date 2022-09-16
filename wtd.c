#define UNICODE
#define _UNICODE

#include <windows.h>
#include <stdio.h>
#include <tchar.h>

int main(void)
{
    DWORD n = GetCurrentDirectory(0, NULL);
    if (n == 0)
    {
        n = GetLastError();
        _ftprintf(stderr, _T("Cannot get length of current directory 0x%08lx.\n"), n);
        return n;
    }
    n += 50;
    LPTSTR buf = (LPTSTR)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, n * sizeof(TCHAR));
    if (buf == NULL)
    {
        n = GetLastError();
        _ftprintf(stderr, _T("Cannot allocate heap memory 0x%08lx.\n"), n);
        return n;
    }
    // "cmd.exe /c wt -d <directory>"
    LPTSTR p = buf;
    *p++ = '/';
    *p++ = 'c';
    *p++ = ' ';
    *p++ = 'w';
    *p++ = 't';
    *p++ = ' ';
    *p++ = '-';
    *p++ = 'd';
    *p++ = ' ';
    *p++ = '"';
    n = GetCurrentDirectory(n, p);
    if (n == 0)
    {
        n = GetLastError();
        _ftprintf(stderr, _T("Cannot get current directory 0x%08lx.\n"), n);
        return n;
    }
    p += n;
    // Remove the trailing backslash, if any.
    if (*(p - 1) == '\\')
    {
        --p;
    }
    *p++ = '"';
    *p++ = '\0';

    _ftprintf(stdout, _T("cmd.exe %s\n"), buf);
    //*
    STARTUPINFO startupInfo;
    memset(&startupInfo, 0, sizeof(startupInfo));
    startupInfo.cb = sizeof(STARTUPINFO);
    PROCESS_INFORMATION processInfo;
    memset(&processInfo, 0, sizeof(processInfo));
    n = CreateProcess(_T("C:\\Windows\\System32\\cmd.exe"), // Application
                      buf,           // Command line arguments
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
        n = GetLastError();
        _ftprintf(stderr, _T("Cannot create process 0x%08lx.\n"), n);
        HeapFree(GetProcessHeap(), 0, buf);
        return n;
    }
    CloseHandle(processInfo.hThread);
    CloseHandle(processInfo.hProcess);
    //*/

    /*
#pragma comment(lib, "ole32")
#pragma comment(lib, "shell32.lib")
    CoInitializeEx(NULL, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    HINSTANCE h = ShellExecute(NULL,          // HWND
                               _T("open"),    // Verb
                               _T("cmd.exe"), // File
                               buf,           // Command line arguments
                               NULL,          // Directory
                               SW_HIDE);      // ShowCmd
    if ((INT_PTR)(h) <= 32)
    {
        n = GetLastError();
        _ftprintf(stderr, _T("Cannot create process 0x%08lx.\n"), n);
        CoUninitialize();
        HeapFree(GetProcessHeap(), 0, buf);
        return n;
    }
    CoUninitialize();
    */

    HeapFree(GetProcessHeap(), 0, buf);
    return 0;
}

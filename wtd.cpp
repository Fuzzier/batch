/**
 * @file
 *
 * @brief Windows Terminal Launcher.
 *
 * @version 1.0
 * @author  Wei Tang <gauchyler@uestc.edu.cn>
 * @date    2023-08-11
 *
 * @copyright Copyright (c) 2023.
 *   National Key Laboratory of Science and Technology on Communications,
 *   University of Electronic Science and Technology of China.
 *   All rights reserved.
 */

#define UNICODE
#define _UNICODE

#include <windows.h>
#include <stdio.h>
#include <tchar.h>
#include <string>
#include <vector>
#include <unordered_map>
#include <type_traits>
#include <sstream>

#pragma comment(lib, "advapi32")  // RegXxx()

////////////////////////////////////////////////////////////////////////////////
namespace std {

#if defined(UNICODE)
    using tstring = std::wstring;
    using tostringstream = std::wostringstream;
#else // !defined(UNICODE)
    using tstring = std::string;
    using tostringstream = std::ostringstream;
#endif // defined(UNICODE)

} // namespace std


////////////////////////////////////////
/**
 * @brief A simple *in-place* parser for command-line options.
 *
 * # Capability
 *
 * Three types of options are supported.
 * * *flag*: an boolean option that is set to `true`.
 *         e.g., `-y`, `--yes`.
 * * *named value*: a value that follows a name.
 *         e.g., `--port 80`.
 * * *positional*: a standalone and ordered value.
 *         e.g., `config.json`.
 *
 * For simplicity, `CliParser` does the following.
 * * A *flag* is treated as a *named value* whose value is `"1"`.
 * * All values are provided as `const char*`.
 * * No explicit exceptions are thrown.
 *   + Exceptions may still be thrown by `std` objects, e.g., `std::bad_alloc`.
 *   + `nullptr` is used as the value of non-existing options.
 *
 * Thus, `CliParser` only provides two types of options.
 * * *named value*
 * * *positional*
 *
 * # In-place parsing
 *
 * `CliParser` parses arguments *in-place*.
 * That is, it **does not** allocate memory to store the arguments.
 * It only stores pointers to arguments.
 * Therefore, the `argv` **must** be *available* and *unchanged* during the lifetime of
 * the `CliParser`.
 *
 * # Usage
 *
 * Pass the arguments of the `main` function to construct `CliParser`.
 *
 * @code{.cpp}
 * int main(int argc, TCHAR** argv[])
 * {
 *     CliParser parser(argc, argv);
 * }
 * @endcode
 *
 * To check the existance of a named option, users can use `has()`.
 * To access the value of the option, users can use the `()` operator.
 * * If an integer is provided, it accesses a *positional*.
 * * If a string is provided, it accesses a *named value*.
 * * A *default value* may also be provided.
 *
 * @code{.cpp}
 * if (parser.has("port"))
 * {
 *     std::cout << "port: " << parser("port") << std::endl;
 * }
 * @endcode
 *
 * If the name refers to an *unknown option*, `CliParser` **does not** throw exceptions.
 * Instead, an *nullptr* is returned.
 *
 * @code{.cpp}
 * if (parser("port"))
 * {
 *     std::cout << "port: " << parser("port") << std::endl;
 * }
 * @endcode
 *
 * A default value can be also provided for a *named value*.
 *
 * @code{.cpp}
 * uint16_t port = boost::lexicial_cast<uint16_t>(parser("port", "80"));
 * @endcode
 *
 * # Process
 *
 * The arguments are classified as follows.
 * * *name*: An argument that starts with a dash, which looks like `"-xxx"`.
 *         All dashes at the start of a name are stripped.
 * * *value*: An argument that *does not* start with a dash.
 *
 * The arguments are processed as follows.
 * * If a *name* is followed by a *value*, then the value is a *named value*.
 * * If a *name* is **not** followed by a *value*, then it is a *flag* set to `true`.
 * * If a *value* is **not** following a *name*, then it is a *positional*.
 * * If the argument is the *first* one that consists of only dashes, then
 *   it is a *separator*.
 * * The following arguments are collected as *positional* arguments.
 *
 * # Examples
 *
 * The general form of a command-line is like follows.
 * @verbatim
 * program --port 80 -udp -- config.json
 * @endverbatim
 *
 * The above command-line specifies:
 * * A named value: `("port", "80")`
 * * A flag: `"udp"`
 * * A seperator: discarded.
 * * Tow positional: `"program"`, `"config.json"`
 *
 * # Remarks
 *
 * The command-line options **shall** be kept simple and stupid.
 * For example, `CliParser` treats *flags* as *named values*, so `"--yes 1"` is
 * semantically the same as `"--yes"`.
 * However, it is **not** recommended to add a value that follows a *flag*.
 */
class CliParser
{
public:
    CliParser(void) noexcept
    {
    }

    CliParser(int argc, const TCHAR* const* argv)
    {
        parse_(argc, argv);
    }

public:
    /**
     * @brief Parse command-line options.
     */
    void parse(int argc, const TCHAR* const* argv)
    {
        values_.clear();
        positionals_.clear();
        parse_(argc, argv);
    }

private:
    void parse_(int argc, const TCHAR* const* argv)
    {
        bool sep = false;            // Seperator encountered.
        const TCHAR* name = nullptr; // To-be-processed name.
        for (int i = 0; i < argc; ++i)
        {
            const TCHAR* s = argv[i];
            if (!sep)
            {
                // If the argument looks like '-???'.
                if (*s == '-')
                {
                    // Skip all leading '-'s.
                    while (*s == '-')
                    {
                        ++s;
                    }
                    // If the argument consists of '-'s only.
                    if (!*s)
                    {
                        // This is the first separator.
                        sep = true;
                        // The name without a value is treated as a flag.
                        if (name)
                        {
                            values_.emplace(name, _T("1"));
                            name = nullptr;
                        }
                    }
                    // Otherwise, it is a name of an option.
                    else
                    {
                        // The previous name without a value is treated as a flag.
                        if (name)
                        {
                            values_.emplace(name, _T("1"));
                        }
                        name = s;
                    }
                }
                // If the argument does not start with '-'.
                else
                {
                    // If the value follows a name.
                    if (name)
                    {
                        values_.emplace(name, s);
                        name = nullptr;
                    }
                    // The value without a name is treated as a positional.
                    else
                    {
                        positionals_.push_back(s);
                    }
                }
            }
            else // if (sep)
            {
                positionals_.push_back(s);
            }
        } // for (int i = 0; i < argc; ++i)
        // The previous name without a value is treated as a flag.
        if (name)
        {
            values_.emplace(name, _T("1"));
        }
    }

public:
    /**
     * @brief Has the named option?
     */
    template<class Char>
    typename std::enable_if<std::is_same<Char, TCHAR>::value, bool>::type
    has(const Char* name) const noexcept
    {
        return !!values_.count(name);
    }

    /**
     * @brief Has the named option?
     */
    bool has(const std::tstring& name) const noexcept
    {
        return !!values_.count(name);
    }

    /**
     * @brief Query the named option.
     *
     * @return If the `name` does not exist, `nullptr` is returned.
     */
    template<class Char>
    typename std::enable_if<std::is_same<Char, TCHAR>::value, const TCHAR*>::type
    operator()(const Char* name) const noexcept
    {
        auto it = values_.find(name);
        if (it != values_.cend())
        {
            return it->second;
        }
        return nullptr;
    }

    /**
     * @brief Query the named option.
     *
     * @return If the `name` does not exist, `nullptr` is returned.
     */
    const TCHAR* operator()(const std::tstring& name) const noexcept
    {
        auto it = values_.find(name);
        if (it != values_.cend())
        {
            return it->second;
        }
        return nullptr;
    }

    /**
     * @brief Query the named option with a default value.
     *
     * @return If the `name` does not exist, `def` is returned.
     */
    template<class Char>
    typename std::enable_if<std::is_same<Char, TCHAR>::value, const TCHAR*>::type
    operator()(const Char* name, const TCHAR* def) const noexcept
    {
        auto it = values_.find(name);
        if (it != values_.cend())
        {
            return it->second;
        }
        else
        {
            return def;
        }
    }

    /**
     * @brief Query the named option with a default value.
     *
     * @return If the `name` does not exist, `def` is returned.
     */
    const TCHAR* operator()(const std::tstring& name, const TCHAR* def) const noexcept
    {
        auto it = values_.find(name);
        if (it != values_.cend())
        {
            return it->second;
        }
        else
        {
            return def;
        }
    }

    /**
     * @brief The number of positionals.
     */
    size_t pcount(void) const noexcept
    {
        return positionals_.size();
    }

    /**
     * @brief Has the positional option?
     */
    bool has(size_t index) const noexcept
    {
        return index < positionals_.size();
    }

    /**
     * @brief Query the positional option.
     *
     * @return If the `index` is out of range, `nullptr` is returned.
     */
    const TCHAR* operator()(size_t index) const noexcept
    {
        if (index < positionals_.size())
        {
            return positionals_[index];
        }
        return nullptr;
    }

    /**
     * @brief Query the positional option with a default value.
     *
     * @return If the `index` is out of range, `def` is returned.
     */
    const TCHAR* operator()(size_t index, const TCHAR* def) const noexcept
    {
        if (index < positionals_.size())
        {
            return positionals_[index];
        }
        return def;
    }

private:
    // name => value.
    std::unordered_map<std::tstring, const TCHAR*>  values_;

    // positional.
    std::vector<const TCHAR*>  positionals_;
};


////////////////////////////////////////////////////////////////////////////////
int _tmain(int argc, TCHAR** argv)
{
    CliParser cli(argc, argv);
    DWORD retval = 0;
    HKEY hkey = NULL;
    {
        std::tostringstream oss;
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
            goto exit;
        }
        LONG length = 0;
        retval = RegQueryValue(hkey, NULL, NULL, &length);
        if (retval != ERROR_SUCCESS)
        {
            goto exit;
        }
        LONG cch = length / sizeof(TCHAR);
        std::tstring app(cch - 1, _T('\0'));
        retval = RegQueryValue(hkey, NULL, &app[0], &length);
        if (retval != ERROR_SUCCESS)
        {
            goto exit;
        }
        oss << _T('\"') << app << _T("\" ");
        ////////////////////
        // Parse command line
        for (int i = 1; i < argc; ++i)
        {
            if (0 == _tcscmp(argv[i], _T("-d")) ||
                0 == _tcscmp(argv[i], _T("--startingDirectory")))
            {
                ++i;
                continue;
            }
            // If there are spaces.
            if (_tcschr(argv[i], _T(' ')))
            {
                // Add double quotes.
                oss << '"' << argv[i] << _T("\" ");
            }
            else
            {
                oss << argv[i] << _T(" ");
            }
        }
        ////////////////////
        // The current directory.
        std::tstring pwd;
        DWORD n = GetCurrentDirectory(0, NULL);
        if (n == 0)
        {
            retval = GetLastError();
            _ftprintf(stderr, _T("Cannot get length of current directory 0x%08lx.\n"), retval);
            goto exit;
        }
        pwd.assign(n, _T('\0'));
        n = GetCurrentDirectory(n, &pwd[0]);
        if (n == 0)
        {
            retval = GetLastError();
            _ftprintf(stderr, _T("Cannot get current directory 0x%08lx.\n"), retval);
            goto exit;
        }
        do
        {
            std::tstring dir;
            if (cli.has(_T("d")))
            {
                dir = cli(_T("d"));
            }
            else if (cli.has(_T("startingDirectory")))
            {
                dir = cli(_T("startingDirectory"));
            }
            else
            {
                oss << _T("-d \"") << pwd.data() << _T("\"");
                break;
            }
            if (dir.size() >= 2)
            {
                // Is absolute path?
                if (_istalpha(dir[0]) && dir[1] == _T(':'))
                {
                    oss << _T("-d \"") << dir.data() << _T("\"");
                    break;
                }
            }
            oss << _T("-d \"") << pwd.data()
                << _T("\\") << dir.data() << _T("\"");
        }
        while (false);
        std::tstring args = oss.str();
        ////////////////////
        // Output diagnostic information.
#if !defined(NDEBUG)
        _ftprintf(stdout, _T("%s\n"), args.data());
#endif // !defined(NDEBUG)
        ////////////////////
        // Run Windows Terminmal.
        STARTUPINFO startupInfo;
        memset(&startupInfo, 0, sizeof(startupInfo));
        startupInfo.cb = sizeof(STARTUPINFO);
        PROCESS_INFORMATION processInfo;
        memset(&processInfo, 0, sizeof(processInfo));
        n = CreateProcess(&app[0],       // Application
                          &args[0],      // Command line arguments
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
            goto exit;
        }
        CloseHandle(processInfo.hThread);
        CloseHandle(processInfo.hProcess);
    }
exit:
    RegCloseKey(hkey);
    return retval;
}

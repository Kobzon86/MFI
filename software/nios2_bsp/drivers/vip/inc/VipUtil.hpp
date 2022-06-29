#ifndef __VIP_UTIL_HPP__
#define __VIP_UTIL_HPP__

/**
 * @name VIP Utilities
 * @brief This contains utility methods for use in developing Video and Image Processing Suite Nios control code.
 */
#include <system.h>

#if defined(ALT_STDOUT_IS_JTAG_UART) && !defined(NDEBUG)
#include <stdio.h>
#include <io.h>
#include <cstdarg>
#define VIP_CONSOLE_MSG(...) VipUtil::console(__VA_ARGS__)
#define VIP_ERROR_MSG(...) VipUtil::error(__VA_ARGS__)
#define VIP_WARNING_MSG(...) VipUtil::warning(__VA_ARGS__)
#define VIP_INFO_MSG(...) VipUtil::info(__VA_ARGS__)
#define VIP_DEBUG_MSG(...) VipUtil::debug(__VA_ARGS__)
#else
#define VIP_CONSOLE_MSG(...)
#define VIP_ERROR_MSG(...)
#define VIP_WARNING_MSG(...)
#define VIP_INFO_MSG(...)
#define VIP_DEBUG_MSG(...)
#endif

class VipUtil {
public:
    /**
     * @brief Log level tracking
     * This allows a user to set the logging level of their application, all
     * the way from printing/displaying every message to displaying none.
     * ALL:   Print every message logged.
     * DEBUG:   Print information specific to debugging a problem with the code.
     * INFO:    Print information that could be useful to a user understanding the system.
     * WARNING: Print potential issues with the system that could cause problems.
     * ERROR:   Print issues/problems which will cause problems/crashes.
     * NONE:    Do not print any logging.
     */
    enum LogLevelType {
        LOG_ALL     = 5,
        LOG_DEBUG   = 4,
        LOG_INFO    = 3,
        LOG_WARNING = 2,
        LOG_ERROR   = 1,
        LOG_NONE    = 0
    };

    static LogLevelType current_level;

    /**
     * @brief Sets the printing/displaying threshold level.
     * Sets the threshold level that controls which messages are printed to the
     * console/terminal using printf, and which messages are discarded.
     * The logging levels go ALL > DEBUG > INFO > WARNING > ERROR > NONE.
     * This means that setting the log level to INFO will cause any ERROR,
     * WARNING and INFO messages to be displayed, but DEBUG messages will be
     * discarded and not displayed.
     * @param [log_level_t] level The threshold level, can be ALL, DEBUG, INFO, WARNING, ERROR or NONE.
     * Example Usage:
     * @code
     *     VipUtil::set_log_level(Util::INFO);  // Set logging level to display INFO, WARNING and ERROR messages.
     * @endcode
     */
    inline static void set_log_level(LogLevelType level) {
        VipUtil::current_level = level;
    }

    /**
     * @brief Returns the current logging level for the application.
     * @see set_log_level
     * @return The current logging level for the application.
     */
    inline static LogLevelType get_log_level() {
        return VipUtil::current_level;
    }


#if defined(ALT_STDOUT_IS_JTAG_UART) && !defined(NDEBUG)
    /**
     * "Hidden" internal method for actually printing the log/console calls.
     */
    static void _print(char const * format, va_list args) {
        char buffer[256];
        vsprintf(buffer, format, args);
        printf("%s", buffer);
        va_end(args);
    }

    /**
     * @brief Ignores all the logging levels, just *always* print directly to console.
     * If you don't want to deal with the various logging levels, this method
     * will just bypass all of the level checking and always print out to the
     * console/terminal using printf.
     */
    static void console(char const * format, ...)
    {
        if (current_level > LOG_NONE) {
            va_list args;
            va_start(args, format);
            VipUtil::_print(format, args);
        }
    }

    /**
     * @brief For logging failures that will cause the system to stop functioning.
     * This can be used to print issues/problems which will certainly cause
     * problems/crashes.
     */
    static void error(char const * format, ...)
    {
        if (current_level >= LOG_ERROR) {
            va_list args;
            va_start(args, format);
            VipUtil::_print(format, args);
        }
    }

    /**
     * @brief For logging warnings.
     * This can be used to print potential issues with the system that could
     * cause problems.
     */
    static void warning(char const * format, ...)
    {
        if (current_level >= LOG_WARNING) {
            va_list args;
            va_start(args, format);
            VipUtil::_print(format, args);
        }
    }

    /**
     * @brief For logging information messages.
     * This can be used to print information that could be useful to a user
     * understanding the system, for instance reporting statistics or states.
     */
    static void info(char const * format, ...)
    {
        if (current_level >= LOG_INFO) {
            va_list args;
            va_start(args, format);
            VipUtil::_print(format, args);
        }
    }

    /**
     * @brief For logging debugging information.
     * This can be used to print information specific to debugging a problem
     * with the code which doesn't usually have to be displayed to a user.
     */
    static void debug(char const * format, ...)
    {
        if (current_level >= LOG_DEBUG) {
            va_list args;
            va_start(args, format);
            VipUtil::_print(format, args);
        }
    }
#endif
};

#endif     // __VIP_UTIL_HPP__

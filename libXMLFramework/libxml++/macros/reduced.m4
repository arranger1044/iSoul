## LIBXMLCPP_ARG_ENABLE_API_EXCEPTIONS()
##
## Provide the --enable-api-exceptions configure argument, enabled
## by default.
##
AC_DEFUN([LIBXMLCPP_ARG_ENABLE_API_EXCEPTIONS],
[
  AC_ARG_ENABLE([api-exceptions],
      [  --enable-api-exceptions  Build exceptions API.
                              [[default=yes]]],
      [libxmlcpp_enable_api_exceptions="$enableval"],
      [libxmlcpp_enable_api_exceptions='yes'])

  if test "x$libxmlcpp_enable_api_exceptions" = "xyes"; then
  {
    AC_DEFINE([LIBXMLCPP_EXCEPTIONS_ENABLED],[1], [Defined when the --enable-api-exceptions configure argument was given])
  }
  fi
])


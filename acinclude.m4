dnl AM_LIBXML([ACTION-IF-FOUND [, ACTION-IF-NOT-FOUND]])

AC_DEFUN(AM_LIBXML,
[

AC_MSG_CHECKING(for libxml version >= 2.5.1)

if xml2-config --libs print > /dev/null 2>&1; then
    vers=`xml2-config --version | sed -e "s/libxml //" | awk 'BEGIN { FS = "."; } { printf "%d", ($''1 * 1000 + $''2) * 1000 + $''3;}'`
    if test $vers -ge 2005001; then
        AC_MSG_RESULT(yes)
        LIBXML_CFLAGS=`xml2-config --cflags`
        LIBXML_LIBS=`xml2-config --libs`
        AC_SUBST(LIBXML_CFLAGS)
        AC_SUBST(LIBXML_LIBS)
        ifelse([$1], , :, [$1])
    else
        AC_MSG_RESULT(no)
        ifelse([$2], , , [$2])
    fi
elif xml-config --libs print > /dev/null 2>&1; then
    vers=`xml-config --version | sed -e "s/libxml //" | awk 'BEGIN { FS = "."; } { printf "%d", ($''1 * 1000 + $''2) * 1000 + $''3;}'`
    if test $vers -ge 2000000; then
        AC_MSG_RESULT(yes)
        LIBXML_CFLAGS=`xml-config --cflags`
        LIBXML_LIBS=`xml-config --libs`
        AC_SUBST(LIBXML_CFLAGS)
        AC_SUBST(LIBXML_LIBS)
        ifelse([$1], , :, [$1])
    else
        AC_MSG_RESULT(no)
        ifelse([$2], , , [$2])
    fi
else
    AC_MSG_RESULT(no)
    ifelse([$2], , , [$2])
fi

])


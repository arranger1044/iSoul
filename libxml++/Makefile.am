SUBDIRS = parsers exceptions nodes io validators

INCLUDES = -I$(top_srcdir) @LIBXML_CFLAGS@
DEFS = @DEFS@ -DLIBXMLPP_BUILD

h_sources_public = libxml++.h attribute.h dtd.h document.h noncopyable.h keepblanks.h
h_sources_private = 
cc_sources = attribute.cc dtd.cc document.cc noncopyable.cc keepblanks.cc
cc_sources_private =

# Support for DLL on cygwin/mingw using libtool > 1.4
if PLATFORM_WIN32
win32_dlls_ldflags = -no-undefined -Wl,--export-all-symbols
else
win32_dlls_ldflags =
endif

lib_LTLIBRARIES = libxml++-2.6.la
libxml___2_6_la_LDFLAGS = -version-info $(GENERIC_LIBRARY_VERSION) $(win32_dlls_ldflags) 
libxml___2_6_la_LIBADD = parsers/libparsers.la \
                         validators/libvalidators.la \
                         exceptions/libexceptions.la \
                         nodes/libnodes.la \
                         io/libio.la \
						 @LIBXML_LIBS@
libxml___2_6_la_SOURCES = $(cc_sources) $(h_sources_public) $(h_sources_private) $(cc_sources_private)

# Install the headers:
library_includedir=$(includedir)/libxml++-2.6/libxml++
library_include_HEADERS = $(h_sources_public)

library_configdir = $(libdir)/libxml++-2.6/include
library_config_DATA = libxml++config.h


SUBDIRS = parsers exceptions nodes io

INCLUDES = -I$(top_srcdir) @LIBXML_CFLAGS@

h_sources_public = libxml++.h attribute.h dtd.h document.h noncopyable.h keepblanks.h
h_sources_private = 
cc_sources = attribute.cc dtd.cc document.cc noncopyable.cc keepblanks.cc
cc_sources_private =

lib_LTLIBRARIES = libxml++-2.6.la
libxml___2_6_la_LDFLAGS = -version-info $(GENERIC_LIBRARY_VERSION)
libxml___2_6_la_LIBADD = @LIBXML_LIBS@ \
                         parsers/libparsers.la \
                         exceptions/libexceptions.la \
                         nodes/libnodes.la \
			 io/libio.la
libxml___2_6_la_SOURCES = $(cc_sources) $(h_sources_public) $(h_sources_private) $(cc_sources_private)

# Install the headers:
library_includedir=$(includedir)/libxml++-2.6/libxml++
library_include_HEADERS = $(h_sources_public)


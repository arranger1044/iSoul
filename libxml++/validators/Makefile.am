INCLUDES = -I$(top_srcdir) @LIBXML_CFLAGS@

h_sources_public = validator.h dtdvalidator.h
cc_sources = validator.cc dtdvalidator.cc


noinst_LTLIBRARIES = libvalidators.la
libvalidators_la_SOURCES = $(h_sources_public) $(cc_sources)

# Install the headers:
library_includedir=$(includedir)/libxml++-2.6/libxml++/validators
library_include_HEADERS = $(h_sources_public)

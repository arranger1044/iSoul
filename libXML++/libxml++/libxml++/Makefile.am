AM_CPPFLAGS = -I$(top_builddir) -I$(top_srcdir) -I. $(LIBXMLXX_CFLAGS)
DEFS = @DEFS@ -DLIBXMLPP_BUILD

h_sources_public = libxml++.h \
	attribute.h \
	attributedeclaration.h \
	attributenode.h \
	document.h \
	dtd.h \
	keepblanks.h \
	noncopyable.h \
	schema.h \
	exceptions/exception.h \
	exceptions/parse_error.h \
	exceptions/validity_error.h \
	exceptions/internal_error.h \
	io/istreamparserinputbuffer.h \
	io/outputbuffer.h \
	io/ostreamoutputbuffer.h \
	io/parserinputbuffer.h \
	nodes/cdatanode.h \
	nodes/commentnode.h \
	nodes/contentnode.h \
	nodes/element.h \
	nodes/entitydeclaration.h \
	nodes/entityreference.h \
	nodes/node.h \
	nodes/processinginstructionnode.h \
	nodes/textnode.h \
	parsers/parser.h \
	parsers/saxparser.h \
	parsers/domparser.h \
	parsers/textreader.h \
	validators/dtdvalidator.h \
	validators/schemavalidator.h \
	validators/validator.h
cc_sources = attribute.cc \
	attributedeclaration.cc \
	attributenode.cc \
	document.cc \
	dtd.cc \
	keepblanks.cc \
	noncopyable.cc \
	schema.cc \
	exceptions/exception.cc \
	exceptions/parse_error.cc \
	exceptions/validity_error.cc \
	exceptions/internal_error.cc \
	io/istreamparserinputbuffer.cc \
	io/outputbuffer.cc \
	io/ostreamoutputbuffer.cc \
	io/parserinputbuffer.cc \
	nodes/cdatanode.cc \
	nodes/commentnode.cc \
	nodes/contentnode.cc \
	nodes/entitydeclaration.cc \
	nodes/entityreference.cc \
	nodes/element.cc \
	nodes/node.cc \
	nodes/processinginstructionnode.cc \
	nodes/textnode.cc \
	parsers/parser.cc \
	parsers/saxparser.cc \
	parsers/domparser.cc \
	parsers/textreader.cc \
	validators/dtdvalidator.cc \
	validators/schemavalidator.cc \
	validators/validator.cc

win32_dlls_ldflags = -no-undefined

lib_LTLIBRARIES = libxml++-2.6.la
libxml___2_6_la_LDFLAGS = -version-info $(LIBXMLXX_SO_VERSION) $(win32_dlls_ldflags)
libxml___2_6_la_LIBADD = $(LIBXMLXX_LIBS)
libxml___2_6_la_SOURCES = $(cc_sources) $(h_sources_public)

# Install the headers:
library_includedir=$(includedir)/libxml++-2.6/libxml++
library_include_HEADERS = $(h_sources_public)

include $(top_srcdir)/examples/Makefile.am_fragment

#Build the executable, but don't install it.
noinst_PROGRAMS = example

#List of source files needed to build the executable:
example_SOURCES = main.cc \
	svgparser.cc svgparser.h \
	svgdocument.h svgdocument.cc \
	svgelement.cc svgelement.h \
	svgpath.h \
	svggroup.h

EXTRA_DIST = example.xml README

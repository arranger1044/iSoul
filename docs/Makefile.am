## This voodoo stuff lets automake see the subdirs
## without including them into recursive builds.
if LIBXMLCPP_FALSE
SUBDIRS = reference
endif
DIST_SUBDIRS = reference

EXTRA_DIST = Makefile_web.am_fragment

include $(top_srcdir)/docs/Makefile_web.am_fragment
html_docs = index.html reference

post-html: reference/@GENERIC_MAJOR_VERSION@.@GENERIC_MINOR_VERSION@/html/index.html
	rsync $(rsync_args) -r $(html_docs) $$USER@shell.sourceforge.net:$(web_path_docs)


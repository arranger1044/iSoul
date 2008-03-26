SUBDIRS = reference manual

EXTRA_DIST = Makefile_web.am_fragment

include $(top_srcdir)/docs/Makefile_web.am_fragment
html_docs = reference manual

post-html: reference/html/index.html
	rsync $(rsync_args) -r index.html $$USER@shell.sourceforge.net:$(web_path_project)
	rsync $(rsync_args) -r $(html_docs) $$USER@shell.sourceforge.net:$(web_path_docs)
	rsync $(rsync_args) -r ../examples $$USER@shell.sourceforge.net:$(web_path_project)


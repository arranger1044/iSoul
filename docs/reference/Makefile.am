doxygen_configfile = Doxyfile

include $(top_srcdir)/docs/Makefile_web.am_fragment
web_path_reference = $(web_path_docs)reference

EXTRA_DIST = README Doxyfile


html/index.html: $(doxygen_configfile)
	doxygen $(doxygen_configfile)


libxml++-reference-html.tar.gz: html/index.html
	tar cf - html | gzip -c --best >$@


# Upload to the web site:
post-html:
	rsync -avz --rsh ssh --cvs-exclude * $$USER@shell.sourceforge.net:$(web_path_reference)


all-local: clean-local html/index.html

clean-local:
	-rm html/*.html
	-rm -f libxml++-reference-html.tar.gz


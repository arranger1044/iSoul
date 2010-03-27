EXTRA_DIST = $(docbook_docs) html libxml++.xml libxml++_without_code.xml insert_example_code.pl

# Create a DocBook source file with the code inline, instead of the special comments.
libxml++.xml: libxml++_without_code.xml insert_example_code.pl
	$(PERL) insert_example_code.pl ../../examples $< >$@

docbook_docs = $(srcdir)/libxml++.xml

include $(top_srcdir)/docs/Makefile_web.am_fragment
article_upload_path = $(web_path_docs)manual


DOCBOOK_STYLESHEET ?= http://docbook.sourceforge.net/release/xsl/current/html/chunk.xsl

html/index.html: $(srcdir)/libxml++.xml
	-rm -rf html
	$(mkinstalldirs) html
	xsltproc -o html/ --catalogs $(DOCBOOK_STYLESHEET) $<

html: html/index.html

libxml++-html.tar.gz: $(srcdir)/html
	tar -cf - $< | gzip > $@

%.dvi: $(srcdir)/%.xml
	db2dvi $<

%.ps: $(srcdir)/%.xml
	db2ps $<

%.pdf: $(srcdir)/%.xml
	db2pdf $<


post-lumps: $(srcdir)/libxml++.dvi $(srcdir)/libxml++.ps $(srcdir)/libxml++.pdf $(srcdir)/libxml++-html.tar.gz
	tar -cf - $^ | ssh $$SSH_OPT $$USER@libxmlplusplus.sourceforge.net "cd $(libxml++) ; tar -xvf - ; chmod a+r,g+w * ; chgrp libxmlplusplus *"

post-html: $(srcdir)/html/index.html
	(cd html && tar -cf - *.html | gzip -3 | \
	 ssh $$SSH_OPT $$USER@libxmlplusplus.sourceforge.net "cd $(article_upload_path)/html ; gunzip | tar -xvf - ; chmod a+r,g+w * ; chgrp libxmlplusplus *")

manualdir = $(docdir)/manual/html


install-manual: $(srcdir)/html/index.html
	@$(NORMAL_INSTALL)
	$(mkinstalldirs) $(DESTDIR)$(manualdir)
	@dir='$(<D)'; for p in $$dir/*.html ; do \
	  f="`echo $$p | sed -e 's|^.*/||'`"; \
	  echo " $(INSTALL_DATA) $$p $(DESTDIR)$(manualdir)/$$f"; \
	  $(INSTALL_DATA) $$p $(DESTDIR)$(manualdir)/$$f; \
	done

uninstall-manual: $(srcdir)/html/index.html
	@$(NORMAL_UNINSTALL)
	@dir='$(<D)'; for p in $$dir/*.html ; do \
	  f="`echo $$p | sed -e 's|^.*/||'`"; \
	  echo " rm -f $(DESTDIR)$(manualdir)/$$f"; \
	  rm -f $(DESTDIR)$(manualdir)/$$f; \
	done

install-data-local: install-manual

uninstall-local: uninstall-manual

all-local: $(srcdir)/html/index.html

maintainer-clean-local:
	-rm -rf $(srcdir)/html
	-rm -f $(srcdir)/libxml++.dvi $(srcdir)/libxml++.ps $(srcdir)/libxml++.pdf $(srcdir)/libxml++-html.tar.gz


doxygen_configfile = Doxyfile
doxygen_configfile_source = $(srcdir)/Doxyfile.in

include $(top_srcdir)/docs/Makefile_web.am_fragment
web_path_reference = $(web_path_docs)reference


EXTRA_DIST = README Doxyfile libxml++_doxygen_tags @GENERIC_MAJOR_VERSION@.@GENERIC_MINOR_VERSION@/html \
             libstdc++.tag.xml
#Ideally, libstdc++.tag.xml would be installed by gcc, instead of being copied into every project.

index_html = @GENERIC_MAJOR_VERSION@.@GENERIC_MINOR_VERSION@/html/index.html


$(index_html): $(doxygen_configfile_source)
	doxygen $(doxygen_configfile)


libxml++-reference-html.tar.gz: $(index_html)
	tar cf - @GENERIC_MAJOR_VERSION@.@GENERIC_MINOR_VERSION@/html | gzip -c --best >$@


# Upload to the web site:
post-html:
	rsync -avz --rsh ssh --cvs-exclude * $$USER@shell.sourceforge.net:$(web_path_reference)


all-local: $(index_html)

doc-clean:
	-rm -rf @GENERIC_MAJOR_VERSION@.@GENERIC_MINOR_VERSION@/html
	-rm -f libxml++_doxygen_tags
	-rm -f $libxml++-reference-html.tar.gz


referencedir = $(docdir)/reference/@GENERIC_MAJOR_VERSION@.@GENERIC_MINOR_VERSION@/html

install-reference: $(index_html)
	@$(NORMAL_INSTALL)
	$(mkinstalldirs) $(DESTDIR)$(referencedir)
	@dir='$(<D)'; for p in $$dir/*.html $$dir/*.css $$dir/*.png $$dir/*.jpg $$dir/*.map $$dir/*.md5 $$dir/*.dot ; do \
	  f="`echo $$p | sed -e 's|^.*/||'`"; \
	  echo " $(INSTALL_DATA) $$p $(DESTDIR)$(referencedir)/$$f"; \
	  $(INSTALL_DATA) $$p $(DESTDIR)$(referencedir)/$$f; \
	done

uninstall-reference: $(index_html)
	@$(NORMAL_UNINSTALL)
	@dir='$(<D)'; for p in $$dir/*.html $$dir/*.css $$dir/*.png $$dir/*.jpg $$dir/*.map $$dir/*.md5 $$dir/*.dot ; do \
	  f="`echo $$p | sed -e 's|^.*/||'`"; \
	  echo " rm -f $(DESTDIR)$(referencedir)/$$f"; \
	  rm -f $(DESTDIR)$(referencedir)/$$f; \
	done

install-data-local: install-reference

uninstall-local: uninstall-reference

maintainer-clean-local: doc-clean

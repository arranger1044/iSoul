<?xml version="1.0"?>

<!-- Customisation of DocBook processing for libxml++. -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/html/chunk.xsl"/>

<xsl:param name="toc.section.depth" select="1"/>
<xsl:param name="chunker.output.indent" select="'yes'"/>
<xsl:param name="chunker.output.encoding" select="'UTF-8'"/>
<xsl:param name="toc.list.type" select="'ul'"/>
<!-- Set the use.id.as.filename param so that the chapter / section number is
     not used as the filename, otherwise the URL will change every time
     anything is re-ordered or inserted in the documentation. -->
<xsl:param name="use.id.as.filename" select="1"/>

</xsl:stylesheet>

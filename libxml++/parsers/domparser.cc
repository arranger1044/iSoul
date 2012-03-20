/* domparser.cc
 * libxml++ and this file are copyright (C) 2000 by Ari Johnson, and
 * are covered by the GNU Lesser General Public License, which should be
 * included with libxml++ as the file COPYING.
 */

#include "libxml++/parsers/domparser.h"
#include "libxml++/dtd.h"
#include "libxml++/nodes/element.h"
#include "libxml++/nodes/textnode.h"
#include "libxml++/nodes/commentnode.h"
#include "libxml++/keepblanks.h"
#include "libxml++/exceptions/internal_error.h"
#include <libxml/parserInternals.h>//For xmlCreateFileParserCtxt().

#include <sstream>
#include <iostream>

namespace xmlpp
{

DomParser::DomParser()
: doc_(0)
{
  //Start with an empty document:
  doc_ = new Document();
}

DomParser::DomParser(const Glib::ustring& filename, bool validate)
: doc_(0)
{
  set_validate(validate);
  parse_file(filename);
}

DomParser::~DomParser()
{ 
  release_underlying();
}

void DomParser::parse_file(const Glib::ustring& filename)
{
  release_underlying(); //Free any existing document.

  KeepBlanks k(KeepBlanks::Default);
  xmlResetLastError();

  //The following is based on the implementation of xmlParseFile(), in xmlSAXParseFileWithData():
  context_ = xmlCreateFileParserCtxt(filename.c_str());

  if(!context_)
  {
    throw internal_error("Couldn't create parsing context\n" + format_xml_error());
  }

  if(context_->directory == 0)
  {
    char* directory = xmlParserGetDirectory(filename.c_str());
    context_->directory = (char*) xmlStrdup((xmlChar*) directory);
  }

  parse_context();
}

void DomParser::parse_memory_raw(const unsigned char* contents, size_type bytes_count)
{
  release_underlying(); //Free any existing document.

  KeepBlanks k(KeepBlanks::Default);
  xmlResetLastError();

  //The following is based on the implementation of xmlParseFile(), in xmlSAXParseFileWithData():
  context_ = xmlCreateMemoryParserCtxt((const char*)contents, bytes_count);

  if(!context_)
  {
    throw internal_error("Couldn't create parsing context\n" + format_xml_error());
  }

  parse_context();
}

void DomParser::parse_memory(const Glib::ustring& contents)
{
  parse_memory_raw((const unsigned char*)contents.c_str(), contents.bytes());
}

void DomParser::parse_context()
{
  KeepBlanks k(KeepBlanks::Default);
  xmlResetLastError();

  //The following is based on the implementation of xmlParseFile(), in xmlSAXParseFileWithData():
  //and the implementation of xmlParseMemory(), in xmlSaxParseMemoryWithData().
  initialize_context();

  if(!context_)
  {
    throw internal_error("Context not initialized\n" + format_xml_error());
  }

  xmlParseDocument(context_);

  check_for_exception();

  const Glib::ustring error_str = format_xml_parser_error(context_);

  if(!error_str.empty())
  {
    release_underlying(); //Free doc_ and context_

    throw parse_error(error_str);
  }

  doc_ = new Document(context_->myDoc);
  // This is to indicate to release_underlying that we took the
  // ownership on the doc.
  context_->myDoc = 0;

  //Free the parse context, but keep the document alive so people can navigate the DOM tree:
  //TODO: Why not keep the context alive too?
  Parser::release_underlying();

  check_for_exception();
}


void DomParser::parse_stream(std::istream& in)
{
  release_underlying(); //Free any existing document.

  KeepBlanks k(KeepBlanks::Default);
  xmlResetLastError();

  context_ = xmlCreatePushParserCtxt(
      0, // setting thoses two parameters to 0 force the parser
      0, // to create a document while parsing.
      0,
      0,
      ""); // here should come the filename. I don't know if it is a problem to let it empty

  if(!context_)
  {
    throw internal_error("Couldn't create parsing context\n" + format_xml_error());
  }

  initialize_context();

  //TODO: Shouldn't we use a Glib::ustring here, and some alternative to std::getline()?
  std::string line;
  while(std::getline(in, line))
  {
    // since getline does not get the line separator, we have to add it since the parser cares
    // about layout in certain cases.
    line += '\n';

    xmlParseChunk(context_, line.c_str(), line.size() /* This is a std::string, not a ustring, so this is the number of bytes. */, 0);
  }

  xmlParseChunk(context_, 0, 0, 1);

  check_for_exception();

  const Glib::ustring error_str = format_xml_parser_error(context_);

  if(!error_str.empty())
  {
    release_underlying(); //Free doc_ and context_

    throw parse_error(error_str);
  }

  doc_ = new Document(context_->myDoc);
  // This is to indicate to release_underlying that we took the
  // ownership on the doc.
  context_->myDoc = 0;


  //Free the parse context, but keep the document alive so people can navigate the DOM tree:
  //TODO: Why not keep the context alive too?
  Parser::release_underlying();

  check_for_exception();
}

void DomParser::release_underlying()
{
  if(doc_)
  {
    delete doc_;
    doc_ = 0;
  }

  Parser::release_underlying();
}

DomParser::operator bool() const
{
  return doc_ != 0;
}

Document* DomParser::get_document()
{
  return doc_;
}

const Document* DomParser::get_document() const
{
  return doc_;
}

} // namespace xmlpp



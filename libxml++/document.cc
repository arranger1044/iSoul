/* document.cc
 * this file is part of libxml++
 *
 * copyright (C) 2003 by the libxml++ development team
 *
 * this file is covered by the GNU Lesser General Public License,
 * which should be included with libxml++ as the file COPYING.
 */

#include <libxml++/document.h>
#include <libxml++/dtd.h>
#include <libxml++/attribute.h>
#include <libxml++/nodes/element.h>
#include <libxml++/nodes/entityreference.h>
#include <libxml++/nodes/textnode.h>
#include <libxml++/nodes/commentnode.h>
#include <libxml++/nodes/cdatanode.h>
#include <libxml++/nodes/processinginstructionnode.h>
#include <libxml++/exceptions/internal_error.h>
#include <libxml++/keepblanks.h>
#include <libxml++/io/ostreamoutputbuffer.h>

#include <libxml/tree.h>

#include <assert.h>

#include <iostream>

namespace
{

//Called by libxml whenever it constructs something,
//such as a node or attribute.
//This allows us to create a C++ instance for every C instance.
void on_libxml_construct(xmlNode* node)
{
  switch (node->type)
  {
    case XML_ELEMENT_NODE:
    {
      node->_private = new xmlpp::Element(node);
      break;
    }
    case XML_ATTRIBUTE_NODE:
    {
      node->_private = new xmlpp::Attribute(node);
      break;
    }
    case XML_TEXT_NODE:
    {
      node->_private = new xmlpp::TextNode(node);
      break;
    }
    case XML_COMMENT_NODE:
    {
      node->_private = new xmlpp::CommentNode(node);
      break;
    }
    case XML_CDATA_SECTION_NODE:
    {
      node->_private = new xmlpp::CdataNode(node);
      break;
    }
    case XML_PI_NODE:
    {
      node->_private = new xmlpp::ProcessingInstructionNode(node);
      break;
    }
    case XML_DTD_NODE:
    {
      node->_private = new xmlpp::Dtd(reinterpret_cast<xmlDtd*>(node));
      break;
    }
    //case XML_ENTITY_NODE:
    //{
    //  assert(0 && "Warning: XML_ENTITY_NODE not implemented");
    //  //node->_private = new xmlpp::ProcessingInstructionNode(node);
    //  break;
    //}
    case XML_ENTITY_REF_NODE:
    {
      node->_private = new xmlpp::EntityReference(node);
      break;
    }
    case XML_DOCUMENT_NODE:
    {
      // do nothing ! in case of documents it's the wrapper that is the owner
      break;
    }
    default:
    {
      // good default for release versions
      node->_private = new xmlpp::Node(node);
      assert(0 && "Warning: new node of unknown type created");
      break;
    }
  }
}

//Called by libxml whenever it destroys something
//such as a node or attribute.
//This allows us to delete the C++ instance for the C instance, if any.
void on_libxml_destruct(xmlNode* node)
{
  bool bPrivateDeleted = false;
  if (node->type == XML_DTD_NODE)
  {
    xmlpp::Dtd* cppDtd = static_cast<xmlpp::Dtd*>(node->_private);
    if(cppDtd)
    {
      delete cppDtd;     
      bPrivateDeleted = true;
    }
  }
  else if (node->type == XML_DOCUMENT_NODE)
    // do nothing. See on_libxml_construct for an explanation
    ;
  else
  {
    xmlpp::Node* cppNode =  static_cast<xmlpp::Node*>(node->_private);
    if(cppNode)
    {
      delete cppNode;
      bPrivateDeleted = true;
    }
  }

  //This probably isn't necessary:
  if(bPrivateDeleted)
    node->_private = 0;
}

} //anonymous namespace

namespace xmlpp
{

Document::Init::Init()
{
   xmlInitParser(); //Not always necessary, but necessary for thread safety.
   xmlRegisterNodeDefault(on_libxml_construct);
   xmlDeregisterNodeDefault(on_libxml_destruct);
   xmlThrDefRegisterNodeDefault(on_libxml_construct);
   xmlThrDefDeregisterNodeDefault(on_libxml_destruct);
}

Document::Init Document::init_;

Document::Document(const Glib::ustring& version)
  : impl_(xmlNewDoc((const xmlChar*)version.c_str()))
{
  impl_->_private = this;
}

Document::Document(xmlDoc* doc)
  : impl_(doc)
{
  impl_->_private = this;
}

Document::~Document()
{
  xmlFreeDoc(impl_);
}

Glib::ustring Document::get_encoding() const
{
  Glib::ustring encoding;
  if(impl_->encoding)
    encoding = (const char*)impl_->encoding;
    
  return encoding;
}

Dtd* Document::get_internal_subset() const
{
  xmlDtd* dtd = xmlGetIntSubset(impl_);
  if(!dtd)
    return 0;
    
  if(!dtd->_private)
    dtd->_private = new Dtd(dtd);
    
  return reinterpret_cast<Dtd*>(dtd->_private);
}

void Document::set_internal_subset(const Glib::ustring& name,
                                   const Glib::ustring& external_id,
                                   const Glib::ustring& system_id)
{
  xmlDtd* dtd = xmlCreateIntSubset(impl_,
				   (const xmlChar*)name.c_str(),
				   external_id.empty() ? (const xmlChar*)NULL : (const xmlChar*)external_id.c_str(),
				   system_id.empty() ? (const xmlChar*)NULL : (const xmlChar*)system_id.c_str());
           
  if (dtd && !dtd->_private)
    dtd->_private = new Dtd(dtd);
}

Element* Document::get_root_node() const
{
  xmlNode* root = xmlDocGetRootElement(impl_);
  if(root == 0)
    return 0;
  else
    return reinterpret_cast<Element*>(root->_private);
}

Element* Document::create_root_node(const Glib::ustring& name,
                                    const Glib::ustring& ns_uri,
                                    const Glib::ustring& ns_prefix)
{
  xmlNode* node = xmlNewDocNode(impl_, 0, (const xmlChar*)name.c_str(), 0);
  xmlDocSetRootElement(impl_, node);

  Element* element = get_root_node();

  if( !ns_uri.empty() )
  {
    element->set_namespace_declaration(ns_uri, ns_prefix);
    element->set_namespace(ns_prefix);
  }

  return element;
}

Element* Document::create_root_node_by_import(const Node* node,
					      bool recursive)
{
  //Create the node, by copying:
  xmlNode* imported_node = xmlDocCopyNode(const_cast<xmlNode*>(node->cobj()), impl_, recursive);
  if (!imported_node)
    throw exception("Unable to import node");

  xmlDocSetRootElement(impl_, imported_node);

  return get_root_node();
}

CommentNode* Document::add_comment(const Glib::ustring& content)
{
  xmlNode* node = xmlNewComment((const xmlChar*)content.c_str());
  if(!node)
    throw internal_error("Cannot create comment node");
  xmlAddChild( (xmlNode*)impl_, node);
  return static_cast<CommentNode*>(node->_private);
}

void Document::write_to_file(const Glib::ustring& filename, const Glib::ustring& encoding)
{
  do_write_to_file(filename, encoding, false);
}

void Document::write_to_file_formatted(const Glib::ustring& filename, const Glib::ustring& encoding)
{
  do_write_to_file(filename, encoding, true);
}

Glib::ustring Document::write_to_string(const Glib::ustring& encoding)
{
  return do_write_to_string(encoding, false);
}

Glib::ustring Document::write_to_string_formatted(const Glib::ustring& encoding)
{
  return do_write_to_string(encoding, true);
}

void Document::write_to_stream(std::ostream& output, const Glib::ustring& encoding)
{
  do_write_to_stream(output, encoding.empty()?get_encoding():encoding, false);
}

void Document::write_to_stream_formatted(std::ostream& output, const Glib::ustring& encoding)
{
  do_write_to_stream(output, encoding.empty()?get_encoding():encoding, true);
}

void Document::do_write_to_file(
    const Glib::ustring& filename,
    const Glib::ustring& encoding,
    bool format)
{
  KeepBlanks k(KeepBlanks::Default);
  xmlIndentTreeOutput = format?1:0;
  int result = 0;

  result = xmlSaveFormatFileEnc(filename.c_str(), impl_, encoding.empty()?NULL:encoding.c_str(), format?1:0);

  if(result == -1)
    throw exception("do_write_to_file() failed.");
}

Glib::ustring Document::do_write_to_string(
    const Glib::ustring& encoding,
    bool format)
{
  KeepBlanks k(KeepBlanks::Default);
  xmlIndentTreeOutput = format?1:0;
  xmlChar* buffer = 0;
  int length = 0;

  xmlDocDumpFormatMemoryEnc(impl_, &buffer, &length, encoding.empty()?NULL:encoding.c_str(), format?1:0);

  if(!buffer)
    throw exception("do_write_to_string() failed.");

  // Create a Glib::ustring copy of the buffer
  Glib::ustring result((char*)buffer, length);
  // Deletes the original buffer
  xmlFree(buffer);
  // Return a copy of the string
  return result;
}

void Document::do_write_to_stream(std::ostream& output, const Glib::ustring& encoding, bool format)
{
  // TODO assert document encoding is UTF-8 if encoding is different than UTF-8
  OStreamOutputBuffer buffer(output, encoding);
  xmlSaveFormatFileTo(buffer.cobj(), impl_, encoding.c_str(), format?1:0);
}

void Document::set_entity_declaration(const Glib::ustring& name, XmlEntityType type,
                              const Glib::ustring& publicId, const Glib::ustring& systemId,
                              const Glib::ustring& content)
{
  xmlAddDocEntity( impl_, (const xmlChar*) name.c_str(), type, 
    (const xmlChar*) publicId.c_str(), (const xmlChar*) systemId.c_str(),
    (const xmlChar*) content.c_str() );
}

_xmlEntity* Document::get_entity(const Glib::ustring& name)
{
  return xmlGetDocEntity(impl_, (const xmlChar*) name.c_str());
}

_xmlDoc* Document::cobj()
{
  return impl_;
}

const _xmlDoc* Document::cobj() const
{
  return impl_;
}

} //namespace xmlpp

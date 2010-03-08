/* schema.cc
 * libxml++ and this file are copyright (C) 2000 by Ari Johnson, and
 * are covered by the GNU Lesser General Public License, which should be
 * included with libxml++ as the file COPYING.
 */

#include <libxml++/schema.h>

#include <libxml/tree.h>
#include <libxml/xmlschemas.h>
#include <libxml/xmlschemastypes.h>

namespace xmlpp
{
  
Schema::Schema(_xmlSchema* schema)
: impl_(schema)
, embedded_doc_(false)
{
  schema->_private = this;
}

Schema::Schema(Document* document, bool embed)
: impl_(0)
, embedded_doc_(false)
{
  set_document(document, embed);
}

Schema::~Schema()
{
  release_underlying();
}

void Schema::set_document(Document* document, bool embed)
{
  release_underlying();

  xmlSchemaParserCtxtPtr context = xmlSchemaNewDocParserCtxt( document->cobj() );
  impl_ = xmlSchemaParse( context );
#ifdef LIBXMLCPP_EXCEPTIONS_ENABLED
  if ( !impl_ )
   throw parse_error("Schema could not be parsed");
#endif
  impl_->_private = this;
  embedded_doc_ = embed;
  xmlSchemaFreeParserCtxt( context );
}

Glib::ustring Schema::get_name() const
{
  return (char*)impl_->name;
}

Glib::ustring Schema::get_target_namespace() const
{
  return (char*)impl_->targetNamespace;
}

Glib::ustring Schema::get_version() const
{
  return (char*)impl_->version;
}

void Schema::release_underlying()
{
  if(embedded_doc_ && impl_ && impl_->doc->_private)
  {
    delete (Document*) impl_->doc->_private;
    embedded_doc_ = false;
  }

  if(impl_)
  {
    xmlSchemaFree(impl_);
    impl_ = 0;
  }
}

Document* Schema::get_document()
{
  if(impl_)
    return (Document*) impl_->doc->_private;
  else
    return 0;
}

const Document* Schema::get_document()const
{
  if(impl_)
    return (Document*) impl_->doc->_private;
  else
    return 0;
}

_xmlSchema* Schema::cobj()
{
  return impl_;
}

const _xmlSchema* Schema::cobj() const
{
  return impl_;
}

} //namespace xmlpp

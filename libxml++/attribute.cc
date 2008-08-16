/* attribute.cc
 * libxml++ and this file are copyright (C) 2000 by Ari Johnson, and
 * are covered by the GNU Lesser General Public License, which should be
 * included with libxml++ as the file COPYING.
 */

#include "libxml++/attribute.h"

#include <libxml/tree.h>

namespace xmlpp
{

Attribute::Attribute(xmlNode* node)
  : Node(node)
{
}

Attribute::~Attribute()
{
}

Glib::ustring Attribute::get_name() const
{
  return cobj()->name ? (char*)cobj()->name : Glib::ustring();
}

Glib::ustring Attribute::get_value() const
{
  const xmlChar* ns_uri = NULL;
  if(cobj()->ns)
    ns_uri = cobj()->ns->href;

  xmlChar *value = xmlGetNsProp(cobj()->parent, cobj()->name, ns_uri);
  const Glib::ustring retn = value ? (char*)value : Glib::ustring();
  xmlFree(value);
  return retn;
}

void Attribute::set_value(const Glib::ustring& value)
{
  xmlSetProp(cobj()->parent, cobj()->name, (xmlChar*)value.c_str());
}

xmlAttr* Attribute::cobj()
{
  // yes, this does what it looks like: it takes an xmlNode pointer
  // and *reinterprets* it as an xmlAttr pointer
  // -stefan
  return reinterpret_cast<xmlAttr*>(Node::cobj());
}

const xmlAttr* Attribute::cobj() const
{
  // yes, this does what it looks like: it takes an xmlNode pointer
  // and *reinterprets* it as an xmlAttr pointer
  // -stefan
  return reinterpret_cast<const xmlAttr*>(Node::cobj());
}

} //namespace xmlpp





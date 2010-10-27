/* xml++.cc
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

std::string Attribute::get_name() const
{
  return cobj()->name ? (char*)cobj()->name : "";
}

std::string Attribute::get_value() const
{
  xmlChar *value = xmlGetProp(cobj()->parent, cobj()->name);
  std::string retn = value ? (char *)value : "";
  xmlFree(value);
  return retn;
}

void Attribute::set_value(const std::string& value)
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





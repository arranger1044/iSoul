/* attributenode.cc
 * libxml++ and this file are copyright (C) 2000 by Ari Johnson, and
 * are covered by the GNU Lesser General Public License, which should be
 * included with libxml++ as the file COPYING.
 */

#include "libxml++/attributenode.h"

#include <libxml/tree.h>

namespace xmlpp
{

AttributeNode::AttributeNode(xmlNode* node)
  : Attribute(node)
{
}

AttributeNode::~AttributeNode()
{
}

} //namespace xmlpp

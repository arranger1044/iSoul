/* attribute.h
 * libxml++ and this file are copyright (C) 2000 by Ari Johnson, and
 * are covered by the GNU Lesser General Public License, which should be
 * included with libxml++ as the file COPYING.
 */

#ifndef __LIBXMLPP_ATTRIBUTE_H
#define __LIBXMLPP_ATTRIBUTE_H


#include <glibmm/ustring.h>

#include <libxml++/nodes/node.h>

#ifndef DOXYGEN_SHOULD_SKIP_THIS
extern "C" {
  struct _xmlAttr;
}
#endif //#ifndef DOXYGEN_SHOULD_SKIP_THIS

namespace xmlpp
{

/** Represents XML Node attributes.
 *
 */
class Attribute : public Node
{
public:
  explicit Attribute(_xmlNode* node);
  virtual ~Attribute();
  
  Glib::ustring get_name() const;
  Glib::ustring get_value() const;
  void set_value(const Glib::ustring& value);

  ///Access the underlying libxml implementation.
  _xmlAttr* cobj();

  ///Access the underlying libxml implementation.
  const _xmlAttr* cobj() const;
};

} // namespace xmlpp

#endif //__LIBXMLPP_ATTRIBUTE_H


/* libxml++.h
 * libxml++ and this file are copyright (C) 2000 by Ari Johnson, and
 * are covered by the GNU Lesser General Public License, which should be
 * included with libxml++ as the file COPYING.
 */

#ifndef __LIBXMLCPP_H
#define __LIBXMLCPP_H

/** @mainpage libxml++ Reference Manual
 *
 * @section description Description
 *
 * libxml++ is a C++ wrapper for the libxml2 XML parser library. libxml2 and
 * glibmm are required. libxml++ presents a simple C++-like API that can
 * achieve common tasks with less code.
 *
 * @section use Use
 *
 * To use libxml++ in your application, include one of the header files. A
 * @c pkg-config file is provided to simplify compilation.
 */
#include <libxml++/exceptions/internal_error.h>
#include <libxml++/exceptions/parse_error.h>
#include <libxml++/parsers/domparser.h>
#include <libxml++/parsers/saxparser.h>
#include <libxml++/parsers/textreader.h>
#include <libxml++/nodes/node.h>
#include <libxml++/nodes/commentnode.h>
#include <libxml++/nodes/element.h>
#include <libxml++/nodes/entityreference.h>
#include <libxml++/nodes/textnode.h>
#include <libxml++/attribute.h>
#include <libxml++/document.h>
#include <libxml++/validators/validator.h>
#include <libxml++/validators/dtdvalidator.h>
#include <libxml++/validators/schemavalidator.h>

#endif //__LIBXMLCPP_H

// -*- C++ -*-

/* myparser.h
 *
 * Copyright (C) 2002 The libxml++ development team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#ifndef __LIBXMLPP_EXAMPLES_MYPARSER_H
#define __LIBXMLPP_EXAMPLES_MYPARSER_H

#include <libxml++/libxml++.h>

class MyException: public xmlpp::exception
{
  public:
    MyException();
    virtual ~MyException() throw ();
    virtual void Raise() const;
    virtual xmlpp::exception * Clone() const;
};

class MySaxParser : public xmlpp::SaxParser
{
  public:
    MySaxParser();
    virtual ~MySaxParser();

  protected:
    //overrides:
    virtual void on_start_document();
    virtual void on_end_document();
    virtual void on_start_element(const std::string& name,
                                  const AttributeList &properties);
    virtual void on_end_element(const std::string& name);
    virtual void on_characters(const std::string& characters);
    virtual void on_comment(const std::string& text);
    virtual void on_warning(const std::string& text);
    virtual void on_error(const std::string& text);
    virtual void on_fatal_error(const std::string& text);
};


#endif //__LIBXMLPP_EXAMPLES_MYPARSER_H

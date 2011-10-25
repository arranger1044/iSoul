// -*- C++ -*-

/* myparser.cc
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

#include "myparser.h"
#include <glibmm/convert.h> //For Glib::ConvertError

#include <iostream>

MySaxParser::MySaxParser()
  : xmlpp::SaxParser()
{
}

MySaxParser::~MySaxParser()
{
}

#ifdef LIBXMLCPP_EXCEPTIONS_ENABLED
void MySaxParser::on_start_document()
{
  std::cout << "on_start_document()" << std::endl;
}

void MySaxParser::on_end_document()
{
  std::cout << "on_end_document()" << std::endl;
}

void MySaxParser::on_start_element(const Glib::ustring& name,
                                   const AttributeList& attributes)
{
  std::cout << "node name=" << name << std::endl;

  // Print attributes:
  for(xmlpp::SaxParser::AttributeList::const_iterator iter = attributes.begin(); iter != attributes.end(); ++iter)
  {
    try
    {
      std::cout << "  Attribute name=" << iter->name << std::endl;
    }
    catch(const Glib::ConvertError& ex)
    {
      std::cerr << "MySaxParser::on_start_element(): Exception caught while converting name for std::cout: " << ex.what() << std::endl;
    }

    try
    {
      std::cout << "    , value= " << iter->value << std::endl;
    }
    catch(const Glib::ConvertError& ex)
    {
      std::cerr << "MySaxParser::on_start_element(): Exception caught while converting value for std::cout: " << ex.what() << std::endl;
    }
  }
}

void MySaxParser::on_end_element(const Glib::ustring& /* name */)
{
  std::cout << "on_end_element()" << std::endl;
}

void MySaxParser::on_characters(const Glib::ustring& text)
{
  try
  {
    std::cout << "on_characters(): " << text << std::endl;
  }
  catch(const Glib::ConvertError& ex)
  {
    std::cerr << "MySaxParser::on_characters(): Exception caught while converting text for std::cout: " << ex.what() << std::endl;
  }
}

void MySaxParser::on_comment(const Glib::ustring& text)
{
  try
  {
    std::cout << "on_comment(): " << text << std::endl;
  }
  catch(const Glib::ConvertError& ex)
  {
    std::cerr << "MySaxParser::on_comment(): Exception caught while converting text for std::cout: " << ex.what() << std::endl;
  }
}

void MySaxParser::on_warning(const Glib::ustring& text)
{
  try
  {
    std::cout << "on_warning(): " << text << std::endl;
  }
  catch(const Glib::ConvertError& ex)
  {
    std::cerr << "MySaxParser::on_warning(): Exception caught while converting text for std::cout: " << ex.what() << std::endl;
  }
}

void MySaxParser::on_error(const Glib::ustring& text)
{
  try
  {
    std::cout << "on_error(): " << text << std::endl;
  }
  catch(const Glib::ConvertError& ex)
  {
    std::cerr << "MySaxParser::on_error(): Exception caught while converting text for std::cout: " << ex.what() << std::endl;
  }
}

void MySaxParser::on_fatal_error(const Glib::ustring& text)
{
  try
  {
    std::cout << "on_fatal_error(): " << text << std::endl;
  }
  catch(const Glib::ConvertError& ex)
  {
    std::cerr << "MySaxParser::on_characters(): Exception caught while converting value for std::cout: " << ex.what() << std::endl;
  }
}
#endif

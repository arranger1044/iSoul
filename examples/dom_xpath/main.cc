// -*- C++ -*-

/* main.cc
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

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <libxml++/libxml++.h>

#include <iostream>


void xpath_test(const xmlpp::Node* node, const Glib::ustring& xpath)
{
  std::cout << std::endl; //Separate tests by an empty line.
  std::cout << "searching with xpath '" << xpath << "' in root node: " << std::endl;

  xmlpp::NodeSet set = node->find(xpath);
  
  std::cout << set.size() << " nodes have been found:" << std::endl;

  //Print the structural paths:
  for(xmlpp::NodeSet::iterator i = set.begin(); i != set.end(); ++i)
  {
    std::cout << " " << (*i)->get_path() << std::endl;
  }
}

int main(int argc, char* argv[])
{
  Glib::ustring filepath;
  if(argc > 1 )
    filepath = argv[1]; //Allow the user to specify a different XML file to parse.
  else
    filepath = "example.xml";

  try
  {
    xmlpp::DomParser parser(filepath);
    if(parser)
    {
      const xmlpp::Node* root = parser.get_document()->get_root_node(); //deleted by DomParser.

      if(root)
      {
        // Find all sections, no matter where:
        xpath_test(root, "//section");

        // Find the title node (if there is one):
        xpath_test(root, "title");

        std::cout << std::endl;

        // And finally test whether intra-document links are well-formed.
        // To be well-formed, the 'linkend' attribute must refer to
        // an element in terms of its 'id'.
        //
        // Find out whether there are linkend attributes that don't have
        // corresponding 'id's
        std::cout << "searching for unresolved internal references "
                  << "(see docbook manual):" << std::endl;

        xpath_test(root, "//xref/@linkend");
      }
    }
  }
  catch(const std::exception& ex)
  {
    std::cout << "Exception caught: " << ex.what() << std::endl;
  }

  return 0;
}


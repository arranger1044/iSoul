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

void print_indentation(unsigned int indentation)
{
  for(unsigned int i = 0; i < indentation; ++i)
    std::cout << " ";
}

void print_node(const xmlpp::Node* node, unsigned int indentation = 0)
{
  std::cout << std::endl; //Separate nodes by an empty line.
  
  const xmlpp::ContentNode* nodeContent = dynamic_cast<const xmlpp::ContentNode*>(node);
  const xmlpp::TextNode* nodeText = dynamic_cast<const xmlpp::TextNode*>(node);
  const xmlpp::CommentNode* nodeComment = dynamic_cast<const xmlpp::CommentNode*>(node);

  if(nodeText && nodeText->is_white_space()) //Let's ignore the indenting - you don't always want to do this.
    return;
    
  Glib::ustring nodename = node->get_name();

  if(!nodeText && !nodeComment && !nodename.empty()) //Let's not say "name: text".
  {
    print_indentation(indentation);
    std::cout << "Node name = " << node->get_name() << std::endl;
    std::cout << "Node name = " << nodename << std::endl;
  }
  else if(nodeText) //Let's say when it's text. - e.g. let's say what that white space is.
  {
    print_indentation(indentation);
    std::cout << "Text Node" << std::endl;
  }

  //Treat the various node types differently: 
  if(nodeText)
  {
    print_indentation(indentation);
    std::cout << "text = \"" << nodeText->get_content() << "\"" << std::endl;
  }
  else if(nodeComment)
  {
    print_indentation(indentation);
    std::cout << "comment = " << nodeComment->get_content() << std::endl;
  }
  else if(nodeContent)
  {
    print_indentation(indentation);
    std::cout << "content = " << nodeContent->get_content() << std::endl;
  }
  else if(const xmlpp::Element* nodeElement = dynamic_cast<const xmlpp::Element*>(node))
  {
    //A normal Element node:

    //line() works only for ElementNodes.
    print_indentation(indentation);
    std::cout << "     line = " << node->get_line() << std::endl;

    //Print attributes:
    const xmlpp::Element::AttributeList& attributes = nodeElement->get_attributes();
    for(xmlpp::Element::AttributeList::const_iterator iter = attributes.begin(); iter != attributes.end(); ++iter)
    {
      const xmlpp::Attribute* attribute = *iter;
      print_indentation(indentation);
      std::cout << "  Attribute " << attribute->get_name() << " = " << attribute->get_value() << std::endl;
    }

    const xmlpp::Attribute* attribute = nodeElement->get_attribute("title");
    if(attribute)
    {
      std::cout << "title found: =" << attribute->get_value() << std::endl;
      
    }
  }
  
  if(!nodeContent)
  {
    //Recurse through child nodes:
    xmlpp::Node::NodeList list = node->get_children();
    for(xmlpp::Node::NodeList::iterator iter = list.begin(); iter != list.end(); ++iter)
    {
      print_node(*iter, indentation + 2); //recursive
    }
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
    xmlpp::DomParser parser;
    parser.set_validate();
    parser.set_substitute_entities(); //We just want the text to be resolved/unescaped automatically.
    parser.parse_file(filepath);
    if(parser)
    {
      //Walk the tree:
      const xmlpp::Node* pNode = parser.get_document()->get_root_node(); //deleted by DomParser.
      print_node(pNode);
    }
  }
  catch(const std::exception& ex)
  {
    std::cout << "Exception caught: " << ex.what() << std::endl;
  }

  return 0;
}


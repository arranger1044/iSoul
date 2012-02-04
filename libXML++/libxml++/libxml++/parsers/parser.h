/* parser.h
 * libxml++ and this file are copyright (C) 2000 by Ari Johnson, and
 * are covered by the GNU Lesser General Public License, which should be
 * included with libxml++ as the file COPYING.
 */

#ifndef __LIBXMLPP_PARSER_H
#define __LIBXMLPP_PARSER_H

#ifdef _MSC_VER //Ignore warnings about the Visual C++ Bug, where we can not do anything
#pragma warning (disable : 4786)
#endif

#include <libxml++/nodes/element.h>
#include <libxml++/exceptions/validity_error.h>
#include <libxml++/exceptions/internal_error.h>

#include <istream>
#include <cstdarg> //For va_list.

#ifndef DOXYGEN_SHOULD_SKIP_THIS
extern "C" {
  struct _xmlParserCtxt;
}
#endif //DOXYGEN_SHOULD_SKIP_THIS

namespace xmlpp {

/** XML parser.
 *
 */
class Parser : NonCopyable
{
public:
  Parser();
  virtual ~Parser();

  typedef unsigned int size_type;

  /** By default, the parser will not validate the XML file.
   * @param val Whether the document should be validated.
   */
  virtual void set_validate(bool val = true);

  /** See set_validate()
   * @returns Whether the parser will validate the XML file.
   */
  virtual bool get_validate() const;

  /** Set whether the parser will automatically substitute entity references with the text of the entities' definitions.
   * For instance, this affects the text returned by ContentNode::get_content().
   * By default, the parser will not substitute entities, so that you do not lose the entity reference information.
   * @param val Whether entities will be substitued.
   */
  virtual void set_substitute_entities(bool val = true);

  /** See set_substitute_entities().
   * @returns Whether entities will be substituted during parsing.
   */
  virtual bool get_substitute_entities() const;

  /** Set whether the parser will collect and throw error and warning messages.
   * If messages are collected, they are included in an exception thrown at the
   * end of parsing. If the messages are not collected, they are written on
   * stderr. The messages written on stderr are slightly different, and may
   * be preferred in a program started from the command-line.
   *
   * The default, if set_throw_messages() is not called, is to collect and throw
   * only messages from validation. Other messages are written to stderr.
   * This is for backward compatibility, and may change in the future.
   * @param val Whether messages will be collected and thrown in an exception.
   */
  void set_throw_messages(bool val = true);

  /** See set_throw_messages().
   * @returns Whether messages will be collected and thrown in an exception.
   *          The default with only validation messages thrown is returned as false.
   */
  bool get_throw_messages() const;
  
  /** Parse an XML document from a file.
   * @throw exception
   * @param filename The path to the file.
   */
  virtual void parse_file(const Glib::ustring& filename) = 0;

  //TODO: In a future ABI-break, add a virtual void parse_memory_raw(const unsigned char* contents, size_type bytes_count);
  
  /** Parse an XML document from a string.
   * @throw exception
   * @param contents The XML document as a string.
   */
  virtual void parse_memory(const Glib::ustring& contents) = 0;

  /** Parse an XML document from a stream.
   * @throw exception
   * @param in The stream.
   */
  virtual void parse_stream(std::istream& in) = 0;

  //TODO: Add stop_parser()/stop_parsing(), wrapping xmlStopParser()?

protected:
  virtual void initialize_context();
  virtual void release_underlying();

  //TODO: In a future ABI-break, add these virtual functions.
  //virtual void on_parser_error(const Glib::ustring& message);
  //virtual void on_parser_warning(const Glib::ustring& message);
  virtual void on_validity_error(const Glib::ustring& message);
  virtual void on_validity_warning(const Glib::ustring& message);

  virtual void handleException(const exception& e);
  virtual void check_for_exception();
  //TODO: In a future API/ABI-break, change the name of this function to
  // something more appropriate, such as check_for_error_and_warning_messages.
  virtual void check_for_validity_messages();
  
  static void callback_parser_error(void* ctx, const char* msg, ...);
  static void callback_parser_warning(void* ctx, const char* msg, ...);
  static void callback_validity_error(void* ctx, const char* msg, ...);
  static void callback_validity_warning(void* ctx, const char* msg, ...);

  enum MsgType
  {
    MsgParserError,
    MsgParserWarning,
    MsgValidityError,
    MsgValidityWarning
  };

  static void callback_error_or_warning(MsgType msg_type, void* ctx,
                                        const char* msg, va_list var_args);

  _xmlParserCtxt* context_;
  exception* exception_;
  //TODO: In a future ABI-break, add these members.
  //bool throw_messages_;
  //Glib::ustring parser_error_;
  //Glib::ustring parser_warning_;
  Glib::ustring validate_error_;
  Glib::ustring validate_warning_; //Built gradually - used in an exception at the end of parsing.

  bool validate_;
  bool substitute_entities_;
};

} // namespace xmlpp

#endif //__LIBXMLPP_PARSER_H


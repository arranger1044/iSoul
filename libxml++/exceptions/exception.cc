#include "exception.h"

namespace xmlpp {
  
exception::exception(const Glib::ustring& message)
: message_(message)
{
}

exception::~exception() throw()
{}

const char* exception::what() const throw()
{
  return message_.c_str();
}

void exception::Raise() const
{
  throw *this;
}

exception * exception::Clone() const
{
  return new exception(*this);
}

} //namespace xmlpp


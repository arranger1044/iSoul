
#ifndef _GLIBMM_USTRING_H
#define _GLIBMM_USTRING_H 1

#include <string>

#define G_STRFUNC __FUNCTION__

namespace Glib {
	class ustring : public std::string {
	public:
		ustring(const std::string &s = std::string()) : std::string(s) {}
		ustring(const char *s) : std::string(s) {}
		ustring(const char *begin, const char *end) : std::string(begin, end) {}
		
		inline size_t bytes(void) const {
			return size();
		}
	};
}

#endif /* _GLIBMM_USTRING_H */

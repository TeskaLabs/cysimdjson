#include "simdjson.h"
using namespace simdjson;

inline int get(ondemand::document & document, const std::string & key, ondemand::value & value) {
	auto error = document[key].get(value);
	if (error) {
		return -1;
	}
	return 0;
}


inline int get_string_view(ondemand::value & value, std::string_view & dst) {
	auto error = value.get_string().get(dst);
	if (error) {
		std::cerr << error << std::endl;
		return -1;
	}
	return 0;
}


inline std::string to_string(std::string_view sv) {
	//TODO: This creates a string copy
	return std::string(sv);
}

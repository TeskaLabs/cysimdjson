// We have to include "Python.h" b/c otherwise parser.parse() crashes
// Assumption is that Python.h sets some definition that is used by `simdjson.h`
// TODO: Find what `ifdef` is set and set that without `Python.h`
#include "Python.h"

#include "simdjson/simdjson.h"

extern "C" {
#include "cysimdjsonc.h"
}

void * cysimdjson_parser_new(void) {
	simdjson::dom::parser * parser = new simdjson::dom::parser();
	void * p = static_cast<void*>(parser);
	return p;
}

void cysimdjson_parser_del(void * p) {
	assert(p != NULL);
	simdjson::dom::parser * parser = static_cast<simdjson::dom::parser *>(p);
	delete parser;
}


const size_t cysimdjson_element_sizeof(void) {
	return sizeof(simdjson::dom::element);
}


bool cysimdjson_parser_parse(void * p, void * memory, const uint8_t * data, size_t datalen) {
	simdjson::dom::parser * parser = static_cast<simdjson::dom::parser *>(p);

	try {
		// Initialize the element at the memory provided by a caller
		// See: https://www.geeksforgeeks.org/placement-new-operator-cpp/
		// `memory` is a pointer to a pre-allocated memory space with >= cysimdjson_element_sizeof() bytes
		simdjson::dom::element * element = new(memory) simdjson::dom::element();

		// Parse the JSON
		auto err = parser->parse(
			data, datalen,
			true // Create a copy if needed (TODO: this may be optimized eventually to save data copy)
		).get(*element);

		if (err) {
			// Likely syntax error in JSON
			return true;
		}

	} catch (const std::bad_alloc& e) {
		// Error when allocating memory
		return true;
	}
	catch (...) {
		return true;
	}

	// No error
	return false;
}


bool cysimdjson_element_get_str(const char * attrname, size_t attrlen, void * e, char ** output, size_t * outputlen) {
	simdjson::dom::element * element = static_cast<simdjson::dom::element *>(e);
	std::string_view pointer = std::string_view(attrname, attrlen);

	std::string_view result;
	auto err = element->at_pointer(pointer).get(result);
	if (err) {
		return true;
	}

	*output = (char *)result.data();
	*outputlen = result.size();
	return false;
}

bool cysimdjson_element_get_int64_t(const char * attrname, size_t attrlen, void * e, int64_t * output) {

	simdjson::dom::element * element = static_cast<simdjson::dom::element *>(e);
	std::string_view pointer = std::string_view(attrname, attrlen);

	int64_t result;
	auto err = element->at_pointer(pointer).get(result);
	if (err) {
		return true;
	}

	*output = result;
	return false;
}

bool cysimdjson_element_get_uint64_t(const char * attrname, size_t attrlen, void * e, uint64_t * output) {
	simdjson::dom::element * element = static_cast<simdjson::dom::element *>(e);
	std::string_view pointer = std::string_view(attrname, attrlen);

	uint64_t result;
	auto err = element->at_pointer(pointer).get(result);
	if (err) {
		return true;
	}

	*output = result;
	return false;
}

bool cysimdjson_element_get_bool(const char * attrname, size_t attrlen, void * e, bool * output) {
	simdjson::dom::element * element = static_cast<simdjson::dom::element *>(e);
	std::string_view pointer = std::string_view(attrname, attrlen);

	bool result;
	auto err = element->at_pointer(pointer).get(result);
	if (err) {
		return true;
	}

	*output = result;
	return false;
}

bool cysimdjson_element_get_double(const char * attrname, size_t attrlen, void * e, double * output) {
	simdjson::dom::element * element = static_cast<simdjson::dom::element *>(e);
	std::string_view pointer = std::string_view(attrname, attrlen);

	double result;
	auto err = element->at_pointer(pointer).get(result);
	if (err) {
		return true;
	}

	*output = result;
	return false;
}

char cysimdjson_element_get_type(const char * attrname, size_t attrlen, void * e) {
	simdjson::dom::element * element = static_cast<simdjson::dom::element *>(e);
	std::string_view pointer = std::string_view(attrname, attrlen);

	simdjson::dom::element_type result;
	auto err = element->at_pointer(pointer).type().get(result);
	if (err) {
		return '\0';
	}

	switch (result) {
		case simdjson::dom::element_type::INT64: return 'i';
		case simdjson::dom::element_type::UINT64: return 'u';
		case simdjson::dom::element_type::STRING: return 's';
		case simdjson::dom::element_type::DOUBLE: return 'f';
		case simdjson::dom::element_type::BOOL: return 'B';
		case simdjson::dom::element_type::ARRAY: return 'A';
		case simdjson::dom::element_type::OBJECT: return 'O';
		case simdjson::dom::element_type::NULL_VALUE: return 'N';
	}

	return '?';
}

bool cysimdjson_element_get(const char * attrname, size_t attrlen, void * e, void * output_element) {
	simdjson::dom::element * element = static_cast<simdjson::dom::element *>(e);
	std::string_view pointer = std::string_view(attrname, attrlen);

	simdjson::dom::element * sub_element = new(output_element) simdjson::dom::element();

	auto err = element->at_pointer(pointer).get(*sub_element);
	if (err) {
		return true;
	}

	return false;

}

// This is here for an unit test
int cysimdjson_parser_test() {
	simdjson::dom::parser parser;
	simdjson::dom::object object;

	const char * jsond = R"({"key":"value"}     )";
	const size_t jsond_len = std::strlen(jsond);

	auto error = parser.parse(jsond, jsond_len).get(object);
	if (error) {
		return -1;
	}
	
	return 0;
}


size_t cysimdjson_minify(void * e, char * buffer, size_t buffer_size) {
	simdjson::dom::element * element = static_cast<simdjson::dom::element *>(e);
	std::string json_string = simdjson::minify(*element);

	if (json_string.size() < buffer_size) {
		std::strcpy(buffer, json_string.c_str());
		return json_string.size();
	} else {
		return 0; // The output JSON doesn't fit
	}
}

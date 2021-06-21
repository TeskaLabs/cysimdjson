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


size_t cysimdjson_element_sizeof(void) {
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


bool cysimdjson_element_get_str(const char * attrname, size_t attrlen, void * e, const char ** output, size_t * outputlen) {
	simdjson::dom::element * element = static_cast<simdjson::dom::element *>(e);
	std::string_view pointer = std::string_view(attrname, attrlen);

	std::string_view result;
	auto err = element->at_pointer(pointer).get(result);
	if (err) {
		return true;
	}

	*output = result.data();
	*outputlen = result.size();
	return false;
}


// This is here for an unit test
void cysimdjson_parser_test() {
	printf("cysimdjson_parser_test started ...\n");

	simdjson::dom::parser parser;
	simdjson::dom::object object;

	const char * jsond = R"({"key":"value"}     )";
	const size_t jsond_len = std::strlen(jsond);

	auto error = parser.parse(jsond, jsond_len).get(object);

	printf("cysimdjson_parser_test OK!\n");
}

#ifndef CYSIMDJSONAPI_H
#define CYSIMDJSONAPI_H

// This is API for C (not C++) level
// This header has to be C compliant

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

void * cysimdjson_parser_new(void);
void cysimdjson_parser_del(void * parser);

const size_t cysimdjson_element_sizeof(void);

// `element` is a pointer with pre-allocated buffer of the size=cysimdjson_element_sizeof()
bool cysimdjson_parser_parse(void * parser, void * element, const uint8_t * data, size_t datalen);

bool cysimdjson_element_get_str(const char * attrname, size_t attrlen, void * element, char ** output, size_t * outputlen);
bool cysimdjson_element_get_int64_t(const char * attrname, size_t attrlen, void * element, int64_t * output);
bool cysimdjson_element_get_uint64_t(const char * attrname, size_t attrlen, void * element, uint64_t * output);
bool cysimdjson_element_get_bool(const char * attrname, size_t attrlen, void * element, bool * output);
bool cysimdjson_element_get_double(const char * attrname, size_t attrlen, void * element, double * output);

char cysimdjson_element_get_type(const char * attrname, size_t attrlen, void * element);
bool cysimdjson_element_get(const char * attrname, size_t attrlen, void * element, void * output_element);

int cysimdjson_parser_test(void);

// Export element `e` as JSON into the "buffer" and returns the exported JSON size.
// If the "buffer_size" is too small, returns 0;
size_t cysimdjson_minify(void * element, char * buffer, size_t buffer_size);

#endif

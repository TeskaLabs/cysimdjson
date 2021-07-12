#ifndef CYSIMDJSONAPI_H
#define CYSIMDJSONAPI_H

// This is API for C (not C++) level
// This header has to be C compliant

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

void * cysimdjson_parser_new(void);
void cysimdjson_parser_del(void * parser);

size_t cysimdjson_element_sizeof(void);
bool cysimdjson_parser_parse(void * parser, void * memory, const uint8_t * data, size_t datalen);

bool cysimdjson_element_get_str(const char * attrname, size_t attrlen, void * element, char ** output, size_t * outputlen);
bool cysimdjson_element_get_int64_t(const char * attrname, size_t attrlen, void * e, int64_t * output);
bool cysimdjson_element_get_uint64_t(const char * attrname, size_t attrlen, void * e, uint64_t * output);
bool cysimdjson_element_get_bool(const char * attrname, size_t attrlen, void * e, bool * output);
bool cysimdjson_element_get_double(const char * attrname, size_t attrlen, void * e, double * output);

char cysimdjson_element_get_type(const char * attrname, size_t attrlen, void * e);

void cysimdjson_parser_test(void);

#endif

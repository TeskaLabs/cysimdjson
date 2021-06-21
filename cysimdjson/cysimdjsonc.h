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

bool cysimdjson_element_get_str(const char * attrname, size_t attrlen, void * element, const char ** output, size_t * outputlen);

void cysimdjson_parser_test(void);

#endif

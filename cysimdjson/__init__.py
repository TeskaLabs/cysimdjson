import os
import sys

# If the environment variable CYSIMDJSON_GLOBAL_DL is set to "1"
# then the compiled cysimdjson library is imported into a global symbol table
# It is needed to enable third party component to access cysimdjson C API

if sys.platform != 'win32':
	prev = sys.getdlopenflags()

try:
	if os.environ.get("CYSIMDJSON_GLOBAL_DL") == "1":
		if sys.platform != 'win32':
			sys.setdlopenflags(os.RTLD_GLOBAL | os.RTLD_NOW)

	from .cysimdjson import (
		JSONParser,
		JSONObject,
		JSONArray,
		JSONElement,
		addr_to_element,
		SIMDJSON_VERSION,
		MAXSIZE_BYTES,
		PADDING,
	)
finally:
	if sys.platform != 'win32':
		sys.setdlopenflags(prev)

__all__ = [
	"JSONParser",
	"JSONObject",
	"JSONArray",
	"JSONElement",
	"addr_to_element",
	"SIMDJSON_VERSION",
	"MAXSIZE_BYTES",
	"PADDING",
]

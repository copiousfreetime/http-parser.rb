/**
 * Copyright (c) 2009 Jeremy Hinegardner
 * All rights reserved.  See LICENSE and/or COPYING for details.
 *
 * vim: shiftwidth=4
 */

#ifndef __HTTP_PARSER_EXT_H___
#define __HTTP_PARSER_EXT_H___
#include "ruby.h"
#include "http_parser.h"
#include <string.h>

extern VALUE mHttp;                /* module Http */
extern VALUE cHttpParser;          /* class Http::Parser */
extern VALUE cHttpRequestParser;   /* class Http::RequestParser */
extern VALUE cHttpResponseParser;  /* class Http::ResponseParser */
extern VALUE eHttpParserError;     /* class Http::Parser::Error */

/*
 * constants
 */


/**
 * Methods for Parser
 */
VALUE hpe_alloc( VALUE klass );

/**
 * Methods for RequestParser
 */
VALUE hpe_request_parser_initialize( VALUE self );

/** 
 * Methods for ResponseParser
 */
VALUE hpe_response_parser_initialize( VALUE self );
#endif


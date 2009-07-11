/**
 * Copyright (c) 2009 Jeremy Hinegardner
 * All rights reserved.  See LICENSE and/or COPYING for details.
 *
 * vim: shiftwidth=4
 */

#include "ruby.h"
#include "http_parser.h"

/* free the http_parser memory */
void hpe_free( http_parser* parser )
{
    parser->data = NULL;
    xfree( parser );
    return;
}

/*
 * allocate the hpe_http_parser structure
 */
VALUE hpe_alloc( VALUE klass )
{
    http_parser *parser = xmalloc( sizeof( http_parser ));
    VALUE            obj;


    obj = Data_Wrap_Struct( klass, NULL, hpe_free, hpe_parser );
    return obj;
}

/*
 * call-seq:
 *   RequestParser.new
/*
 * Create a new HTTP Request parser.
 *
 */
static VALUE hpe_request_parser_initialize( VALUE self )
{
    http_parser *parser;

    Data_Get_Struct( self, http_parser, parser );
    http_parser_init( parser, HTTP_REQUEST );

    return self;
}

/*
 * call-seq:
 *   ResponseParser.new
/*
 * Create a new HTTP Response parser.
 *
 */
static VALUE hpe_response_parser_initialize( VALUE self )
{
    http_parser *parser;

    Data_Get_Struct( self, http_parser, parser );
    http_parser_init( parser, HTTP_RESPONSE );

    return self;
}


/*
 *
 */
void Init_http_parser_ext()
{
    VALUE mHttp               = rb_define_module( "Http" );
    VALUE cHttpParser         = rb_define_class_under( mHttp, "Parser", rb_cObject);
    VALUE cHttpRequestParser  = rb_define_class_under( mHttp, "RequestParser", cHttpParser );
    VALUE cHttpResponseParser = rb_define_class_under( mHttp, "ResponseParser", cHttpParser );

    /* Http::Parser */
    rb_define_method( cHttpParser, "status_code", 0 );
    rb_define_method( cHttpParser, "method", 0 );
    rb_define_method( cHttpParser, "transfer_encoding?", 0 );
    rb_define_method( cHttpParser, "version", 0 );
    rb_define_method( cHttpParser, "keep_alive?", 0 );
    rb_define_method( cHttpParser, "content_length?", 0 );


    /* Http::RequestParser */
    rb_define_alloc_func( cHttpRequestParser, hpe_alloc);
    rb_define_method( cHttpRequestParser, hpe_request_parser_initialize );

    /* Http::ResponseParser */
    rb_define_alloc_func( cHttpResponseParser, hpe_alloc);
    rb_define_method( cHttpResponseParser, hpe_response_parser_initialize );

}



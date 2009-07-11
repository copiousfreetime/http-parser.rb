/**
 * Copyright (c) 2009 Jeremy Hinegardner
 * All rights reserved.  See LICENSE and/or COPYING for details.
 *
 * vim: shiftwidth=4
 * vim: textwidth-72
 */

#include "http-parser_ext.h"

/* class defined here */
VALUE mHttp;                /* module Http */
VALUE cHttpParser;          /* class Http::Parser */
VALUE cHttpRequestParser;   /* class Http::RequestParser */
VALUE cHttpResponseParser;  /* class Http::ResponseParser */
VALUE eHttpParserError;     /* class Http::Parser::Error  */

/* generator for callback setter */
#define HPE_CALLBACK_SETTER(FOR,CB_TYPE)                              \
VALUE hpe_parser_##FOR( VALUE self, VALUE callable )                  \
{                                                                     \
    http_parser *parser;                                              \
    Data_Get_Struct( self, http_parser, parser );                     \
    if ( Qnil == callable ) {                                         \
        parser->FOR = NULL;                                           \
    } else {                                                          \
        parser->FOR = (http_##CB_TYPE)hpe_##FOR##_##CB_TYPE;          \
    }                                                                 \
}


/* generator for callback methods */
#define HPE_CALLBACK(FOR)                                              \
int hpe_##FOR##_cb( http_parser *parser )                              \
{                                                                      \
    VALUE rb_parser = (VALUE)parser->data;                             \
    VALUE callable  = rb_iv_get( rb_parser, "@" #FOR "_callback" );    \
                                                                       \
    if ( Qnil != callable ) {                                          \
        VALUE result = rb_funcall(callable, rb_intern("call"),         \
                                  1, rb_parser );                      \
        if ( ( Qfalse != result ) && ( Qnil != result ) ) {            \
            return true;                                               \
        }                                                              \
    }                                                                  \
    return false;                                                      \
};                                                                     \
HPE_CALLBACK_SETTER(FOR,cb)


#define HPE_DATA_CALLBACK(FOR)                                         \
int hpe_##FOR##_data_cb( http_parser *parser,                          \
                         const char *at, size_t length)                \
{                                                                      \
    VALUE rb_parser = (VALUE)parser->data;                             \
    VALUE callable  = rb_iv_get( rb_parser, "@" #FOR "_callback" );    \
                                                                       \
    if ( Qnil != callable ) {                                          \
        VALUE str    = rb_str_new( at, length );                       \
        VALUE result = rb_funcall(callable, rb_intern("call"),         \
                                  2, rb_parser, str );                 \
        if ( ( Qfalse != result ) && ( Qnil != result ) ) {            \
            return true;                                               \
        }                                                              \
    }                                                                  \
    return false;                                                      \
};                                                                     \
HPE_CALLBACK_SETTER(FOR,data_cb)

/* common callacks */
HPE_CALLBACK(on_message_begin);
HPE_DATA_CALLBACK(on_header_field);
HPE_DATA_CALLBACK(on_header_value);
HPE_CALLBACK(on_headers_complete);
HPE_DATA_CALLBACK(on_body);
HPE_CALLBACK(on_message_complete);

/* only used by Http::Request */
HPE_DATA_CALLBACK(on_path);
HPE_DATA_CALLBACK(on_query_string);
HPE_DATA_CALLBACK(on_uri);
HPE_DATA_CALLBACK(on_fragment);


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
    VALUE           obj;

    obj = Data_Wrap_Struct( klass, NULL, hpe_free, parser );
    return obj;
}

/*
 * call-seq:
 *   response_parser.status_code -> Integer
 *
 * Return the HTTP Status code of the response.
 *
 */
VALUE hpe_parser_status_code( VALUE self )
{
    http_parser *parser;
    VALUE       rc;

    Data_Get_Struct( self, http_parser, parser );
    rc = INT2FIX( parser->status_code );
    return rc;
}

/*
 * call-seq:
 *   request_parser.method -> String
 *
 * Return the HTTP Method used for the request.
 */
VALUE hpe_parser_method( VALUE self )
{
    http_parser *parser;

    Data_Get_Struct( self, http_parser, parser );
    switch ( parser->method ) {
    case HTTP_COPY:      return rb_mod_const_get( mHttp, "COPY" );      break;
    case HTTP_DELETE:    return rb_mod_const_get( mHttp, "DELETE" );    break;
    case HTTP_GET:       return rb_mod_const_get( mHttp, "GET" );       break;
    case HTTP_HEAD:      return rb_mod_const_get( mHttp, "HEAD" );      break;
    case HTTP_LOCK:      return rb_mod_const_get( mHttp, "LOCK" );      break;
    case HTTP_MKCOL:     return rb_mod_const_get( mHttp, "MKCOL");      break;
    case HTTP_MOVE:      return rb_mod_const_get( mHttp, "MOVE");       break;
    case HTTP_OPTIONS:   return rb_mod_const_get( mHttp, "OPTIONS");    break;
    case HTTP_POST:      return rb_mod_const_get( mHttp, "POST");       break;
    case HTTP_PROPFIND:  return rb_mod_const_get( mHttp, "PROPFIND");   break;
    case HTTP_PROPPATCH: return rb_mod_const_get( mHttp, "PROPPATCH" ); break;
    case HTTP_PUT:       return rb_mod_const_get( mHttp, "PUT");        break;
    case HTTP_TRACE:     return rb_mod_const_get( mHttp, "TRACE");      break;
    case HTTP_UNLOCK:    return rb_mod_const_get( mHttp, "UNLOCK");     break;
    default:
      rb_raise(eHttpParserError, "Invalid Request Method");
      break;
    }
}

/*
 * call-seq:
 *   parser.chunked_encoding? -> true of false
 *
 * Return if the request/reponse is chunked_encoding.
 *
 */
VALUE hpe_parser_chunked_encoding( VALUE self )
{
    http_parser *parser;
    VALUE        rc = Qfalse;

    Data_Get_Struct( self, http_parser, parser );
    if ( parser->transfer_encoding == HTTP_CHUNKED ) {
        rc = Qtrue;
    }

    return rc;
}

/*
 * call-seq:
 *   parser.version -> Version string
 *
 * Return the version string of the request/response being parsed.
 *
 */
VALUE hpe_parser_version( VALUE self )
{
    http_parser *parser;
    char         v[4];

    Data_Get_Struct( self, http_parser, parser );

    snprintf(v, 4, "%d.%d", parser->version_major, parser->version_minor );

    return rb_str_new2( v );
}


/*
 * call-seq:
 *   parser.keep_alive? -> true or false
 *
 * Does this request/response support keep_alive?
 *
 */
VALUE hpe_parser_keep_alive( VALUE self )
{
    http_parser *parser;

    Data_Get_Struct( self, http_parser, parser );

    if ( http_parser_should_keep_alive( parser ) ) {
        return Qtrue;
    } else {
        return Qfalse;
    }
}


/*
 * call-seq:
 *   parser.content_length -> Integer
 *
 * The content length of the body of the request/response being parsed.
 *
 */
VALUE hpe_parser_content_length( VALUE self )
{
    http_parser *parser;
    size_t       content_length;
    VALUE        rc;

    Data_Get_Struct( self, http_parser, parser );
    content_length = parser->content_length;
    rc = UULL2NUM( content_length );
   
    return rc;
}


/*
 * call-seq:
 *   parser.has_error? -> true or false
 *
 * Returns true or false if the parser has encountered and error or not.
 *
 */
VALUE hpe_parser_has_error( VALUE self )
{
    http_parser *parser;
    VALUE        rc;

    Data_Get_Struct( self, http_parser, parser );

    if ( http_parser_has_error( parser ) ){
        return Qtrue;
    } else {
        return Qfalse;
    }
}


/*
 * call-seq:
 *   parser.reset -> nil
 *
 * Reset the state of the parser to what it was upon initial
 * instantiation.  This resets the internal state machine and allows it
 * to be used again.
 *
 * Also be aware, that immediately following the +on_message_complete+
 * callback the Parser is also implicitly reset.
 *
 */
VALUE hpe_parser_reset( VALUE self )
{
    http_parser *parser;
    VALUE        rc;

    Data_Get_Struct( self, http_parser, parser );
    RESET_PARSER( parser );
    return Qnil;
}

/*
 * call-seq:
 *   parser.parse_chunk( String ) -> nil
 *
 * Parse the given hunk of data invoking the callbacks as appropriate.
 *
 * If an error is encountered, an exception is thrown.  If there is an
 * on_error callback registered, then an exception is NOT thrown, the
 * on_error callback is called.
 *
 */
VALUE hpe_parser_parse_chunk( VALUE self, VALUE chunk )
{
    http_parser *parser;
    VALUE       str = StringValue( chunk );

    Data_Get_Struct( self, http_parser, parser );
    http_parser_execute( parser, RSTRING_PTR(str), RSTRING_LEN(str) );

    if ( http_parser_has_error( parser ) ) {
        if ( 
    

/*
 * call-seq:
 *   RequestParser.new
 *
 * Create a new HTTP Request parser.
 *
 */
VALUE hpe_request_parser_initialize( VALUE self )
{
    http_parser *parser;

    Data_Get_Struct( self, http_parser, parser );
    http_parser_init( parser, HTTP_REQUEST );

    /* we use the data field in the parser to point to the Ruby Object
     * that wraps it
     */
    parser->data = (void*)self;

    return self;
}

/*
 * call-seq:
 *   ResponseParser.new
 *
 * Create a new HTTP Response parser.
 *
 */
VALUE hpe_response_parser_initialize( VALUE self )
{
    http_parser *parser;

    Data_Get_Struct( self, http_parser, parser );
    http_parser_init( parser, HTTP_RESPONSE );

    /* we use the data field in the parser to point to the Ruby Object
     * that wraps it.
     */
    parser->data = (void*)self;

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
    VALUE eHttpParserError    = rb_define_class_under( cHttpParser, "Error", rb_eStandardError );

    /* Http:: Constants */
    /* methods */
    rb_define_const( mHttp, "COPY"      ,rb_str_new2("COPY") );
    rb_define_const( mHttp, "DELETE"    ,rb_str_new2("DELETE") );
    rb_define_const( mHttp, "GET"       ,rb_str_new2("GET") );
    rb_define_const( mHttp, "HEAD"      ,rb_str_new2("HEAD") );
    rb_define_const( mHttp, "LOCK"      ,rb_str_new2("LOCK") );
    rb_define_const( mHttp, "MKCOL"     ,rb_str_new2("MKCOL") );
    rb_define_const( mHttp, "MOVE"      ,rb_str_new2("MOVE") );
    rb_define_const( mHttp, "OPTIONS"   ,rb_str_new2("OPTIONS") );
    rb_define_const( mHttp, "POST"      ,rb_str_new2("POST") );
    rb_define_const( mHttp, "PROPFIND"  ,rb_str_new2("PROPFIND") );
    rb_define_const( mHttp, "PROPPATCH" ,rb_str_new2("PROPPATCH") );
    rb_define_const( mHttp, "PUT"       ,rb_str_new2("PUT") );
    rb_define_const( mHttp, "TRACE"     ,rb_str_new2("TRACE") );
    rb_define_const( mHttp, "UNLOCK"    ,rb_str_new2("UNLOCK") );

    /* transer encodings */
    rb_define_const( mHttp, "IDENTITY" ,rb_str_new2("IDENTITY") );
    rb_define_const( mHttp, "CHUNKED"  ,rb_str_new2("CHUNKED") );


    /******************************************************************
     * Http::Parser 
    ******************************************************************/
    rb_define_method( cHttpParser, "chunked_encoding?" ,hpe_parser_chunked_encoding , 0 );
    rb_define_method( cHttpParser, "version"           ,hpe_parser_version          , 0 );
    rb_define_method( cHttpParser, "keep_alive?"       ,hpe_parser_keep_alive       , 0 );
    rb_define_method( cHttpParser, "content_length?"   ,hpe_parser_content_length   , 0 );
    rb_define_method( cHttpParser, "has_error?"        ,hpe_parser_has_error        , 0 );
    rb_define_method( cHttpParser, "reset"             ,hpe_parser_reset            , 0 );
    rb_define_method( cHttpParser, "parse_chunk"       ,hpe_parse_chunk             , 1 );

    /* the common callbacks */
    rb_define_method( cHttpParser, "on_message_begin="    ,hpe_parser_on_message_begin   , 1 );
    rb_define_method( cHttpParser, "on_header_field="     ,hpe_parser_on_header_field    , 1 );
    rb_define_method( cHttpParser, "on_header_value="     ,hpe_parser_on_header_value    , 1 );
    rb_define_method( cHttpParser, "on_headers_complete=" ,hpe_parser_on_headers_complete, 1 );
    rb_define_method( cHttpParser, "on_body="             ,hpe_parser_on_body            , 1 );
    rb_define_method( cHttpParser, "on_message_complete=" ,hpe_parser_on_message_complete, 1 );
    rb_define_method( cHttpParser, "on_error="            ,hpe_parser_on_error           , 2 );


    /******************************************************************
     * Http::RequestParser 
    ******************************************************************/
    rb_define_alloc_func( cHttpRequestParser, hpe_alloc);
    rb_define_method( cHttpRequestParser, "initialize",hpe_request_parser_initialize, 0 );
    rb_define_method( cHttpRequestParser, "method"    ,hpe_parser_method            , 0 );

    /* additional request callbacks */
    rb_define_method( cHttpParser, "on_path="           ,hpe_parser_on_path          , 1 );
    rb_define_method( cHttpParser, "on_query_string="   ,hpe_parser_on_query_string  , 1 );
    rb_define_method( cHttpParser, "on_uri="            ,hpe_parser_on_uri           , 1 );
    rb_define_method( cHttpParser, "on_fragment="       ,hpe_parser_on_fragment      , 1 );


    /******************************************************************
     * Http::ResponseParser
     ******************************************************************/
    rb_define_alloc_func( cHttpResponseParser, hpe_alloc);
    rb_define_method( cHttpResponseParser, "initialize"  ,hpe_response_parser_initialize, 0 );
    rb_define_method( cHttpResponseParser, "status_code" ,hpe_parser_status_code        , 0 );

}



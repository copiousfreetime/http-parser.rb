/**
 * Copyright (c) 2009 Jeremy Hinegardner
 * All rights reserved.  See LICENSE and/or COPYING for details.
 *
 * vim: shiftwidth=4 tw=72
 */

/* #include "http-parser_ext.h" */

#include "ruby.h"
#include "http_parser.h"
#include <string.h>
#include <stdio.h>

#define true 1
#define false 0

/* class defined here */
VALUE mHttp;                /* module Http */
VALUE cHttpParser;          /* class Http::Parser */
VALUE cHttpRequestParser;   /* class Http::RequestParser */
VALUE cHttpResponseParser;  /* class Http::ResponseParser */
VALUE eHttpParserError;     /* class Http::Parser::Error  */

/***
 * Callback Error handling:
 *
 * Any time a callback is invoked, if it raises and exception then the
 * parsing will stop and either an exception will be raised where the
 * +parse_chunk+ method is called, or the +on_error+ callback will be
 * called.
 *
 * Since we are registering ruby methods as the callbacks to C methods,
 * we need to wrap the ruby method and capture the exception and store
 * it away.  We do this by using rb_protect and then getting hte
 * exception by accessing $!.
 *
 * The exception caught is then stored in the @_exception instance
 * variable in the Parser class which is passed to the +on_error+
 * callback.
 *
 */

/* wrapper struct around the information need to call a ruby method 
 * and have it be protected with rb_protect.  This is used by
 * hpe_funcall2 which is invoked by rb_protect
 */
typedef struct hpe_protected {
    VALUE   instance;
    ID      method;
    int     argc;
    VALUE  *argv;
} hpe_protected_t;

#define ERROR_INFO_MESSAGE()  ( rb_obj_as_string( rb_gv_get("$!") ) )

/**
 * invoke a ruby function, this is to be used by rb_protect
 */
VALUE hpe_wrap_funcall2( VALUE arg )
{
    hpe_protected_t *protected = (hpe_protected_t*) arg;
    return rb_funcall2( protected->instance, protected->method,
                        protected->argc, protected->argv );
}


/* generator for callback setter */
#define HPE_CALLBACK_SETTER(FOR,CB_TYPE)                              \
VALUE hpe_parser_##FOR( VALUE self, VALUE callable )                  \
{                                                                     \
    http_parser *parser;                                              \
    VALUE rb_parser;                                                  \
                                                                      \
    Data_Get_Struct( self, http_parser, parser );                     \
    rb_parser = (VALUE)parser->data;                                  \
                                                                      \
    if ( Qnil == callable ) {                                         \
        parser->FOR = NULL;                                           \
    } else {                                                          \
        rb_iv_set( rb_parser, "@" #FOR "_callback", callable );       \
        parser->FOR = (http_##CB_TYPE)hpe_##FOR##_##CB_TYPE;          \
    }                                                                 \
    return callable;                                                  \
}


/* generator for callback methods */
#define HPE_CALLBACK(FOR)                                              \
int hpe_##FOR##_cb( http_parser *parser )                              \
{                                                                      \
    VALUE rb_parser = (VALUE)parser->data;                             \
    VALUE callable  = rb_iv_get( rb_parser, "@" #FOR "_callback" );    \
    int had_error   = false;                                           \
                                                                       \
    if ( Qnil != callable ) {                                          \
        hpe_protected_t protected;                                     \
        VALUE           result;                                        \
        VALUE           cb_exception = Qnil;                           \
                                                                       \
        protected.instance = (VALUE)callable;                          \
        protected.method   = rb_intern("call");                        \
        protected.argc     = 1;                                        \
        protected.argv     = &rb_parser;                               \
                                                                       \
        result = rb_protect( hpe_wrap_funcall2, (VALUE)&protected,     \
                             &had_error);                              \
        if (had_error) {                                               \
            cb_exception = rb_gv_get("$!");                            \
        }                                                              \
        rb_iv_set( rb_parser, "@callback_exception", cb_exception);    \
    }                                                                  \
    return had_error;                                                  \
};                                                                     \
HPE_CALLBACK_SETTER(FOR,cb)


#define HPE_DATA_CALLBACK(FOR)                                         \
int hpe_##FOR##_data_cb( http_parser *parser,                          \
                         const char *at, size_t length)                \
{                                                                      \
    VALUE rb_parser = (VALUE)parser->data;                             \
    VALUE callable  = rb_iv_get( rb_parser, "@" #FOR "_callback" );    \
    int had_error   = false;                                           \
                                                                       \
    if ( Qnil != callable ) {                                          \
        hpe_protected_t protected;                                     \
        VALUE           result;                                        \
        VALUE           cb_exception = Qnil;                           \
        VALUE           args[2];                                       \
        VALUE           str = rb_str_new( at, length );                \
                                                                       \
        args[0] = rb_parser;                                           \
        args[1] = str;                                                 \
                                                                       \
        protected.instance = (VALUE)callable;                          \
        protected.method   = rb_intern("call");                        \
        protected.argc     = 2;                                        \
        protected.argv     = args;                                     \
                                                                       \
        result = rb_protect( hpe_wrap_funcall2, (VALUE)&protected,     \
                             &had_error);                              \
        if (had_error) {                                               \
            cb_exception = rb_gv_get("$!");                            \
        }                                                              \
        rb_iv_set( rb_parser, "@callback_exception", cb_exception);    \
    }                                                                  \
    return had_error;                                                  \
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
    http_parser *parser = xcalloc(1, sizeof( http_parser ));
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
    ID           const_get = rb_intern("const_get");
    VALUE        method; 

    Data_Get_Struct( self, http_parser, parser );
    switch ( parser->method ) {
    case HTTP_COPY:
        method = rb_funcall( mHttp, const_get, 1, rb_str_new2("COPY"));       
        break;
    case HTTP_DELETE:
        method = rb_funcall( mHttp, const_get, 1, rb_str_new2("DELETE"));
        break;
    case HTTP_GET:
        method = rb_funcall( mHttp, const_get, 1, rb_str_new2("GET" ));
        break;
    case HTTP_HEAD:
        method = rb_funcall( mHttp, const_get, 1, rb_str_new2("HEAD" ));
        break;
    case HTTP_LOCK:
        method = rb_funcall( mHttp, const_get, 1, rb_str_new2("LOCK" ));
        break;
    case HTTP_MKCOL:
        method = rb_funcall( mHttp, const_get, 1, rb_str_new2("MKCOL"));
        break;
    case HTTP_MOVE:
        method = rb_funcall( mHttp, const_get, 1, rb_str_new2("MOVE"));
        break;
    case HTTP_OPTIONS:
        method = rb_funcall( mHttp, const_get, 1, rb_str_new2("OPTIONS"));
        break;
    case HTTP_POST:
        method = rb_funcall( mHttp, const_get, 1, rb_str_new2("POST"));
        break;
    case HTTP_PROPFIND:
        method = rb_funcall( mHttp, const_get, 1, rb_str_new2("PROPFIND"));
        break;
    case HTTP_PROPPATCH:
        method = rb_funcall( mHttp, const_get, 1, rb_str_new2("PROPPATCH" ));
        break;
    case HTTP_PUT:
        method = rb_funcall( mHttp, const_get, 1, rb_str_new2("PUT"));
        break;
    case HTTP_TRACE:
        method = rb_funcall( mHttp, const_get, 1, rb_str_new2("TRACE"));
        break;
    case HTTP_UNLOCK:
        method = rb_funcall( mHttp, const_get, 1, rb_str_new2("UNLOCK"));
        break;
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
    int          ka;

    Data_Get_Struct( self, http_parser, parser );
    if ( http_parser_should_keep_alive( parser ) )  {
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
    rc = ULL2NUM( content_length );
   
    return rc;
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
 * If an error is encountered, an exception is thrown.  This could be
 * one of two things:
 *
 * 1) The error happened in the callback, in that case that exception is
 *    reraised
 * 2) Internal error in the parser, in this case an new excpetion is
 *    raised
 *
 * If there is an on_error callback, then it is invoked. In both cases
 * the parser and the input chunk are passed to the +on_error+ callback.
 * The receiver of the callback can interrogate the parser and see if
 * there was an error from some other callback.
 *
 */
VALUE hpe_parser_parse_chunk( VALUE self, VALUE chunk )
{
    http_parser *parser;
    VALUE       str = StringValue( chunk );
    char*       chunk_p = RSTRING_PTR( str );

    Data_Get_Struct( self, http_parser, parser );
    http_parser_execute( parser, chunk_p, RSTRING_LEN(str) );

    if ( http_parser_has_error( parser ) ) {
        VALUE callback = rb_iv_get( self, "@on_error_callback" );
        if ( Qnil == callback ) {
            rb_raise(eHttpParserError, "Failure during parsing of chunk [%s]",
                    chunk_p);
        } else {
            rb_funcall( callback, rb_intern("call"), 2, self, chunk );
        } 
    }
    return Qnil;
}

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

    rb_call_super( 0, NULL );

    /* we use the data field in the parser to point to the Ruby Object
     * that wraps it
     */
    parser->data = (void*)self;
    rb_iv_set( self, "@on_path_callback", Qnil);
    rb_iv_set( self, "@on_uri_callback", Qnil);
    rb_iv_set( self, "@on_fragment_callback", Qnil);
    rb_iv_set( self, "@on_query_string_callback", Qnil);

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

    rb_call_super( 0, NULL );

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
    mHttp               = rb_define_module( "Http" );
    cHttpParser         = rb_define_class_under( mHttp, "Parser", rb_cObject);
    cHttpRequestParser  = rb_define_class_under( mHttp, "RequestParser", cHttpParser );
    cHttpResponseParser = rb_define_class_under( mHttp, "ResponseParser", cHttpParser );
    eHttpParserError    = rb_define_class_under( cHttpParser, "Error", rb_eStandardError );

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
    rb_define_method( cHttpParser, "content_length"    ,hpe_parser_content_length   , 0 );
    rb_define_method( cHttpParser, "reset"             ,hpe_parser_reset            , 0 );
    rb_define_method( cHttpParser, "parse_chunk"       ,hpe_parser_parse_chunk      , 1 );

    /* the common callbacks */
    rb_define_method( cHttpParser, "on_message_begin="    ,hpe_parser_on_message_begin   , 1 );
    rb_define_method( cHttpParser, "on_header_field="     ,hpe_parser_on_header_field    , 1 );
    rb_define_method( cHttpParser, "on_header_value="     ,hpe_parser_on_header_value    , 1 );
    rb_define_method( cHttpParser, "on_headers_complete=" ,hpe_parser_on_headers_complete, 1 );
    rb_define_method( cHttpParser, "on_body="             ,hpe_parser_on_body            , 1 );
    rb_define_method( cHttpParser, "on_message_complete=" ,hpe_parser_on_message_complete, 1 );


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



//
//  RKResponse.h
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKRequest.h"

@interface RKResponse : NSObject {
	RKRequest* _request;
	NSHTTPURLResponse* _httpURLResponse;
	NSMutableData* _body;
	NSError* _failureError;
}

/**
 * The request that generated this response
 */
@property(nonatomic, readonly) RKRequest* request;

/**
 * The URL the response was loaded from
 */
@property(nonatomic, readonly) NSURL* URL;

/**
 * The MIME Type of the response body
 */
@property(nonatomic, readonly) NSString* MIMEType;

/**
 * The status code of the HTTP response
 */
@property(nonatomic, readonly) NSInteger statusCode;

/**
 * Return a dictionary of headers sent with the HTTP response
 */
@property(nonatomic, readonly) NSDictionary* allHeaderFields;

/**
 * The data returned as the response body
 */
@property(nonatomic, readonly) NSData* body;

/**
 * The error returned if the URL connection fails
 */
@property(nonatomic, readonly) NSError* failureError;

/**
 * An NSArray of NSHTTPCookie objects associated with the response
 */
@property(nonatomic, readonly) NSArray* cookies;

/**
 * Initialize a new response object for a REST request
 */
- (instancetype)initWithRequest:(RKRequest*)request;

/**
 * Initializes a response object from the results of a synchronous request
 */
- (instancetype)initWithSynchronousRequest:(RKRequest*)request URLResponse:(NSURLResponse*)URLResponse body:(NSData*)body error:(NSError*)error;

/**
 * Return the localized human readable representation of the HTTP Status Code returned
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *localizedStatusCodeString;

/**
 * Return the response body as an NSString
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *bodyAsString;

/**
 * Return the response body parsed as JSON into an object
 */
@property (NS_NONATOMIC_IOSONLY, readonly, strong) id bodyAsJSON;

/**
 * Will determine if there is an error object and use it's localized message
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *failureErrorDescription;

/**
 * Indicates that the connection failed to reach the remote server. The details of the failure
 * are available on the failureError reader.
 */
@property (NS_NONATOMIC_IOSONLY, getter=isFailure, readonly) BOOL failure;

/**
 * Indicates an invalid HTTP response code less than 100 or greater than 600
 */
@property (NS_NONATOMIC_IOSONLY, getter=isInvalid, readonly) BOOL invalid;

/**
 * Indicates an HTTP response code between 100 and 199
 */
@property (NS_NONATOMIC_IOSONLY, getter=isInformational, readonly) BOOL informational;

/**
 * Indicates an HTTP response code between 200 and 299
 */
@property (NS_NONATOMIC_IOSONLY, getter=isSuccessful, readonly) BOOL successful;

/**
 * Indicates an HTTP response code between 300 and 399
 */
@property (NS_NONATOMIC_IOSONLY, getter=isRedirection, readonly) BOOL redirection;

/**
 * Indicates an HTTP response code between 400 and 499
 */
@property (NS_NONATOMIC_IOSONLY, getter=isClientError, readonly) BOOL clientError;

/**
 * Indicates an HTTP response code between 500 and 599
 */
@property (NS_NONATOMIC_IOSONLY, getter=isServerError, readonly) BOOL serverError;

/**
 * Indicates that the response is either a server or a client error
 */
@property (NS_NONATOMIC_IOSONLY, getter=isError, readonly) BOOL error;

/**
 * Indicates an HTTP response code of 200
 */
@property (NS_NONATOMIC_IOSONLY, getter=isOK, readonly) BOOL OK;

/**
 * Indicates an HTTP response code of 201
 */
@property (NS_NONATOMIC_IOSONLY, getter=isCreated, readonly) BOOL created;

/**
 * Indicates an HTTP response code of 401
 */
@property (NS_NONATOMIC_IOSONLY, getter=isUnauthorized, readonly) BOOL unauthorized;

/**
 * Indicates an HTTP response code of 403
 */
@property (NS_NONATOMIC_IOSONLY, getter=isForbidden, readonly) BOOL forbidden;

/**
 * Indicates an HTTP response code of 404
 */
@property (NS_NONATOMIC_IOSONLY, getter=isNotFound, readonly) BOOL notFound;

/**
 * Indicates an HTTP response code of 422
 */
@property (NS_NONATOMIC_IOSONLY, getter=isUnprocessableEntity, readonly) BOOL unprocessableEntity;

/**
 * Indicates an HTTP response code of 301, 302, 303 or 307
 */
@property (NS_NONATOMIC_IOSONLY, getter=isRedirect, readonly) BOOL redirect;

/**
 * Indicates an empty HTTP response code of 201, 204, or 304
 */
@property (NS_NONATOMIC_IOSONLY, getter=isEmpty, readonly) BOOL empty;

/**
 * Indicates an HTTP response code of 503
 */
@property (NS_NONATOMIC_IOSONLY, getter=isServiceUnavailable, readonly) BOOL serviceUnavailable;

/**
 * Returns the value of 'Content-Type' HTTP header
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *contentType;

/**
 * Returns the value of the 'Content-Length' HTTP header
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *contentLength;

/**
 * Returns the value of the 'Location' HTTP Header
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *location;

/**
 * True when the server turned an HTML response (MIME type is text/html)
 */
@property (NS_NONATOMIC_IOSONLY, getter=isHTML, readonly) BOOL HTML;

/**
 * True when the server turned an XHTML response (MIME type is application/xhtml+xml)
 */
@property (NS_NONATOMIC_IOSONLY, getter=isXHTML, readonly) BOOL XHTML;

/**
 * True when the server turned an XML response (MIME type is application/xml)
 */
@property (NS_NONATOMIC_IOSONLY, getter=isXML, readonly) BOOL XML;

/**
 * True when the server turned an XML response (MIME type is application/json)
 */
@property (NS_NONATOMIC_IOSONLY, getter=isJSON, readonly) BOOL JSON;

@end

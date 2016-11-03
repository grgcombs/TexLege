//
//  RKRequestSerializable.h
//  RestKit
//
//  Created by Blake Watters on 8/3/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef RK_REQUEST_SERIALIZABLE_H
#define RK_REQUEST_SERIALIZABLE_H 1

/*
 * This protocol is implemented by objects that can be serialized into a representation suitable
 * for transmission over a REST request. Suitable serializations are x-www-form-urlencoded and
 * multipart/form-data.
 */
@protocol RKRequestSerializable

/**
 * The value of the Content-Type header for the HTTP Body representation of the serialization
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *HTTPHeaderValueForContentType;

@optional

/**
 * NOTE: One of the following methods MUST be implemented for your serializable implementation
 * to be complete. If you are allowing serialization of a small in-memory data structure, implement
 * HTTPBody as it is much simpler. HTTPBodyStream provides support for streaming a large payload
 * from disk instead of memory.
 */

/**
 * An NSData representing the HTTP Body serialization of the object implementing the protocol
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *HTTPBody;

/**
 * Returns an input stream for reading the serialization as a stream. Used to provide support for
 * handling large HTTP payloads.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, strong) NSInputStream *HTTPBodyStream;

/**
 * Returns the length of the HTTP Content-Length header
 */
@property (NS_NONATOMIC_IOSONLY, readonly) NSUInteger HTTPHeaderValueForContentLength;

/**
 * The value of the Content-Type header for the HTTP Body representation of the serialization
 *
 * @deprecated Implement HTTPHeaderValueForContentType instead
 */
- (NSString*)ContentTypeHTTPHeader DEPRECATED_ATTRIBUTE;

@end

#endif

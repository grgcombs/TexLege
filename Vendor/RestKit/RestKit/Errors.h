//
//  Errors.h
//  RestKit
//
//  Created by Blake Watters on 3/25/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

@import Foundation;

// The error domain for RestKit generated errors
extern NSString* const RKRestKitErrorDomain;

typedef NS_ENUM(unsigned int, RKRestKitError) {
	RKObjectLoaderRemoteSystemError = 1,
	RKRequestBaseURLOfflineError
};

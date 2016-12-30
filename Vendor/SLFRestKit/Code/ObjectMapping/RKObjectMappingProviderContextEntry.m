//
//  RKObjectMappingProviderContextEntry.m
//  RestKit
//
//  Created by Jeff Arena on 1/26/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKObjectMappingProviderContextEntry.h"

@implementation RKObjectMappingProviderContextEntry

@synthesize mapping = _mapping;
@synthesize userData = _userData;

- (id)init {
    self = [super init];
    if (self) {
        _mapping = nil;
        _userData = nil;
    }
    return self;
}

- (void)dealloc {
    [_mapping release];
    _mapping = nil;
    [_userData release];
    _userData = nil;
    [super dealloc];
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[RKObjectMappingProviderContextEntry class]]) {
        RKObjectMappingProviderContextEntry *entry = (RKObjectMappingProviderContextEntry *)object;
        return ([self.mapping isEqual:entry.mapping] && (self.userData == entry.userData));
    }
    return NO;
}

#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (NSUINT_BIT - howmuch)))

- (NSUInteger)hash {
    return NSUINTROTATE([self.mapping hash], NSUINT_BIT / 2) ^ [self.userData hash];
}

+ (RKObjectMappingProviderContextEntry *)contextEntryWithMapping:(RKObjectMappingDefinition *)mapping {
    RKObjectMappingProviderContextEntry *contextEntry = [[[RKObjectMappingProviderContextEntry alloc] init] autorelease];
    contextEntry.mapping = mapping;
    return contextEntry;
}

+ (RKObjectMappingProviderContextEntry *)contextEntryWithMapping:(RKObjectMappingDefinition *)mapping userData:(id)userData {
    RKObjectMappingProviderContextEntry * contextEntry = [RKObjectMappingProviderContextEntry contextEntryWithMapping:mapping];
    contextEntry.userData = userData;
    return contextEntry;
}

@end

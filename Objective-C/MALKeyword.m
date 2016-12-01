//
//  MALKeyword.m
//  mal
//
//  Created by Dirk Theisen on 19.10.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import "MALKeyword.h"

@implementation MALKeyword {
    NSString* _string;
}

static NSMutableDictionary* keywords = nil;

+ (void) load {
    if (! keywords) {
        keywords = [NSMutableDictionary dictionaryWithCapacity: 40];
    }
}

+ (instancetype) keywordForString: (NSString*) aString {
    MALKeyword* result = keywords[aString];
    if (! result) {
        result = [[self alloc] initWithString: aString];
        keywords[aString] = result;
    }
    return result;
}

- (id) init {
    return nil; // use convenience constructor
}

- (id) initWithString: (NSString*) aString {
    NSParameterAssert(aString.length > 0);
    if (self = [super init]) {
        _string = aString;
    }
    return self;
}

- (BOOL) isKeyword {
    return YES;
}

- (BOOL) isEqual: (id) object {
    return self == object; // uniqued
}

- (NSString*) lispDescriptionReadable: (BOOL) readable {
    return [@":" stringByAppendingString: _string];
}

- (id) copyWithZone: (id) zone {
    return self;
}

- (NSString*) description {
    return [NSString stringWithFormat: @"%@: '%@'", [super description], _string];
}

@end

@implementation NSString (LispTypes)

- (MALKeyword*) asKeyword {
    return [MALKeyword keywordForString: self];
}
@end

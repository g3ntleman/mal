//
//  NSObject+Types.m
//  mal
//
//  Created by Dirk Theisen on 01.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import "NSObject+Types.h"


@implementation NSObject (LispTypes)

- (NSString*) lispDescription {
    return [self description];
}

- (BOOL) isSymbol {
    return NO;
}

@end


@implementation NSArray (LispTypes)

- (NSString*) lispDescription {
    
    BOOL first = YES;
    NSMutableString* buffer = [[NSMutableString alloc] initWithCapacity: self.count*12];
    [buffer appendString: @"("];
    for (id object in self) {
        if (!first) {
            [buffer appendString: @" "];
            first = NO;
        }
        [buffer appendString: [object lispDescription]];
    }
    [buffer appendString: @")"];
    
    return buffer;
}

@end

@implementation NSDictionary (LispTypes)

- (NSString*) lispDescription {
    
    __block BOOL first = YES;
    NSMutableString* buffer = [[NSMutableString alloc] initWithCapacity: self.count*12];
    [buffer appendString: @"{"];
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
        if (!first) {
            [buffer appendString: @" "];
            first = NO;
        }
        [buffer appendString: [key lispDescription]];
        [buffer appendString: @" "];
        [buffer appendString: [value lispDescription]];
    }];
    [buffer appendString: @"}"];
    
    return buffer;
}

@end

@implementation NSString (LispTypes)

static NSMutableSet* symbols = nil;

+ (void)load {
    symbols = [NSMutableSet setWithCapacity: 50];
}

- (NSString*) asSymbol {
    NSString* result = [symbols member: self];
    if (! result) {
        [symbols addObject: self];
        result = self;
    }
    return result;
}

- (BOOL) isSymbol {
    return self == [symbols member: self];
}

@end
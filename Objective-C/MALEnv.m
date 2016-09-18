//
//  MALEnv.m
//  mal
//
//  Created by Dirk Theisen on 14.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import "MALEnv.h"
#import "NSObject+Types.h"

@implementation MALEnv {
    MALEnv* outer;
}

- (id) init {
    return [self initWithOuterEnvironment: nil capacity: 4];
}

- (id) initWithOuterEnvironment: (MALEnv*) anOuter
                       capacity: (NSUInteger) capacity {
    if (self = [super init]) {
        data = [[NSMutableDictionary alloc] initWithCapacity: capacity];
        outer = anOuter;
    }
    return self;
}

- (id) initWithOuterEnvironment: (MALEnv*) anOuter
                       bindings: (NSArray*) keys
                    expressions: (NSArray*) expressions {
    
    if (keys.count != expressions.count) {
        NSParameterAssert(keys.count == expressions.count);
    }
    NSUInteger count = keys.count;
    if (self = [self initWithOuterEnvironment: anOuter
                                     capacity: count]) {
        for (NSUInteger i=0; i<count; i++) {
            data[keys[i]] = expressions[i];
        }
    }
    return self;
}



//void set: (id) obj symbol: (NSString*) symbol {
//    data[[symbol asSymbol]] = obj;
//}

- (MALEnv*) find: (NSString*) symbol {
    NSParameterAssert([symbol isSymbol]);
    
    MALEnv* me = self;
    id obj;
    while (! (obj = me->data[symbol])) {
        me = me->outer;
    }
    return me;
}

- (id) get: (NSString*) symbol {
    NSParameterAssert([symbol isSymbol]);
    
    MALEnv* me = self;
    id obj;
    while (me && ! (obj = me->data[symbol])) {
        me = me->outer;
    }
    if (! obj) {
        @throw [NSException exceptionWithName: @"MALSymbolNotFound"
                                       reason: [NSString stringWithFormat: @"Symbol '%@' unavailable in all accessible Environments.", symbol]
                                     userInfo: nil];
    }
    return obj;
}

- (NSString*) description {
    return [NSString stringWithFormat: @"%@ bindings: %@", [super description], data];
}

@end

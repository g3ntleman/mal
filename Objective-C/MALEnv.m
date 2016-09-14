//
//  MALEnv.m
//  mal
//
//  Created by Dirk Theisen on 14.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import "MALEnv.h"
#import "NSObject+Types.h"

@implementation MALEnv

- (id) init {
    if (self = [super init]) {
        data = [[NSMutableDictionary alloc] initWithCapacity: 4];
    }
    return self;
}

- (id) initWithOuterEnvironment: (MALEnv*) anOuter {
    if (self = [self init]) {
        outer = anOuter;
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
    while (! (obj = me->data[symbol])) {
        me = me->outer;
    }
    if (! obj) {
        @throw [NSException exceptionWithName: @"MALSymbolNotFound"
                                       reason: [NSString stringWithFormat: @"Symbol '%@' unavailable in all accessible Environments.", symbol]
                                     userInfo: nil];
    }
    return obj;
}


@end

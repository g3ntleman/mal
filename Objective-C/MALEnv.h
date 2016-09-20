//
//  MALEnv.h
//  mal
//
//  Created by Dirk Theisen on 14.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MALEnv : NSObject {
    @public
    NSMutableDictionary* data;
}

- (id) initWithOuterEnvironment: (MALEnv*) anOuter
                       capacity: (NSUInteger) capacity;

- (id) initWithOuterEnvironment: (MALEnv*) anOuter
                       bindings: (NSMutableDictionary*) bindings;

- (id) initWithOuterEnvironment: (MALEnv*) anOuter
                       bindings: (NSArray*) keys
                    expressions: (NSArray*) expressions;

- (MALEnv*) find: (NSString*) symbol;
- (id) get: (NSString*) symbol;

@end

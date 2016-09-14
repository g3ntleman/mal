//
//  MALEnv.h
//  mal
//
//  Created by Dirk Theisen on 14.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MALEnv : NSObject {
    NSMutableDictionary* data;
    MALEnv* outer;
}

- (id) initWithOuterEnvironment: (MALEnv*) anOuter;

- (MALEnv*) find: (NSString*) symbol;
- (id) get: (NSString*) symbol;

@end

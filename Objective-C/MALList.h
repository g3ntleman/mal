//
//  MALList.h
//  mal
//
//  Created by Dirk Theisen on 06.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MALList : NSArray

+ (id) listFromArray: (NSArray*) anArray;

// TODO: Implement +listWithObjects: ...

- (NSUInteger)count;

- (id)objectAtIndex:(NSUInteger)index;

@end
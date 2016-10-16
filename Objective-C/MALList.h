//
//  MALList.h
//  mal
//
//  Created by Dirk Theisen on 06.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MALList : NSArray {
    NSUInteger _count;
}

+ (id) listFromArray: (NSArray*) anArray;
+ (id) listFromFirstObject: (id) first rest: (NSArray*) anArray;
+ (id) listFromArray:(NSArray *)anArray subrange: (NSRange) range;

// TODO: Implement +listWithObjects: ...

- (NSUInteger)count;

- (id)objectAtIndex:(NSUInteger)index;

@end

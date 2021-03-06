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

+ (id) list;
+ (id) listFromArray: (NSArray*) anArray;
+ (id) listFromFirstObject: (id) first rest: (NSArray*) anArray;
+ (id) listFromFirstObject: (id) first secondObject: second;
+ (id) listFromArray:(NSArray *)anArray subrange: (NSRange) range;
+ (id) listFromObjects: (const id[]) objects count: (NSUInteger) count;

// TODO: Implement +listWithObjects: ...

- (NSUInteger) count;

- (id)objectAtIndex: (NSUInteger) index;

- (id*) objects;
    
- (void) setObject: (id) obj atIndexedSubscript: (NSUInteger) idx;

// "private"
+ (id) listWithCapacity: (NSUInteger) capacity;
- (void) addObject: (id) obj;

@end

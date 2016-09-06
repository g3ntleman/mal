//
//  MALList.m
//  mal
//
//  Created by Dirk Theisen on 06.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import "MALList.h"
#import <objc/runtime.h>

@implementation MALList {
    NSUInteger _count;
}

+ (id) listFromArray: (NSArray*) anArray {
    
    NSUInteger count = anArray.count;
    MALList* instance = class_createInstance([MALList class], count*sizeof(id));
    instance->_count = count;
    
    NSObject** objects = object_getIndexedIvars(instance);
    
    for (NSObject* obj in anArray) {
        *objects = [obj retain];
        objects+=1;
    }
    
    return instance;
}

- (void) dealloc {
    id* objects = object_getIndexedIvars(self);
    for (NSUInteger i=0;i<_count;i++) {
        [objects[i] release];
    }
    [super dealloc];
}


- (NSUInteger) count {
    return _count;
}

- (id) objectAtIndex: (NSUInteger) index {
    return ((const id*)object_getIndexedIvars(self))[index];
}

- (NSString*) lispDescription {
    
    NSMutableString* buffer = [[NSMutableString alloc] initWithCapacity: self.count*4];
    [buffer appendString: @"("];
    id* objects = object_getIndexedIvars(self);
    for (NSUInteger i=0;i<_count;i++) {
        if (i>0) {
            [buffer appendString: @" "];
        }
        [buffer appendString: [objects[i] lispDescription]];
    }
    [buffer appendString: @")"];
    
    return buffer;
}

@end
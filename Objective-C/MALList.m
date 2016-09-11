//
//  MALList.m
//  mal
//
//  Created by Dirk Theisen on 06.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import "MALList.h"
#import "NSObject+Types.h"
#import <objc/runtime.h>

@implementation MALList {
    NSUInteger _count;
}

+ (id) listWithCapacity: (NSUInteger) capacity {
    MALList* instance = class_createInstance([MALList class], capacity*sizeof(id));
    return instance;
}

+ (id) listFromArray: (NSArray*) anArray {
    
    NSUInteger count = anArray.count;
    MALList* instance = [self listWithCapacity: count];
    instance->_count = count;
    
    NSObject** objects = object_getIndexedIvars(instance);
    
    for (NSObject* obj in anArray) {
        *objects = [obj retain];
        objects+=1;
    }
    
    return instance;
}

+ (id) listFromFirstObject: (id) first rest: (NSArray*) anArray {
    
    NSUInteger count = anArray.count+1;
    MALList* instance = [self listWithCapacity: count];
    instance->_count = count;
    
    NSObject** objects = object_getIndexedIvars(instance);
    *objects++ = [first retain];
    
    for (NSObject* obj in anArray) {
        *objects++ = [obj retain];
    }
    
    return instance;
}

- (void) addObject: (id) obj {
    NSObject** objects = object_getIndexedIvars(self);
    objects[_count++] = [obj retain];
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

- (id) EVAL: (NSDictionary*) env {
    
    if (self.count) {
        @try {
            MALList* evaluatedList = [self eval_ast: env];
            LispFunction f = evaluatedList[0];
            if (MALObjectIsBlock(f)) {
                return f(evaluatedList);
            }
            @throw [NSException exceptionWithName: @"MALUndefinedFunction" reason: [NSString stringWithFormat: @"A '%@' function is not defined.", self[0]] userInfo: nil];
        } @catch(NSException* e) {
            NSLog(@"Error evaluating function '%@': %@", self[0], e);
            return nil;
        }
    }
    return self;
}

- (id) eval_ast: (NSDictionary*) env {
    NSUInteger count = self.count;
    if (!count) return self;
    //LispFunction f = nil;
    
    NSMutableArray* args = [MALList listWithCapacity: count];
    for (id object in self) {
        id eObject = [object EVAL: env];
        //if (!f) {
        //    f = eObject;
        //} else {
        [args addObject: eObject];
        //}
    }
    return args;// f(args);
}

@end
//
//  MALList.m
//  mal
//
//  Created by Dirk Theisen on 06.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import "MALList.h"
#import "core.h"
#import "NSObject+Types.h"
#import <objc/runtime.h>

@implementation MALList 

static MALList* emptyList = nil;

+ (void) load {
    if (! emptyList) {
        emptyList = [self listWithCapacity: 0];
    }
}

+ (id) listWithCapacity: (NSUInteger) capacity {
    MALList* instance = class_createInstance([MALList class], capacity*sizeof(id));
    instance->_count = 0;
    return instance;
}

/**
 * Returns the empty list
 */
+ (id) list {
    return emptyList;
}


+ (id) listFromArray: (NSArray*) anArray {
    
    NSUInteger count = anArray.count;
    MALList* instance = [self listWithCapacity: count];
    instance->_count = count;
    NSObject** objects = object_getIndexedIvars(instance);
    [anArray getObjects: objects];
    for (NSInteger i = 0; i<count; i++) {
        [objects[i] retain];
    }
//    for (id element in anArray) {
//        [instance addObject: element];
//    }
    return instance;
}

+ (id) listFromFirstObject: (id) first secondObject: second {
    MALList* instance = [self listWithCapacity: 2];
    instance->_count = 2;
    NSObject** objects = object_getIndexedIvars(instance);
    objects[0] = first;
    objects[1] = second;
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

+ (id) listFromObjects: (const __unsafe_unretained id[]) objects count: (NSUInteger) count {
    MALList* instance = [self listWithCapacity: count];
    NSObject** ivars = object_getIndexedIvars(instance);
    for (NSUInteger i=0; i<count;i++) {
        ivars[i] = [objects[i] retain];
    }
    instance->_count = count;
    return instance;
}

+ (id) listFromArray:(NSArray *)anArray subrange: (NSRange) range {
    NSInteger count = range.length;
    MALList* instance = [self listWithCapacity: count];
    NSObject** objects = object_getIndexedIvars(instance);
    instance->_count = count;
    [anArray getObjects: objects range: range];
    for (NSInteger i = 0; i<range.length; i++) {
        [objects[i] retain];
    }
    return instance;
}

- (id*) objects {
    NSObject** objects = object_getIndexedIvars(self);
    return objects;
}
    
- (void)setObject: (id) obj atIndexedSubscript: (NSUInteger) idx {
    NSParameterAssert(idx<_count);
    NSObject** objects = object_getIndexedIvars(self);
    id previousValue = objects[idx];
    if (previousValue != obj) {
        [previousValue release];
        objects[idx] = [obj retain];
    }
}


- (void) addObject: (id) obj {
    NSObject** objects = object_getIndexedIvars(self);
    objects[_count++] = [obj retain];
}

- (NSString*) description {
    return [super description];
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

- (BOOL) isVector {
    return NO;
}


- (id) objectAtIndex: (NSUInteger) index {
    NSParameterAssert(index<_count);
    return ((const id*)object_getIndexedIvars(self))[index];
}

- (NSString*) lispDescriptionReadable: (BOOL) readable {
    
    NSMutableString* buffer = [[NSMutableString alloc] initWithCapacity: self.count*4];
    [buffer appendString: @"("];
    id* objects = object_getIndexedIvars(self);
    for (NSUInteger i=0;i<_count;i++) {
        if (i>0) {
            [buffer appendString: @" "];
        }
        id object = objects[i];
        [buffer appendString: object ? [object lispDescriptionReadable: readable] : @"nil"];
    }
    [buffer appendString: @")"];
    
    return buffer;
}

- (BOOL) lispEqual: (id) other {
    if ([other isKindOfClass: [MALList class]]) {
        return [self isEqual: other];
    }
    return NO;
}


- (id) eval_ast: (MALEnv*) env {
    NSUInteger count = self.count;
    if (!count) return self;
    
    NSMutableArray* args = [MALList listWithCapacity: count];
    for (id object in self) {
        id eObject = EVAL(object, env);
        [args addObject: eObject];
    }
    return args;
}

@end

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

+ (id) listWithCapacity: (NSUInteger) capacity {
    MALList* instance = class_createInstance([MALList class], capacity*sizeof(id));
    return instance;
}

+ (id) listFromArray: (NSArray*) anArray {
    
    NSUInteger count = anArray.count;
    MALList* instance = [self listWithCapacity: count];
    instance->_count = count;
    
    NSObject** objects = object_getIndexedIvars(instance);
    
    [anArray getObjects: objects];
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
    
    MALList* instance = [self listWithCapacity: range.length];
    NSObject** objects = object_getIndexedIvars(instance);
    [anArray getObjects: objects range: range];
    instance->_count = range.length;
    return instance;
}

- (const id*) objects {
    NSObject** objects = object_getIndexedIvars(self);
    return objects;
}
    
- (void)setObject: (id) obj atIndexedSubscript: (NSUInteger) idx {
    NSParameterAssert(idx<_count);
    NSObject** objects = object_getIndexedIvars(self);
    objects[idx] = obj;
}


- (void) addObject: (id) obj {
    NSObject** objects = object_getIndexedIvars(self);
    objects[_count++] = [obj retain];
}

- (NSString*) description {
    return [self lispDescriptionReadable: YES];
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

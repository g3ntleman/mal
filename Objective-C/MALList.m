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

+ (id) listFromArray:(NSArray *)anArray subrange: (NSRange) range {
    
    MALList* instance = [self listWithCapacity: range.length];
    NSObject** objects = object_getIndexedIvars(instance);
    NSUInteger max = range.location+range.length;
    for (NSUInteger i=range.location; i<max;i++) {
        id obj = [anArray[i] retain];
        *objects++ = obj;
    }
    instance->_count = range.length;
    return instance;
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

- (id) EVAL: (MALEnv*) env {
    
    if (self.count) {
        @try {
            if (self[0] == [@"def!" asSymbol]) {
                if (_count==3) {
                    // Make new Binding:
                    id value = [self[2] EVAL: env];
                    env->data[self[1]] = value;
                    return value;
                }
                return nil;
            }
            if (self[0] == [@"let*" asSymbol]) {
                if (_count==3) {
                    NSArray* bindingsList = self[1];
                    NSUInteger bindingListCount = bindingsList.count;
                    // Make new Environment:
                    MALEnv* letEnv = [[MALEnv alloc] initWithOuterEnvironment: env capacity:bindingListCount];
                    for (NSUInteger i=0; i<bindingListCount; i+=2) {
                        id key = bindingsList[i];
                        id value = [bindingsList[i+1] EVAL: letEnv];
                        letEnv->data[key] = value;
                    }
                    id result = [self[2] EVAL: letEnv];
                    return result;

                }
                return nil;
            }
            if (self[0] == [@"do" asSymbol]) {
                id result = nil;
                for (NSUInteger i=1; i<_count; i++) {
                    result = [self[i] EVAL: env];
                }
                return result; // return the result of the last expression evaluation
            }
            if (self[0] == [@"if" asSymbol]) {
                id cond = [self[1] EVAL: env];
                id result = nil;
                if ([cond boolValue]) {
                    result = [self[2] EVAL: env];
                } else {
                    if (_count>3) {
                        result = [self[3] EVAL: env];
                    }
                }
                return result;
            }

            if (self[0] == [@"fn*" asSymbol]) {
                MALList* bindings = self[1];
                id body = self[2];
                LispFunction block = ^id(NSArray* args) {
                    NSArray* argsOnly = [args subarrayWithRange: NSMakeRange(1, args.count-1)]; // Inefficient
                    return [body EVAL: [[MALEnv alloc] initWithOuterEnvironment: env
                                                                       bindings: bindings
                                                                    expressions: argsOnly]];
                };

                return [block copy];
            }
            
            MALList* evaluatedList = [self eval_ast: env];
            LispFunction f = evaluatedList[0];
            if (MALObjectIsBlock(f)) {
                id result = f(evaluatedList);
                return result;
            }
            @throw [NSException exceptionWithName: @"MALUndefinedFunction" reason: [NSString stringWithFormat: @"A '%@' function is not defined.", self[0]] userInfo: nil];
        } @catch(NSException* e) {
            NSLog(@"Error evaluating function '%@': %@", self[0], e);
            return nil;
        }
    }
    return self;
}

- (id) eval_ast: (MALEnv*) env {
    NSUInteger count = self.count;
    if (!count) return self;
    //LispFunction f = nil;
    
    NSMutableArray* args = [MALList listWithCapacity: count];
    for (id object in self) {
        id eObject = [object EVAL: env];
        [args addObject: eObject];
    }
    return args;
}

@end

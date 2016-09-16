//
//  NSObject+Types.m
//  mal
//
//  Created by Dirk Theisen on 01.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import "MALList.h"
#import "NSObject+Types.h"


BOOL MALObjectIsBlock(id _Nullable block) {
    static Class blockClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        blockClass = [^{} class];
        while ([blockClass superclass] != NSObject.class) {
            blockClass = [blockClass superclass];
        }
    });
    
    return [block isKindOfClass:blockClass];
}

@implementation NSObject (LispTypes)

- (NSString*) lispDescription {
    return [self description];
}

- (BOOL) isSymbol {
    return NO;
}

- (id) EVAL: (MALEnv*) env {
    return [self eval_ast: env];
}

- (id) eval_ast: (MALEnv*) env {
    return self;
}

@end


@implementation NSArray (LispTypes)

- (NSString*) lispDescription {
    
    BOOL first = YES;
    NSMutableString* buffer = [[NSMutableString alloc] initWithCapacity: self.count*4];
    [buffer appendString: @"["];
    for (id object in self) {
        if (first) {
            first = NO;
        } else {
            [buffer appendString: @" "];
        }
        [buffer appendString: [object lispDescription]];
    }
    [buffer appendString: @"]"];
    
    return buffer;
}


- (id) eval_ast: (MALEnv*) env {
    NSUInteger count = self.count;
    if (!count) return self;
    //LispFunction f = nil;
    
    NSMutableArray* args = [NSMutableArray arrayWithCapacity: count-1];
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

@implementation NSDictionary (LispTypes)

- (NSString*) lispDescription {
    
    __block BOOL first = YES;
    NSMutableString* buffer = [[NSMutableString alloc] initWithCapacity: self.count*12];
    [buffer appendString: @"{"];
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
        if (first) {
            first = NO;
        } else {
            [buffer appendString: @" "];
        }
        [buffer appendString: [key lispDescription]];
        [buffer appendString: @" "];
        [buffer appendString: [value lispDescription]];
    }];
    [buffer appendString: @"}"];
    
    return buffer;
}

- (id) eval_ast: (MALEnv*) env {
    NSUInteger count = self.count;
    if (!count) return self;

    NSMutableDictionary* tmp = [NSMutableDictionary dictionaryWithCapacity: count];
    for (id key in self) {
        id eObject = [[self objectForKey: key] EVAL: env];
        [tmp setObject: eObject forKey: key];
    }
    return tmp;
}

@end

@implementation NSString (LispTypes)

static NSMutableSet* symbols = nil;

+ (void)load {
    symbols = [NSMutableSet setWithCapacity: 50];
}

- (NSString*) asSymbol {
    NSString* result = [symbols member: self];
    if (! result) {
        [symbols addObject: self];
        result = self;
    }
    return result;
}

- (BOOL) isSymbol {
    return self == [symbols member: self];
}

- (id) eval_ast : (MALEnv*) env {
    if ([self isSymbol]) {
        id result = [env get: self];
        if (! result) {
            NSString* msg = [NSString stringWithFormat: @"Symbol '%@' not defined.", self];
            @throw([NSException exceptionWithName: @"MALUndefinedSymbolException"
                                           reason: msg
                                         userInfo: nil]);
        }
        return result;
        
    }
    return self; // simple string
}

@end



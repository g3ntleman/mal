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
    
    return [block isKindOfClass: blockClass];
}

@implementation NSObject (LispTypes)

- (NSString*) lispDescriptionReadable: (BOOL) readable {
    return MALObjectIsBlock(self) ? @"#" : [self description];
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

- (BOOL) truthValue {
    return YES;
}

@end

@implementation NSNull (LispTypes)

- (NSUInteger) count {
    return 0;
}

- (NSString*) lispDescriptionReadable: (BOOL) readable {
    return @"nil";
}

- (BOOL) truthValue {
    return NO;
}

@end

@implementation MALBool

MALBool* YESBOOL = nil;
MALBool* NOBOOL = nil;

+ (void) load {
    YESBOOL = [[self alloc] init];
    NOBOOL = [[self alloc] init];
}

+ (id) yes {
    return YESBOOL;
}

+ (id) no {
    return NOBOOL;
}

//- (BOOL) boolValue {
//    return self == YESBOOL ? YES : NO;
//}
//
//- (NSInteger) integerValue {
//    return self == YESBOOL ? 1 : 0;
//}


- (BOOL) truthValue {
    return self == YESBOOL ? YES : NO;
}

//- (const char*) objCType {
//    return "B";
//}

- (NSString*) description {
    return self == YESBOOL ? @"YESBOOL" : @"NOBOOL";
}

- (NSString*) lispDescriptionReadable: (BOOL) readable {
    return self == YESBOOL ? @"true" : @"false";
}

@end



@implementation NSArray (LispTypes)

- (NSString*) lispDescriptionReadable: (BOOL) readable {
    
    BOOL first = YES;
    NSMutableString* buffer = [[NSMutableString alloc] initWithCapacity: self.count*4];
    [buffer appendString: @"["];
    for (id object in self) {
        if (first) {
            first = NO;
        } else {
            [buffer appendString: @" "];
        }
        [buffer appendString: object ? [object lispDescriptionReadable: readable] : @"nil"];
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

- (NSString*) lispDescriptionReadable: (BOOL) readable {
    
    __block BOOL first = YES;
    NSMutableString* buffer = [[NSMutableString alloc] initWithCapacity: self.count*12];
    [buffer appendString: @"{"];
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
        if (first) {
            first = NO;
        } else {
            [buffer appendString: @" "];
        }
        [buffer appendString: [key lispDescriptionReadable: readable]];
        [buffer appendString: @" "];
        [buffer appendString: value ? [value lispDescriptionReadable: readable] : @"nil"];
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
        result = [NSString stringWithString: self];
        [symbols addObject: result];
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
    return self; // it's a simple string
}


/**
 * TODO: abbreviate long strings
 */
- (NSString*) lispDescriptionReadable: (BOOL) readable {

    if (readable) {
        NSUInteger count = self.length;
        unichar source[count];
        unichar* sourcep = source;
        unichar dest[count*2+2]; // worst case
        unichar* destp = dest;
        unichar* endp = sourcep+count;
        [self getCharacters: sourcep];
        *destp++ = '\"';
        while (sourcep < endp) {
            unichar ch = *sourcep;
            if (ch == '\"' || ch == '\\') {
                *destp++ = (unichar)'\\';
            }
            if (ch == '\n') {
                *destp++ = (unichar)'\\';
                *destp++ = 'n';
            } else {
                *destp++ = ch;
            }
            sourcep+=1;
        }
        *destp++ = '\"';
        return [NSString stringWithCharacters: dest length: destp-dest];
    } else {
        return self;
    }
}

@end



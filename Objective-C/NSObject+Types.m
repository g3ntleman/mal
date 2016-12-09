//
//  NSObject+Types.m
//  mal
//
//  Created by Dirk Theisen on 01.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import "MALList.h"
#import "MALKeyword.h"
#import "NSObject+Types.h"

@interface MALBool : NSValue
@end
@interface MALNil : NSValue
@end

@implementation MALNil

- (const char*) objCType {
    return @encode(id);
}

- (void) getValue: (void*) value {
    void** oPtr = value;
    *oPtr = nil;
}

- (NSString*) lispDescriptionReadable: (BOOL) readable {
    return @"nil";
}

@end

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

- (BOOL) isSequential {
    return NO;
}

- (MALList*) asSequence {
    return MALNilObject;
}


- (BOOL) isMap {
    return NO;
}

- (BOOL) isVector {
    return NO;
}


- (BOOL) isKeyword {
    return NO;
}


- (NSDictionary*) meta {
    return nil;
}

- (void) setMeta: (id) newMeta {
    // stub
}


- (BOOL) isMacro {
    return NO;
}

- (BOOL) lispEqual: (id) other {
    return [self isEqual: other];
}


- (id) eval_ast: (MALEnv*) env {
    return self;
}

//- (id) truthValue {
//    return NOBOOL;
//}

@end

//@implementation NSNull (LispTypes)
//
//- (NSUInteger) count {
//    return 0;
//}
//
//- (NSString*) lispDescriptionReadable: (BOOL) readable {
//    return @"nil";
//}
//
//
//- (id) firstObject {
//    return nil;
//}
//
//@end

Class MALStringClass;
Class MALArrayClass;
Class MALListClass;
id MALNilObject;
id YESBOOL = nil;
id NOBOOL = nil;


@implementation MALBool


+ (void) load {
    YESBOOL = [[self alloc] init];
    NOBOOL = [[self alloc] init];
    MALStringClass = [NSString class];
    MALArrayClass = [NSArray class];
    MALListClass = [MALList class];
    MALNilObject = [[MALNil alloc] init];
}


- (BOOL) boolValue {
    return self == YESBOOL ? YES : NO;
}

//
//- (NSInteger) integerValue {
//    return self == YESBOOL ? 1 : 0;
//}


//- (id) truthValue {
//    return self == YESBOOL ? YESBOOL : NOBOOL;
//}

- (const char*) objCType {
    return "B";
}

- (NSString*) description {
    return self == YESBOOL ? @"YESBOOL" : @"NOBOOL";
}

- (NSString*) lispDescriptionReadable: (BOOL) readable {
    return self == YESBOOL ? @"true" : @"false";
}

- (BOOL) isEqual: (id) object {
    return self == object;
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

- (BOOL) isVector {
    return YES;
}

- (id) eval_ast: (MALEnv*) env {
    NSUInteger count = self.count;
    if (!count) return self;
    //LispFunction f = nil;
    
    NSMutableArray* args = [NSMutableArray arrayWithCapacity: count-1];
    for (id object in self) {
        id eObject = EVAL(object, env);
        //if (!f) {
        //    f = eObject;
        //} else {
        [args addObject: eObject];
        //}
    }
    return args;// f(args);
}

- (BOOL) isSequential {
    return YES;
}

- (MALList*) asSequence {
    if (! self.count) return MALNilObject;
    return [MALList listFromArray: self];
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

- (BOOL) isMap {
    return YES;
}

- (id) dictionaryBySettingObject: (id) value forKey: (id<NSCopying>) key {
    NSParameterAssert(key);
    NSDictionary* result = self;
    if (value) {
        if (! [value isEqual: self[key]]) {
            NSMutableDictionary* newdict = [self mutableCopy];
            [newdict setObject: value forKey: key];
            result = newdict;
        }
    }
    return result;
}

- (id) dictionaryByRemovingObjectForKey: (id<NSCopying>) key {
    NSMutableDictionary * dictionary = [self mutableCopy];
    [dictionary removeObjectForKey: key];
    return [dictionary copy];
}

- (id) eval_ast: (MALEnv* _Nullable) env {
    NSUInteger count = self.count;
    if (!count) return self;

    NSMutableDictionary* tmp = [NSMutableDictionary dictionaryWithCapacity: count];
    for (id key in self) {
        id eObject = EVAL([self objectForKey: key], env);
        [tmp setObject: eObject forKey: key];
    }
    return tmp;
}

@end

@implementation NSString (LispTypes)

static NSMutableSet* symbols = nil;

+ (void) load {
    if (! symbols) {
        symbols = [NSMutableSet setWithCapacity: 50];
    }
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


- (BOOL) lispEqual: (id) other {
    return  [self isEqual: other] && ((self == [symbols member: self]) == (other == [symbols member: other]));
}


- (id) eval_ast : (MALEnv*) env {
    if ([self isSymbol]) {
        id result = [env get: self];
        if (! result) {
            NSString* msg = [NSString stringWithFormat: @"'%@' not found", self];
            @throw([NSException exceptionWithName: @"MALUndefinedSymbolException"
                                           reason: msg
                                         userInfo: nil]);
        }
        return result;
    }
    return self; // it's a simple string
}

- (MALList*) asSequence {
    NSUInteger len = self.length;
    if (! len) return MALNilObject;
    MALList* result = [MALList listWithCapacity: len];
    unichar string[len];
    [self getCharacters: string];
    for (NSUInteger i=0; i<len; i++) {
        [result addObject: [NSString stringWithCharacters: &(string[i]) length: 1]];
    }
    
    return result;
}


/**
 * TODO: abbreviate long strings
 */
- (NSString*) lispDescriptionReadable: (BOOL) readable {

    if ([self isSymbol]) {
        return self;
    }
    
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
            } else if (ch == '\r') {
                *destp++ = (unichar)'\\';
                *destp++ = 'r';
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

@implementation MALAtom
    
- (id) initWithValue: (id) aValue {
    if (self = [super init]) {
        value = aValue;
    }
    return self;
}

- (NSString*) lispDescriptionReadable: (BOOL) readable {
    return [NSString stringWithFormat: @"(atom %@)", [value lispDescriptionReadable: readable]];
}

    
@end

@implementation NSException (LispTypes)

- (NSString*) lispDescriptionReadable: (BOOL) readable {
    return [NSString stringWithFormat: @"Exception %@", [[self userInfo][@"MalObject"] lispDescriptionReadable: readable]];
}


@end


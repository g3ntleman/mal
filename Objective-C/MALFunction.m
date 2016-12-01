#import "NSObject+Types.h"
#import "MALFunction.h"
#import "MALEnv.h"

@implementation MALFunction {
    NSMutableDictionary* _meta;
}

- (id) initWithBlock: (GenericFunction) aBlock {
    if (self = [super init]) {
        block = [aBlock copy];
        _meta = nil;
    }
    return self;
}

//- (void) dealloc {
//    if (_block) {
//        [_block release];
//    }
//}


- (NSMutableDictionary*) meta {
    if (!_meta) {
        _meta = [[NSMutableDictionary alloc] init];
    }
    return _meta;
}

/**
 * returns a name or nil for anonymous functions.
 */
- (NSString*) name {
    return _meta[@"name"];
}

//- (id)apply:(NSArray *)args {
//    return EVAL(_ast, [[MALEnv alloc] initWithOuterEnvironment: _env bindings: binds:_params]);
//}

- (id) copyWithZone: (NSZone*) zone {
    MALFunction* copy = [[[self class] alloc] initWithBlock: block];
    if (copy && _meta) {
        [copy.meta setValuesForKeysWithDictionary: _meta];
    }
    return copy;
}

- (NSString*) description {
    return [NSString stringWithFormat: @"%@ %@", [super description], self.name];
}

- (NSString*) lispDescriptionReadable: (BOOL) readable {
    NSString* name = self.name;
    return name ? [NSString stringWithFormat: @"#%@", self.name] : @"#";
}

- (BOOL) isEqual: (id) other {
    if (! [other isKindOfClass: [self class]]) {
        return NO;
    }
    return block == ((MALFunction*)other)->block;
}

- (BOOL) isMacro {
    return _meta[@"macro"] != nil;
}

- (void) setMacro: (BOOL) isMacro {
    self.meta[@"macro"] = isMacro ? @YES : nil;
}

@end


//NSObject * apply(id f, NSArray *args) {
//    if ([f isKindOfClass:[MALFunction class]]) {
//        return [f apply:args];
//    } else {
//        NSObject * (^ fn)(NSArray *) = f;
//        return fn(args);
//    }
//}

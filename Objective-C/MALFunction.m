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

- (NSString*) lispDescriptionReadable: (BOOL) readable {
    return @"#";
}

- (BOOL) isEqual: (id) other {
    if (! [other isKindOfClass: [self class]]) {
        return NO;
    }
    return block == ((MALFunction*)other)->block;
}


@end


@implementation MALMacro

- (BOOL) isMacro {
    return YES;
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

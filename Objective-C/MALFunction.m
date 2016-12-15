#import "NSObject+Types.h"
#import "MALFunction.h"
#import "MALEnv.h"


@implementation MALFunction {
    NSMutableDictionary* _meta;
    BOOL _isMacro;
}


- (id) initWithMetaInfo: (NSDictionary*) meta
                  block: (GenericFunction) aBlock {
    if (self = [super init]) {
        block = [aBlock copy];
        _meta = [meta copy];
    }
    return self;
}

- (id) initWithName: (NSString*) functionName
              block: (GenericFunction) aBlock {
    return [self initWithMetaInfo: @{@"name": functionName} block: aBlock];
}

//- (void) dealloc {
//    if (block) {
//        [block release];
//    }
//}


- (id) meta {
//    if (!_meta) {
//        _meta = [[NSMutableDictionary alloc] init];
//    }
    return _meta;
}

- (void) setMeta: (id) meta {
    _meta = meta;
}

/**
 * returns a name of the function or nil, if not set.
 */
- (NSString*) name {
    return _meta[@"name"];
}

- (id) copyWithZone:(NSZone *)zone {
    return self;
}

- (id) lispObjectBySettingMeta: (id) newMeta {
    MALFunction* copy = [[[self class] alloc] initWithMetaInfo: newMeta block: block];
    copy->_isMacro = _isMacro;
    return copy;
}

- (NSString*) description {
    return [NSString stringWithFormat: @"%@ %@", [super description], self.name];
}

- (NSString*) lispDescriptionReadable: (BOOL) readable {
    NSString* name = self.name;
    return name ? [NSString stringWithFormat: @"#%@", self.name] : @"#";
}

- (NSUInteger) hash {
    return [block hash];
}

- (BOOL) isEqual: (id) other {
    if (! [other isKindOfClass: [self class]]) {
        return NO;
    }
    return block == ((MALFunction*)other)->block; // also check macro flag?
}

- (BOOL) isMacro {
    return _isMacro;
}

- (void) setMacro: (BOOL) isMacro {
    _isMacro = isMacro;
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

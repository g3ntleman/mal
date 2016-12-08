//
//  NSObject+Types.h
//  mal
//
//  Created by Dirk Theisen on 01.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MALList.h"
#import "MALFunction.h"
#import "MALEnv.h"

#pragma clang diagnostic ignored "-Wnullability-completeness"

extern Class MALStringClass;
extern Class MALListClass;
extern id MALNilObject;


typedef id _Nullable (^LispFunction)(NSArray* _Nullable args );

extern BOOL MALObjectIsBlock(id _Nullable block);


@interface NSObject (LispTypes)

- (NSString* _Nonnull) lispDescriptionReadable: (BOOL) readable;
- (id _Nullable) eval_ast: (MALEnv* _Nullable) env;
- (BOOL) isSymbol;
- (BOOL) isKeyword;
- (BOOL) isMacro;
- (BOOL) isSequential;
- (id) meta;
- (void) setMeta: (id) newMeta;
//- (id) truthValue;
- (BOOL) lispEqual: (id) other;

- (BOOL) isMap;
- (BOOL) isVector;

@end

@interface NSString (LispTypes)

- (NSString* _Nonnull) asSymbol;

@end

@interface NSDictionary (LispTypes)
- (id) dictionaryBySettingObject: (id) value forKey: (id<NSCopying>) key;
- (id) dictionaryByRemovingObjectForKey: (id<NSCopying>) key;
@end


// Atoms

@interface MALAtom : NSObject {
    @public id value;
}
    
- (id) initWithValue: (id) value;
    
@end



extern id _Nonnull  YESBOOL;
extern id _Nonnull  NOBOOL;

id _Nullable EVAL(id _Nullable ast, MALEnv* _Nullable env);


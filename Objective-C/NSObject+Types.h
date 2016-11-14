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


typedef id _Nullable (^LispFunction)(NSArray* _Nullable args );

extern BOOL MALObjectIsBlock(id _Nullable block);

@interface NSObject (LispTypes)

- (NSString* _Nonnull) lispDescriptionReadable: (BOOL) readable;
- (id _Nullable) eval_ast: (MALEnv* _Nullable) env;
- (BOOL) isSymbol;
- (BOOL) isMacro;
- (BOOL) truthValue;
- (BOOL) lispEqual: (id) other;

@end

@interface NSString (LispTypes)

- (NSString* _Nonnull) asSymbol;

@end


@interface MALBool : NSNumber

+ (_Nonnull id) yes;
+ (_Nonnull id) no;

@end

// Atoms

@interface MalAtom : NSObject {
    @public id value;
}
    
- (id) initWithValue: (id) value;
    
@end


extern MALBool* _Nonnull  YESBOOL;
extern MALBool* _Nonnull  NOBOOL;

id _Nullable EVAL(id _Nullable ast, MALEnv* _Nullable env);


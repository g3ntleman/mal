//
//  NSObject+Types.h
//  mal
//
//  Created by Dirk Theisen on 01.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MALEnv.h"

typedef id _Nullable (^LispFunction)(NSArray* _Nullable args );

extern BOOL MALObjectIsBlock(id _Nullable block);

@interface NSObject (LispTypes)

- (NSString* _Nonnull) lispDescriptionReadable: (BOOL) readable;
- (id) EVAL: (MALEnv*) env;
- (id) eval_ast: (MALEnv*) env;
- (BOOL) isSymbol;

@end

@interface NSString (LispTypes)

- (NSString* _Nonnull) asSymbol;

@end

@interface MALBool : NSNumber

+ (id) numberWithBool: (BOOL) yn;

+ (id) yes;
+ (id) no;

@end

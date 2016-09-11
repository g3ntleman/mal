//
//  NSObject+Types.h
//  mal
//
//  Created by Dirk Theisen on 01.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id _Nullable (^LispFunction)(NSArray* _Nullable args );

extern BOOL MALObjectIsBlock(id _Nullable block);

@interface NSObject (LispTypes)

- (NSString* _Nonnull) lispDescription;
- (id) EVAL: (NSDictionary*) env;
- (id) eval_ast: (NSDictionary*) env;
- (BOOL) isSymbol;

@end

@interface NSString (LispTypes)

- (NSString* _Nonnull) asSymbol;

@end


//
//  NSObject+Types.h
//  mal
//
//  Created by Dirk Theisen on 01.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (LispTypes)

- (NSString*) lispDescription;
- (BOOL) isSymbol;

@end

@interface NSString (LispTypes)

- (NSString*) asSymbol;

@end



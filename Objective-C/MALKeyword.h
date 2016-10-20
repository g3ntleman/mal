//
//  MALKeyword.h
//  mal
//
//  Created by Dirk Theisen on 19.10.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MALKeyword : NSObject

+ (instancetype) keywordForString: (NSString* _Nonnull) aString;

@end


@interface NSString (MALKeyword)

- (MALKeyword* _Nonnull) asKeyword;

@end

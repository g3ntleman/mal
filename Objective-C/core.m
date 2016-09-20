//
//  MALNamespace.m
//  mal
//
//  Created by Dirk Theisen on 19.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import "core.h"
#import "NSObject+Types.h"
#import "MALList.h"

NSDictionary* MALCoreNameSpace() {
    static NSMutableDictionary* coreNS = nil;
    static Class stringClass = nil;
    static Class listClass = nil;
    static MALBool* yes = nil;
    static MALBool* no  = nil;
    
    if (! coreNS) {
        stringClass = [NSString class];
        listClass = [MALList class];
        yes = [MALBool yes];
        no  = [MALBool no];
        
        // Ignore first argument!
        NSDictionary* protoNS = @{
                                  [@"string?" asSymbol]: ^(NSArray *args){
                                      return [args[1] isKindOfClass: stringClass] ? yes: no;
                                  },
                                  [@"list?" asSymbol]: ^(NSArray *args){
                                      return [args[1] isKindOfClass: listClass] ? yes : no;
                                  },
                                  [@"+" asSymbol]: ^id(NSArray* args) {
                                      NSUInteger count = args.count;
                                      NSInteger result = 0;
                                      for (int i = 1; i<count; i++) {
                                          result += [args[i] integerValue];
                                      }
                                      return @(result);
                                  },
                                  [@"-" asSymbol]: ^id(NSArray* args) {
                                      NSUInteger count = args.count;
                                      NSInteger result = 0;
                                      
                                      if (count>1) {
                                          result = [args[1] integerValue];
                                          if (count == 2) {
                                              result = -result;
                                          } else {
                                              for (int i = 2; i<count; i++) {
                                                  result -= [args[i] integerValue];
                                              }
                                          }
                                      }
                                      return @(result);
                                  },
                                  [@"*" asSymbol]: ^id(NSArray* args) {
                                      NSCParameterAssert(args.count>1);
                                      NSInteger result = 1;
                                      NSUInteger count = args.count;
                                      
                                      for (int i = 1; i<count; i++) {
                                          result *= [args[i] integerValue];
                                      }
                                      return @(result);
                                  },
                                  [@"/" asSymbol]: ^id(NSArray* args) {
                                      NSUInteger count = args.count;
                                      NSInteger result = 0;
                                      
                                      if (count>1) {
                                          result = [args[1] integerValue];
                                          if (count == 2) {
                                              result = 1.0/result;
                                          } else {
                                              for (int i = 2; i<count; i++) {
                                                  result /= [args[i] integerValue];
                                              }
                                          }
                                      }
                                      return @(result);
                                  },
                                  [@"list" asSymbol]: ^id(NSArray* args) {
                                      return [MALList listFromArray: args
                                                           subrange: NSMakeRange(1, args.count-1)];
                                  },
                                  [@"count" asSymbol]: ^id(NSArray* args) {
                                      return @([args[1] count]);
                                  },
                                  [@"empty?" asSymbol]: ^id(NSArray* args) {
                                      return [MALBool numberWithBool: [args[1] count]==0];
                                  },
                                  [@"first" asSymbol]: ^id(NSArray* args) {
                                      return [args[1] firstObject];
                                  },
                                  [@"rest" asSymbol]: ^id(NSArray* args) {
                                      return [MALList listFromArray: args
                                                           subrange: NSMakeRange(1, args.count-1)];
                                  },
                                  [@"=" asSymbol]: ^id(NSArray* args) {
                                      id o1 = args[1];
                                      id o2 = args[2];
                                      return o1==o2 || [o1 isEqual: o2] ? yes : no;
                                  },
                                  [@">" asSymbol]: ^id(NSArray* args) {
                                      id o1 = args[1];
                                      id o2 = args[2];
                                      return [o1 integerValue] > [o2 integerValue] ? yes : no;
                                  },
                                  [@"<" asSymbol]: ^id(NSArray* args) {
                                      id o1 = args[1];
                                      id o2 = args[2];
                                      return [o1 integerValue] < [o2 integerValue] ? yes : no;
                                  },
                                  [@"not" asSymbol]: ^id(NSArray* args) {
                                      id obj = args[1];
                                      return ((! obj) || obj == no) ? yes : no;
                                  }
                                  
                                  };
        coreNS = [protoNS mutableCopy];
    }
    return coreNS;
}

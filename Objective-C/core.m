//
//  MALNamespace.m
//  mal
//
//  Created by Dirk Theisen on 19.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import "core.h"
#import "NSObject+Types.h"
#import "SESyntaxParser.h"
#import "MALList.h"

//typedef struct SEQ_t {
//    id obj;
//    unsigned index;
//} SEQ;

//id seq_first(SEQ* seq) {
//    return [seq->obj valueAtIndex: seq->index];
//}
//
//SEQ seq_rest(SEQ* seq) {
//    SEQ next;
//    next.obj = seq->obj;
//    next.index = seq.index+1
//    return [seq->obj valueAtIndex: seq->index];
//}

int f1_i(int i) {
    return 1;
}

NSString* f1_io(int i, id o) {
    return [o description];
}


static NSMutableDictionary* coreNS = nil;
static Class stringClass = nil;
static Class listClass = nil;
static MALBool* yes = nil;
static MALBool* no  = nil;
static NSNull* nilObject = nil;


typedef id (*MALFunction1)(id arg1);
typedef id (*MALFunction2)(id arg1, id arg2);
typedef id (*MALFunction3)(id arg1, id arg2, id arg3);


id MALCoreF_first(NSArray* array) {
    return [array firstObject];
}

MALFunction1 MALCore_first = &MALCoreF_first;

NSDictionary* MALCoreNameSpace() {
    
    if (! coreNS) {
        stringClass = [NSString class];
        listClass = [MALList class];
        yes = [MALBool yes];
        no  = [MALBool no];
        nilObject = [NSNull null];
        
        // Ignore first argument!
        NSDictionary* protoNS =
        @{
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
              return [args[1] count]==0 ? YESBOOL : NOBOOL;
          },
//          [@"first" asSymbol]: ^id(NSArray* args) {
//              return [args[1] firstObject];
//          },
          [@"first" asSymbol]: [NSValue valueWithPointer: &MALCore_first],
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
          [@"<=" asSymbol]: ^id(NSArray* args) {
              id o1 = args[1];
              id o2 = args[2];
              return [o1 integerValue] <= [o2 integerValue] ? yes : no;
          },
          [@">=" asSymbol]: ^id(NSArray* args) {
              id o1 = args[1];
              id o2 = args[2];
              return [o1 integerValue] >= [o2 integerValue] ? yes : no;
          },
//          [@"not" asSymbol]: ^id(NSArray* args) {
//              id obj = args[1];
//              return ((! obj) || obj == no) ? yes : no;
//          },
          [@"prn" asSymbol]: ^id(NSArray* args) {
              BOOL first = YES;
              id last = args.lastObject;
              for (id arg in args) {
                  if (! first) {
                      const char* str = [pr_str(arg, YES) UTF8String];
                      printf(arg == last ? "%s" : "%s ", str);
                  } else {
                      first = NO;
                  }
              }
              printf("\n");
              return nilObject;
          },
          [@"str" asSymbol]: ^id(NSArray* args) {
              NSUInteger count = args.count;
              if (count<2) return @"";
              NSMutableString* result = [NSMutableString stringWithCapacity: count*6];
              for (int i = 1; i<count; i++) {
                  [result appendString: [args[i] lispDescriptionReadable: NO]];
              }
              return result;
          },
          [@"pr-str" asSymbol]: ^id(NSArray* args) {
              NSUInteger count = args.count;
              if (count<=1) return @"";
              NSMutableString* result = [NSMutableString stringWithCapacity: count*6];
              for (int i = 1; i<count; i++) {
                  [result appendString: [args[i] lispDescriptionReadable: YES]];
                  if (i<count-1) {
                      [result appendString: @" "];
                  }
              }
              return result;
          },
          
          [@"println" asSymbol]: ^id(NSArray* args) {
              NSUInteger count = args.count;
              
              for (int i = 1; i<count; i++) {
                  NSString* argDesc = [args[i] lispDescriptionReadable: NO];
                  printf(i>1 ? " %s" : "%s", [argDesc UTF8String]);
              }
              printf("\n");
              return nilObject;
          },
          [@"read-string" asSymbol]: ^id(NSArray* args) {
              NSCParameterAssert(args.count == 2);
              id ast = read_str(args[1]);
              return ast;
          },
          [@"slurp" asSymbol]: ^id(NSArray* args) {
              NSCParameterAssert(args.count == 2);
              NSError* error = nil;
              NSString* stringContents = [NSString stringWithContentsOfFile: args[1] encoding:NSUTF8StringEncoding error: &error];
              if (error) {
                  @throw error;
              }
              return stringContents;
          }
        };
        coreNS = [protoNS mutableCopy];
        
        coreNS[[@"first" asSymbol]] = [NSValue valueWithPointer: &MALCore_first];
        
    }
    return coreNS;
}

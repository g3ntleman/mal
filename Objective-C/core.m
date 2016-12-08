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
#import "MALFunction.h"
#import "MALKeyword.h"
#import "MALList.h"

static inline id TruthValue(id object) {
    return object == YESBOOL ? YESBOOL : NOBOOL;
}

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



typedef id (*MALFunction1)(id arg1);
typedef id (*MALFunction2)(id arg1, id arg2);
typedef id (*MALFunction3)(id arg1, id arg2, id arg3);

// Test for wrapping functions
id MALCoreF_first(NSArray* array) {
    return [array firstObject];
}

#define isObject(generic) (YES)

MALFunction1 MALCore_first = &MALCoreF_first;

id string$_gg(void* object) {
    if (!isObject(object)) {
        return NOBOOL;
    }
    return ([((__bridge id)object) isKindOfClass: MALStringClass] ? YESBOOL: NOBOOL);
}

id plus_ggx(id ptr, ...) {
    
//    va_list va;
//    id p;
//    
//    va_start(va, ptr);
//    for (p = ptr; p != NULL; p = va_arg(va, id)) {
//        printf("%p\n", p);
//    }
//    va_end(va);
    
    
    va_list argp;
    va_start(argp, ptr);
    NSInteger result = [ptr integerValue];
    while ((ptr = va_arg(argp, id)) != nil) {
        NSCAssert([ptr isKindOfClass: [NSNumber class]], @"'+': Argument '%@' is not a number.", [ptr lispDescriptionReadable: YES]);
        result += [ptr integerValue];
    }
    va_end(argp);
    return @(result);
}


NSDictionary* MALCoreNameSpace() {
    
    if (! coreNS) {
        
        // Ignore first argument!
        NSDictionary* protoNS =
        @{
          [@"string?" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              return [args[1] isKindOfClass: MALStringClass] ? YESBOOL: NOBOOL;
          }],
          [@"list?" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              return [args[1] isKindOfClass: MALListClass] ? YESBOOL : NOBOOL;
          }],
          [@"+" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSUInteger count = args.count;
              NSInteger result = 0;
              for (int i = 1; i<count; i++) {
                  NSNumber* arg = args[i];
                  NSCAssert([arg isKindOfClass: [NSNumber class]], @"'+': Argument #%d ('%@') is not a number.", i, [arg lispDescriptionReadable: YES]);
                  result += [arg integerValue];
              }
              return @(result);
          }],
          [@"-" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
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
          }],
          [@"*" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSCParameterAssert(args.count>1);
              NSInteger result = 1;
              NSUInteger count = args.count;
              
              for (int i = 1; i<count; i++) {
                  result *= [args[i] integerValue];
              }
              return @(result);
          }],
          [@"/" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
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
          }],
          [@"list" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              return [MALList listFromArray: args
                                   subrange: NSMakeRange(1, args.count-1)];
          }],
          [@"count" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              return @([args[1] count]);
          }],
          [@"empty?" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              return [args[1] count]==0 ? YESBOOL : NOBOOL;
          }],
          [@"first" asSymbol]:  [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              return [args[1] firstObject];
          }],
          [@"rest" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSArray* arg = args[1];
              NSInteger argCount = arg.count;
              return argCount ? [MALList listFromArray: arg
                                              subrange: NSMakeRange(1, argCount-1)] : [MALList list];
          }],
          [@"=" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              id o1 = args[1];
              id o2 = args[2];
              return o1==o2 || [o1 lispEqual: o2] ? YESBOOL : NOBOOL;
          }],
          [@">" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              id o1 = args[1];
              id o2 = args[2];
              return [o1 integerValue] > [o2 integerValue] ? YESBOOL : NOBOOL;
          }],
          [@"<" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              id o1 = args[1];
              id o2 = args[2];
              return [o1 integerValue] < [o2 integerValue] ? YESBOOL : NOBOOL;
          }],
          [@"<=" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              id o1 = args[1];
              id o2 = args[2];
              return [o1 integerValue] <= [o2 integerValue] ? YESBOOL : NOBOOL;
          }],
          [@">=" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              id o1 = args[1];
              id o2 = args[2];
              return [o1 integerValue] >= [o2 integerValue] ? YESBOOL : NOBOOL;
          }],
//          [@"not" asSymbol]: ^id(NSArray* args) {
//              id obj = args[1];
//              return ((! obj) || obj == no) ? yes : no;
//          },
          [@"prn" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
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
              return MALNilObject;
          }],
          [@"str" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSUInteger count = args.count;
              if (count<2) return @"";
              NSMutableString* result = [NSMutableString stringWithCapacity: count*6];
              for (int i = 1; i<count; i++) {
                  [result appendString: [args[i] lispDescriptionReadable: NO]];
              }
              return result;
          }],
          [@"pr-str" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
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
          }],
          [@"println" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSUInteger count = args.count;
              
              for (int i = 1; i<count; i++) {
                  NSString* argDesc = [args[i] lispDescriptionReadable: NO];
                  printf(i>1 ? " %s" : "%s", [argDesc UTF8String]);
              }
              printf("\n");
              return MALNilObject;
          }],
          [@"read-string" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSCParameterAssert(args.count == 2);
              id ast = read_str(args[1]);
              return ast;
          }],
          [@"slurp" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSCParameterAssert(args.count == 2);
              NSError* error = nil;
              NSString* stringContents = [NSString stringWithContentsOfFile: args[1] encoding:NSUTF8StringEncoding error: &error];
              if (error) {
                  @throw [NSException exceptionWithName: error.domain reason: error.localizedDescription userInfo: nil];
              }
              return stringContents;
          }],
          [@"time-ms" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSCParameterAssert(args.count == 1);
              struct timespec spec;
              clock_gettime(CLOCK_REALTIME, &spec);
              long ms = ((spec.tv_nsec + 500000) / 1000000); // Round nanoseconds to milliseconds
              return @(spec.tv_sec*1000+ms);
          }],
          [@"atom" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSCParameterAssert(args.count == 2);
              return [[MALAtom alloc] initWithValue: args[1]];
          }],
          [@"atom?" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSCParameterAssert(args.count == 2);
              return [args[1] isKindOfClass: [MALAtom class]] ? YESBOOL : NOBOOL; // TODO: Make static Class variabel for comparison
          }],
          [@"deref" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSCParameterAssert(args.count == 2);
              NSCAssert([args[1] isKindOfClass: [MALAtom class]], @"'deref' expects an atom, got '%@'.", [args[1] lispDescriptionReadable: YES]);
              return ((MALAtom*)args[1])->value;
          }],
          [@"reset!" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSCParameterAssert(args.count == 3);
              NSCParameterAssert([args[1] isKindOfClass: [MALAtom class]]);
              return ((MALAtom*)args[1])->value = args[2];
          }],
          [@"swap!" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSCParameterAssert(args.count >= 3);
              NSCParameterAssert([args[1] isKindOfClass: [MALAtom class]]);
              MALAtom* atom = args[1];
              MALFunction* f = args[2];
              id atomValue = atom->value;
              MALList* list = [MALList listFromArray: args subrange: NSMakeRange(1, args.count-1)];
              list[1] = atomValue;
              return (atom->value = apply(f, list));
          }],
          [@"cons" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSCParameterAssert(args.count >= 3);
              NSCParameterAssert([args[2] isKindOfClass: [NSArray class]]);
              id first = args[1];
              MALList* rest = args[2];
              MALList* list = [MALList listFromFirstObject: first rest: rest];
              return list;
          }],
          [@"nth" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSCParameterAssert(args.count >= 3);
              NSCParameterAssert([args[1] isKindOfClass: [NSArray class]]);
              NSArray* list = args[1];
              NSInteger n = [args[2] integerValue];
              id result = [list objectAtIndex: n];
              return result;
          }],
          [@"concat" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              id e1 = args[0];
              NSUInteger count = 0;
              for (MALList* e in args) {
                  if (e != e1) {
                      count+=e.count;
                  }
              }
              __unsafe_unretained id elements[count];
              if (count) {
                  NSUInteger offset = 0;
                  for (MALList* e in args) {
                      if (e != e1) {
                          [e getObjects: elements+offset];
                          offset += e.count;
                      }
                  }
              }
              MALList* list = [MALList listFromObjects: elements count: count];
              return list;
          }],
          [@"symbol" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              return [args[1] asSymbol];
          }],
          [@"symbol?" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              return [args[1] isSymbol] ? YESBOOL : NOBOOL;
          }],
          [@"keyword" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              return [args[1] asKeyword];
          }],
          [@"keyword?" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              return [args[1] isKeyword] ? YESBOOL : NOBOOL;
          }],
          [@"vector?" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              return [args[1] isVector] ? YESBOOL : NOBOOL;
          }],
          [@"map?" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              return [args[1] isMap] ? YESBOOL : NOBOOL;
          }],
          [@"get" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSDictionary* dict = args[1];
              if (! dict || dict == MALNilObject) return MALNilObject;
              id key = args[2];
              return dict[key];
          }],
          [@"assoc" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSInteger argsCount = args.count;
              NSCAssert(argsCount >=2 && argsCount %2 == 0, @"'assoc' expects an odd number of parameters.");
              NSDictionary* dict = args[1];
              NSMutableDictionary* result = nil;
              for (NSInteger i=2; i<argsCount; i+=2) {
                  id key = args[i];
                  id value = args[i+1];
                  if (! result) result = [dict mutableCopy];
                  result[key] = value;
              }
              return result ? result : dict;
          }],
          [@"dissoc" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSDictionary* dict = args[1];
              NSInteger argCount = args.count;
              NSMutableDictionary* result = nil;
                  for (int i=2; i<argCount;i++) {
                      id key = args[i];
                      if (dict[key]) {
                          if (! result) result = [dict mutableCopy];
                          [result removeObjectForKey: key];
                      }
                  }
              return result ? result : dict;
          }],
          [@"contains?" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSDictionary* dict = args[1];
              id key = args[2];
              return dict[key] ? YESBOOL : NOBOOL;
          }],
          [@"keys" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSDictionary* dict = args[1];
              NSUInteger count = dict.count;
              __unsafe_unretained id keysArray[count];
              [dict getObjects: NULL andKeys: keysArray];
              MALList* keys = [MALList listFromObjects: keysArray count: count];
              return keys;
          }],
          [@"vals" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSDictionary* dict = args[1];
              NSUInteger count = dict.count;
              __unsafe_unretained id objects[count];
              [dict getObjects: objects andKeys: NULL];
              MALList* vals = [MALList listFromObjects: objects count: count];
              return vals;
          }],
          [@"true?" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              return TruthValue(args[1]);
          }],
          [@"false?" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              return args[1] == YESBOOL ? NOBOOL : YESBOOL;
          }],
          [@"nil?" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              id arg = args[1];
              return (arg == nil || arg == MALNilObject) ? YESBOOL : NOBOOL;
          }],
          [@"sequential?" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              id arg = args[1];
              return ([arg isSequential]) ? YESBOOL : NOBOOL;
          }],
          // apply : takes at least two arguments. The first argument is a function and the last argument is list (or vector). The arguments between the function and the last argument (if there are any) are concatenated with the final argument to create the arguments that are used to call the function. The apply function allows a function to be called with arguments that are contained in a list (or vector). In other words, (apply F A B [C D]) is equivalent to (FABCD).
          [@"apply" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSCParameterAssert(args.count >= 3);
              MALFunction* function = args[1];
              NSArray* lastArgs = args.lastObject;
              NSMutableArray* newArgs = [args mutableCopy];
              [newArgs removeObjectAtIndex: 0];
              [newArgs removeLastObject];
              [newArgs addObjectsFromArray: lastArgs];
              return function->block(newArgs);
          }],
          // map : takes a function and a list (or vector) and evaluates the function against every element of the list (or vector) one at a time and returns the results as a list.
          [@"map" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSCParameterAssert(args.count >= 3);
              MALFunction* function = args[1];
              GenericFunction block = function->block;
              NSArray* objects = args[2];
              MALList* result = [MALList listWithCapacity: objects.count];
              for (NSObject* o in objects) {
                  id oo = block(@[function, o]);
                  [result addObject: oo ? oo : MALNilObject];
              }
              return result;
          }],
          [@"meta" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              return [args[1] meta];
          }],
          [@"with-meta" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSCAssert(args.count==3, @"'with-meta' expects two parameters.");
              NSObject* object = args[1];
              id newMeta = args[2];
              NSObject* copy = [object copy];
              [copy setMeta: newMeta];
              return copy;
          }],
          [@"vector" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              return [args subarrayWithRange: NSMakeRange(1, args.count-1)];
          }],
          [@"*host-language*" asSymbol]: @"Objective-C",
          [@"hash-map" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              NSInteger argsCount = args.count;
              NSCAssert(args.count%2==1, @"hash-map expects an even number of arguments.");
              NSMutableDictionary* result = [[NSMutableDictionary alloc] initWithCapacity: argsCount/2];
              for (int i=1; i<argsCount; i+=2) {
                  id key = args[i];
                  id value = args[i+1];
                  result[key]=value;
              }
              return result;
          }],
          
          [@"throw" asSymbol]: [[MALFunction alloc] initWithBlock: ^id(NSArray* args) {
              id object = args[1];
              NSException* e = [NSException exceptionWithName: @"MALException"
                                                       reason: [object lispDescriptionReadable: YES]
                                                     userInfo: @{@"MalObject": object}];
              @throw e;
          }]
        };
        coreNS = [protoNS mutableCopy];
        
        // Add key as metadata name:
        [coreNS enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, MALFunction*  _Nonnull function, BOOL * _Nonnull stop) {
            function.meta[@"name"] = key;
        }];
        
//        coreNS[[@"first" asSymbol]] = [NSValue valueWithPointer: &MALCore_first];
        
    }
    return coreNS;
}

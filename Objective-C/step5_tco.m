//
//  mal
//
//  Created by Dirk Theisen on 26.08.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <readline/readline.h>
#import "SESyntaxParser.h"
#import "NSObject+Types.h"
#import "core.h"
#import "step4_if_fn_do.h"


id READ(NSString* code) {
    SESyntaxParser* reader = [[SESyntaxParser alloc] initWithString: code range: NSMakeRange(0, code.length)];
    id result = [reader readForm];
    //NSLog(@"Read '%@' into '%@'", code, result);
    return result;
}

NSString* REP(NSString* code, MALEnv* env) {
    
    id ast = nil;
    NSString* result = nil;
    @try {
        ast = READ(code);
    } @catch (NSException* exception) {
        NSLog(@"Error during parsing: %@", exception);
    }
    @try {
        ast = EVAL(ast, env);
    } @catch (NSException* exception) {
        NSLog(@"Error during evaluation: %@", exception);
    }
    @try {
        result = PRINT(ast);
    } @catch (NSException* exception) {
        NSLog(@"Error during printing: %@", exception);
    }
    return result;
}

id EVAL(id ast, MALEnv* env) {
    while (YES) {
        if ([ast isKindOfClass: [MALList class]]) /* TODO: make [MALList class] a static var */ {
            MALList* list = ast;
            NSUInteger listCount = list.count;
            if (listCount) {
                @try {
                    id firstElement = list[0];
                    if (firstElement == [@"def!" asSymbol]) { // TODO: turn symbols into statics
                        if (listCount==3) {
                            // Make new Binding:
                            id value = EVAL(list[2], env);
                            env->data[list[1]] = value;
                            return value;
                        }
                        NSLog(@"Warning: def! needs 2 parameters.");
                        return nilObject;
                    } else if (firstElement == [@"let*" asSymbol]) {
                        MALEnv* letEnv;
                        if (listCount!=3) {
                            NSLog(@"Warning: let* expects 2 parameters.");
                            return nilObject;
                        }
                        NSArray* bindingsList = list[1];
                        NSUInteger bindingListCount = bindingsList.count;
                        // Make new Environment:
                        letEnv = [[MALEnv alloc] initWithOuterEnvironment: env capacity:bindingListCount];
                        for (NSUInteger i=0; i<bindingListCount; i+=2) {
                            id key = bindingsList[i];
                            id value = EVAL(bindingsList[i+1], letEnv);
                            letEnv->data[key] = value;
                        }
                        env = letEnv;
                        ast = list[2];
                        // loop...
                    } else if (firstElement == [@"do" asSymbol]) {
                        if (listCount==1) return nilObject;
                        id result = nil;
                        for (NSUInteger i=1; i<listCount-1; i++) {
                            result = EVAL(list[i], env);
                        }
                        ast = list[listCount-1];
                    } else if (firstElement == [@"if" asSymbol]) {
                        NSCParameterAssert(listCount>2);

                        id cond = EVAL(list[1], env);
                        if ([cond truthValue] == YESBOOL) {
                            ast = list[2];
                        } else {
                            if (listCount<=3) {
                                return nilObject;
                            }
                            ast = list[3];
                        }
                    } else if (firstElement == [@"fn*" asSymbol]) {
                        __block NSArray* symbols = list[1];
                        NSCParameterAssert([symbols isKindOfClass: [NSArray class]]);
                        id body = list[2];
                        NSUInteger symbolsCount = symbols.count;
                        __block BOOL hasVarargs = symbolsCount >= 2 && [(symbols[symbolsCount-2]) isEqualToString: @"&"];
                        
                        LispFunction block = ^id(NSArray* call) {
                            NSMutableDictionary* bindings;
                            MALEnv* functionEnv = env;
                            if (hasVarargs) {
                                NSUInteger regularArgsCount = symbolsCount-2;
                                __unsafe_unretained id args[call.count];
                                __unsafe_unretained id syms[symbolsCount];
                                [call getObjects: args];
                                [symbols getObjects: syms];
                                bindings = [NSMutableDictionary dictionaryWithObjects: args+1 forKeys: syms count: regularArgsCount]; // formal params
                                MALList* varargList = [MALList listFromObjects: args+1+regularArgsCount count: call.count-regularArgsCount-1];
                                bindings[symbols.lastObject] = varargList;
                            } else {
                                NSCParameterAssert(call.count == symbolsCount+1);
                                if (symbolsCount) {
                                    __unsafe_unretained id args[symbolsCount];
                                    __unsafe_unretained id syms[symbolsCount];
                                    [call getObjects: args];
                                    [symbols getObjects: syms];
                                    bindings = [NSMutableDictionary dictionaryWithObjects: args+1 forKeys: syms count: symbolsCount];
                                    functionEnv = [[MALEnv alloc] initWithOuterEnvironment: env
                                                                                  bindings: bindings]; // I want to be on the stack
                                }
                            }
                            return EVAL(body, functionEnv);
                        };
                        
                        return [block copy];
                    } else {
                        MALList* evaluatedList = [list eval_ast: env];
                        LispFunction f = evaluatedList[0];
                        if (firstElement == [@"sum2" asSymbol]) {
                    xxx
                        } else {
                            if (MALObjectIsBlock(f)) {
                                id result = f(evaluatedList);
                                return result;
                            } else {
                                @throw [NSException exceptionWithName: @"MALUndefinedFunction" reason: [NSString stringWithFormat: @"A '%@' function is not defined.", list[0]] userInfo: nil];
                            }
                        }
                    }
                } @catch(NSException* e) {
                    NSLog(@"Error evaluating function '%@': %@", list[0], e);
                    return nil;
                }
            }
        } else {
            return [ast eval_ast: env];
        }
    }
    return nil; // silence compiler
}



int main(int argc, const char * argv[]) {
    // Create an autorelease pool to manage the memory into the program
    @autoreleasepool {
        
        
        MALEnv* replEnvironment = [[MALEnv alloc] initWithOuterEnvironment: nil bindings: [MALCoreNameSpace() mutableCopy]];
        
        REP(@"(def! not (fn* (a) (if a false true)))", replEnvironment);
                
        while (true) {
            char *rawline = readline("user> ");
            if (!rawline) { break; }
            NSString *line = [NSString stringWithUTF8String:rawline];
            if ([line length] == 0) { continue; }
            id result = REP(line, replEnvironment);
            printf("%s\n", [result UTF8String]);
        }
    }
    return 0;
}

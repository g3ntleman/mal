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
                    if (list[0] == [@"def!" asSymbol]) { // TODO: turn symbols into statics
                        if (listCount==3) {
                            // Make new Binding:
                            id value = EVAL(list[2], env);
                            env->data[list[1]] = value;
                            return value;
                        }
                        NSLog(@"Warning: def! needs 2 parameters.");
                        return nil;
                    }
                    if (list[0] == [@"let*" asSymbol]) {
                        MALEnv* letEnv;
                        while (YES) {
                            if (listCount!=3) {
                                NSLog(@"Warning: let* expects 2 parameters.");
                                return nil;
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
                            
                            id result = EVAL(list[2], letEnv);
                            return result;                            
                        }
                    }
                    if (list[0] == [@"do" asSymbol]) {
                        id result = nil;
                        for (NSUInteger i=1; i<listCount; i++) {
                            result = EVAL(list[i], env);
                        }
                        return result; // return the result of the last expression evaluation
                    }
                    if (list[0] == [@"if" asSymbol]) {
                        id cond = EVAL(list[1], env);
                        id result = nil;
                        if ([cond truthValue]) {
                            result = EVAL(list[2], env);
                        } else {
                            if (listCount>3) {
                                result = EVAL(list[3], env);
                            }
                        }
                        return result ? result : nilObject;
                    }
                    
                    if (list[0] == [@"fn*" asSymbol]) {
                        NSArray* symbols = list[1];
                        NSCParameterAssert([symbols isKindOfClass: [NSArray class]]);
                        id body = list[2];
                        NSUInteger symbolsCount = symbols.count;
                        BOOL hasVarargs = symbolsCount >= 2 && [(symbols[symbolsCount-2]) isEqualToString: @"&"];
                        
                        LispFunction block = ^id(NSArray* call) {
                            NSMutableDictionary* bindings;
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
                                } else {
                                    return EVAL(body, env);
                                }
                            }
                            MALEnv* functionEnv = [[MALEnv alloc] initWithOuterEnvironment: env
                                                                                  bindings: bindings]; // I want to be on the stack
                            return EVAL(body, functionEnv);
                        };
                        
                        return [block copy];
                    }
                    
                    MALList* evaluatedList = [list eval_ast: env];
                    LispFunction f = evaluatedList[0];
                    if (MALObjectIsBlock(f)) {
                        id result = f(evaluatedList);
                        return result;
                    }
                    @throw [NSException exceptionWithName: @"MALUndefinedFunction" reason: [NSString stringWithFormat: @"A '%@' function is not defined.", list[0]] userInfo: nil];
                } @catch(NSException* e) {
                    NSLog(@"Error evaluating function '%@': %@", list[0], e);
                    return nil;
                }
            }
            return ast;
            
        } else {
            return [ast eval_ast: env];
        }
    }
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

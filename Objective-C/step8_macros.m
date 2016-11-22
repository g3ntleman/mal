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
#import "step8_macros.h"


id READ(NSString* code) {
    return read_str(code);
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

//static BOOL is_pair(id ast) {
//    return [ast isKindOfClass: [MALList class]] && [ast count]>=2;
//}

static NSArray* quasiquote(NSArray* ast) {
    
    if (! [ast isKindOfClass: [NSArray class]]) {
        return [MALList listFromFirstObject: [@"quote" asSymbol] secondObject: ast];
    }
    
    NSUInteger astCount =  ast.count;
    
    if (! astCount) {
        return ast;
    }
    
    id firstElement = ast[0];

    if (firstElement == [@"unquote" asSymbol]) {
        return ast[1];
    }

    // if is_pair of the first element of ast is true and the first element of
    // first element of ast ( ast[0][0] ) is a symbol named "splice-unquote":
    // return a new list containing: a symbol named "concat", the second element
    // of first element of ast ( ast[0][1] ), and the result of calling quasiquote
    // with the second through last element of ast .
    if ([firstElement isKindOfClass: [NSArray class]] && firstElement[0] == [@"splice-unquote" asSymbol]) {
        __unsafe_unretained id listContent[3];
        listContent[0] = [@"concat" asSymbol];
        listContent[1] = ast[0][1];
        listContent[2] = quasiquote([ast subarrayWithRange: NSMakeRange(1, astCount-1)]);
        return [MALList listFromObjects: listContent count: 3];
    }
    
    // otherwise: return a new list containing: a symbol named "cons", the result of calling
    // quasiquote on first element of ast ( ast[0] ), and the result of calling quasiquote with
    // the second through last element of ast.
    __unsafe_unretained id listContent[3];
    listContent[0] = [@"cons" asSymbol];
    listContent[1] = quasiquote(firstElement);
    listContent[2] = quasiquote([ast subarrayWithRange: NSMakeRange(1, astCount-1)]);
    return [MALList listFromObjects: listContent count: 3];
}

/**
 * This function takes arguments ast and env.
 * It returns true if ast is a list that contains a symbol as the first element
 * and that symbol refers to a function in the env environment and that function
 * has the is_macro attribute set to true. Otherwise, it returns false.
 */
//id as_macro_call(id ast, MALEnv* environment) {
//    if ([ast isKindOfClass: [MALList class]]) /* TODO: make [MALList class] a static var */ {
//        MALList* list = ast;
//        NSUInteger listCount = list.count;
//        if (listCount) {
//            NSString* firstSymbol = list[0];
//            MALFunction* function = [environment get: firstSymbol];
//            if ([function isMacro]) {
//                return function;
//            }
//        }
//    }
//    return ast;
//}

/**
 * This function takes arguments ast and env. It calls is_macro_call with ast and env
 * and loops while that condition is true. Inside the loop, the first element of
 * the ast list (a symbol), is looked up in the environment to get the macro function.
 * This macro function is then called/applied with the rest of the ast elements
 * (2nd through the last) as arguments.
 * The return value of the macro call becomes the new value of ast.
 * When the loop completes because ast no longer represents a macro call,
 * the current value of ast is returned.
 **/
id macroexpand(id ast, MALEnv* environment) {
    id expansion = nil;

    if ([ast isKindOfClass: [MALList class]]) { /* TODO: make [MALList class] a static var */
        MALList* list = ast;
        NSUInteger listCount = list.count;
        if (listCount) {
            NSString* firstSymbol = list[0];
            MALFunction* function = [environment get: firstSymbol];
            if ([function isMacro]) {
                expansion = apply(function, list);
                //NSLog(@"Expanded Macro %@ to %@", function, expansion);
            }
        }
    }
    if (! expansion) {
        return ast;
    }
    return macroexpand(expansion, environment); // rely on compiler TCO
}

id EVAL(id ast, MALEnv* env) {
    while (YES) {
        ast = macroexpand(ast, env);
        if ([ast isKindOfClass: [MALList class]]) {/* TODO: make [MALList class] a static var */
            MALList* list = ast;
            NSUInteger listCount = list.count;
            if (listCount) {
                @try {
                    NSString* firstSymbol = list[0];
                    
                    if (firstSymbol == [@"defmacro!" asSymbol]) { // TODO: turn symbols into statics
                        if (listCount==3) {
                            NSString* name = [list[1] asSymbol];
                            // Make new Binding:
                            MALFunction* macro = EVAL(list[2], env);
                            NSCAssert([macro isKindOfClass: [MALFunction class]], @"defmacro! expects a function.");
                            [macro setMacro: YES];
                            //NSCAssert(macro.isMacro, @"setMacro failed.");
                            macro.meta[@"name"] = name;
                            env->data[name] = macro;
                            return macro;
                        }
                        NSLog(@"Warning: defmacro! needs 2 parameters.");
                        return nil;
                    }
                    
                    if (firstSymbol == [@"def!" asSymbol]) { // TODO: turn symbols into statics
                        if (listCount==3) {
                            // Make new Binding:
                            NSString* name = [list[1] asSymbol];
                            NSObject* value = EVAL(list[2], env);
                            value.meta[@"name"] = name;
                            env->data[name] = value;
                            return value;
                        }
                        NSLog(@"Warning: def! needs 2 parameters.");
                        return nil;
                    }
                    if (firstSymbol == [@"let*" asSymbol]) {
                        MALEnv* letEnv;
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
                    if (firstSymbol == [@"do" asSymbol]) {
                        id result = nil;
                        for (NSUInteger i=1; i<listCount; i++) {
                            result = EVAL(list[i], env);
                        }
                        return result; // return the result of the last expression evaluation
                    }
                    if (firstSymbol == [@"if" asSymbol]) {
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
                    if (firstSymbol == [@"fn*" asSymbol]) {
                        NSArray* symbols = list[1];
                        NSCParameterAssert([symbols isKindOfClass: [NSArray class]]);
                        id body = list[2];
                        NSUInteger symbolsCount = symbols.count;
                        BOOL hasVarargs = symbolsCount >= 2 && [(symbols[symbolsCount-2]) isEqualToString: @"&"];
                        
                        return [[MALFunction alloc] initWithBlock: ^id(NSArray* call) {
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
                                if (! symbolsCount) {
                                    return EVAL(body, env);
                                }
                                __unsafe_unretained id args[symbolsCount];
                                __unsafe_unretained id syms[symbolsCount];
                                [call getObjects: args];
                                [symbols getObjects: syms];
                                bindings = [NSMutableDictionary dictionaryWithObjects: args+1 forKeys: syms count: symbolsCount];
                            }
                            MALEnv* functionEnv = [[MALEnv alloc] initWithOuterEnvironment: env
                                                                                  bindings: bindings]; // I want to be on the stack
                            return EVAL(body, functionEnv);
                        }];
                    }
                    if (firstSymbol == [@"quote" asSymbol]) {
                        return list[1];
                    }
                    if (firstSymbol == [@"quasiquote" asSymbol]) {
                        ast = quasiquote(list[1]);
                        continue; // "TCO"
                    }
                    // Expose the macroexpand function, mostly for debugging:
                    if (firstSymbol == [@"macroexpand" asSymbol]) {
                        return macroexpand(list[1], env);
                    }
                    
                    
                    MALList* evaluatedList = [list eval_ast: env];
                    MALFunction* f = evaluatedList[0];
                    if ([f isKindOfClass: [MALFunction class]]) {
                        id result = f->block(evaluatedList);
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
        
        NSMutableDictionary* bindings = [MALCoreNameSpace() mutableCopy];
        MALEnv* replEnvironment = [[MALEnv alloc] initWithOuterEnvironment: nil bindings: bindings];
        __weak MALEnv* weakEnv = replEnvironment;
        
        // Add eval:
        [replEnvironment set: ^id(NSArray* args) {
            NSCParameterAssert(args.count == 2);
            id ast = args[1];
            return EVAL(ast, weakEnv);
        } symbol: [@"eval" asSymbol]];
        
        // Add *ARGV*:
        NSMutableArray* mainArgs = [NSMutableArray arrayWithCapacity: argc];
        NSString* startupFilename = nil;
        
        if (argc>1) {
            startupFilename = [NSString stringWithCString: argv[1] encoding: NSUTF8StringEncoding];
            for (int i=2; i<argc; i++) {
                [mainArgs addObject: [NSString stringWithCString: argv[i] encoding: NSUTF8StringEncoding]];
            }
        }
        [replEnvironment set: [MALList listFromArray: mainArgs]
                      symbol: [@"*ARGV*" asSymbol]];
        
        REP(@"(def! not (fn* (a) (if a false true)))", replEnvironment); // Just as test. TODO: implement natively
        REP(@"(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \")\")))))", replEnvironment);
        
        if (startupFilename.length) {
            REP([NSString stringWithFormat: @"(load-file \"%@\")", startupFilename], replEnvironment);
        } else {
            // Interactive
            while (true) {
                char *rawline = readline("user> ");
                if (!rawline) { break; }
                NSString *line = [NSString stringWithUTF8String:rawline];
                if ([line length] == 0) { continue; }
                id result = REP(line, replEnvironment);
                printf("%s\n", [result UTF8String]);
            }
        }
    }
    return 0;
}


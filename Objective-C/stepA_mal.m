//
//  mal
//
//  Created by Dirk Theisen on 26.08.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import <Foundation/NSString.h>
#import <Foundation/Foundation.h>
#include <readline/readline.h>
#import "SESyntaxParser.h"
#import "NSObject+Types.h"
#import "core.h"
#import "stepA_mal.h"
#include <dlfcn.h>

id READ(NSString* code) {
    return read_str(code);
}

NSString* REP(NSString* code, MALEnv* env) {
    
    id ast = nil;
    NSString* result = nil;
    @try {
        ast = READ(code);
    } @catch (NSException* exception) {
        NSLog(@"Exception during parsing '%@': %@", code, exception);
    }
    @try {
        ast = EVAL(ast, env);
    } @catch (NSException* exception) {
        NSLog(@"Exception during evaluation: %@", exception);
    }
    @try {
        result = PRINT(ast);
    } @catch (NSException* exception) {
        NSLog(@"Exception during printing: %@", exception);
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
                //NSLog(@"Expanded Macro '%@' to '%@'.", firstSymbol, [expansion lispDescriptionReadable: YES]);
            }
        }
    }
    if (! expansion) {
        return ast;
    }
    return macroexpand(expansion, environment); // rely on compiler TCO
}

id EVAL(id ast, MALEnv* env) {
    NSCParameterAssert(env != nil);
    while (YES) {
        ast = macroexpand(ast, env);
        if ([ast isKindOfClass: [MALList class]]) {/* TODO: make [MALList class] a static var */
            MALList* list = ast;
            NSUInteger listCount = list.count;
            if (listCount) {
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
                        NSString* symbol = [list[1] asSymbol];
                        NSObject* value = EVAL(list[2], env);
                        value = [value lispObjectBySettingMeta: @{@"name": symbol}];
                        env->data[symbol] = value;
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
                        id key = [bindingsList[i] asSymbol];
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
                    if (cond == YESBOOL) {
                        result = EVAL(list[2], env);
                    } else {
                        if (listCount>3) {
                            result = EVAL(list[3], env);
                        }
                    }
                    return result ? result : MALNilObject;
                }
                if (firstSymbol == [@"fn*" asSymbol]) {
                    NSArray* symbols = list[1];
                    NSCParameterAssert([symbols isKindOfClass: [NSArray class]]);
                    id body = list[2];
                    NSUInteger symbolsCount = symbols.count;
                    BOOL hasVarargs = symbolsCount >= 2 && [(symbols[symbolsCount-2]) isEqualToString: @"&"];
                    
                    return [[MALFunction alloc] initWithMetaInfo: nil block: ^id(NSArray* call) {
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
                if (firstSymbol == [@"try*" asSymbol]) {
                    @try {
                        return EVAL(list[1], env);
                    } @catch(NSObject* e) {
                        if (listCount > 2 && [list[2] isKindOfClass: [MALList class]]) {
                            MALList* a2lst = list[2];
                            if (a2lst[0] == [@"catch*" asSymbol]) {
                                id exc = e;
                                if ([e isKindOfClass: [NSException class]]) {
                                    NSDictionary* userInfo = [exc userInfo];
                                    id object = userInfo[@"MalObject"];
                                    if (object) {
                                        exc = object;
                                    } else {
                                        exc = [exc reason];
//                                        NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithObject: [exc name] forKey: @"name"];
//                                        if ([exc reason]) dict[@"reason"] = [exc reason];
//                                        if ([exc userInfo]) dict[@"userInfo"] = [exc userInfo];
//                                        exc = dict;
                                    }
                                }
                                // Bind 2nd paramter symbol to expection dictionary:
                                MALEnv* eEnv = [[MALEnv alloc] initWithOuterEnvironment: env bindings: [NSMutableDictionary dictionaryWithObject: exc forKey: [a2lst[1] asSymbol]]];
                                return EVAL(a2lst[2], eEnv);
                            }
                        }
                        @throw e; // not handeled
                    }
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
            }
            return ast;
        } else {
            return [ast eval_ast: env];
        }
    }
}

NSString* getCurrentWorkingDirectory() {
    char path[PATH_MAX];
    if (getcwd(path, PATH_MAX-1) == 0)
        return nil;
    NSString* currentDir = [[NSFileManager defaultManager] stringWithFileSystemRepresentation: path
                                                             length: strlen(path)];
    return currentDir;
}

typedef id (LispFunction_gg)(id p1);
typedef id (LispFunction_ggx)(id p1, ...);
typedef id (LispFunction_ggg)(id p1, id p2);
typedef id (LispFunction_gggg)(id p1, id p2, id p3);
typedef id (LispFunction_ggggg)(id p1, id p2, id p3, id p4);
typedef id (LispFunction_gggggg)(id p1, id p2, id p3, id p4, id p5);


void* FunctionForSpec(const char* name, const char* parSpec) {
    char symName[100];
    sprintf(symName, "%s_%s", name, parSpec);
    dlerror();
    void* dlhandle = dlopen(NULL, RTLD_NOW);
    void* function = dlsym(dlhandle, symName);
    char* error = dlerror();
    dlclose(dlhandle);
    if (error) {
        return NULL;
    }
    return function;
}

id call1(const char* name, id p1) {
    LispFunction_gg* function = FunctionForSpec(name, "gg");
    NSCAssert(function != NULL, @"Error calling function: No function named '%s' found.", name);
    return function(p1);
}

id call3(const char* name, id p1, id p2, id p3) {
    LispFunction_ggx* function = FunctionForSpec(name, "ggx");
    NSCAssert(function != NULL, @"Error calling function: No function named '%s' found.", name);
    return function(p1, p2, p3);
}



int main(int argc, const char * argv[]) {
    // Create an autorelease pool to manage the memory into the program
    
    @autoreleasepool {
        
        
        NSNumber* sum0 = plus_ggx(@(2), @(3), nil); // call vararg function directly
        NSNumber* sum1 = call3("plus", @(2), @(3), nil); // call vararg function by name
        
        BOOL isString = [call1("string$", @"TestString") boolValue];
        
        //((LispFunction2*)addr)(argc, argv);
        NSMutableDictionary* bindings = [MALCoreNameSpace() mutableCopy];
        MALEnv* replEnvironment = [[MALEnv alloc] initWithOuterEnvironment: nil bindings: bindings];
        __weak MALEnv* weakEnv = replEnvironment;
        
        // Add eval:
        [weakEnv set: [[MALFunction alloc] initWithName: @"eval" block: ^id(NSArray* args) {
            NSCParameterAssert(args.count == 2);
            id ast = args[1];
            return EVAL(ast, replEnvironment);
        }] symbol: @"eval"];
        
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
                      symbol: @"*ARGV*"];
        
        REP(@"(def! not (fn* (a) (if a false true)))", replEnvironment); // Just as test. TODO: implement natively
        REP(@"(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \")\")))))", replEnvironment);
        REP(@"(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw \"odd number of forms to cond\")) (cons 'cond (rest (rest xs)))))))", replEnvironment);
        //REP(@"(defmacro! or (fn* (& xs) (if (empty? xs) nil (if (= 1 (count xs)) (first xs) `(let* (or_FIXME ~(first xs)) (if or_FIXME or_FIXME (or ~@(rest xs))))))))", replEnvironment);
        REP(@"(def! *gensym-counter* (atom 0))", replEnvironment);
        REP(@"(def! gensym (fn* [] (symbol (str \"G__\" (swap! *gensym-counter* (fn* [x] (+ 1 x)))))))", replEnvironment);
        REP(@"(defmacro! or (fn* (& xs) (if (empty? xs) nil (if (= 1 (count xs)) (first xs) (let* (condvar (gensym)) `(let* (~condvar ~(first xs)) (if ~condvar ~condvar (or ~@(rest xs)))))))))", replEnvironment);

        
        if (startupFilename.length) {
            REP([NSString stringWithFormat: @"(load-file \"%@\")", startupFilename], replEnvironment);
        } else {
            REP(@"(println (str \"Mal [\" *host-language* \"]\"))", replEnvironment);
            //printf("Welcome to the MAL Interpreter (Objective-C).\n");
            //printf("Working Directory: %s\n\n", [getCurrentWorkingDirectory() UTF8String]);

            NSMutableString* line = [NSMutableString string];
            // Interactive
            while (true) {
                char *rawline = readline(line.length ? "": "user> ");
                if (!rawline || !strlen(rawline)) { continue; }
                if (rawline[0] == '\4') {
                    break; // quit
                }
                
                NSString* fragment = [NSString stringWithUTF8String: rawline];
                [line appendString: fragment];
                if ([line length] == 0) { break; }
                @try {
                    // Try to read a form:
                    READ(line);
                } @catch (NSException* exception) {
                    // If that fails, wait for more input:
                    [line appendString: @"\n"];
                    continue;
                }
                
                id result = REP(line, replEnvironment);
                printf("%s\n", [result UTF8String]);
                line = [NSMutableString string];
            }
        }
    }
    return 0;
}


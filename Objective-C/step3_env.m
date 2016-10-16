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
#import "step3_env.h"


//#define EVAL(ast, env) [ast lispEvalWithEnvironment: env]
//#define eval_ast(ast, env) [ast eval_ast: env]


id eval_ast(id ast, MALEnv* env) {
    return [ast eval_ast: env];
}




id READ(NSString* code) {
    SESyntaxParser* reader = [[SESyntaxParser alloc] initWithString: code range: NSMakeRange(0, code.length)];
    id result = [reader readForm];
    //NSLog(@"Read '%@' into '%@'", code, result);
    return result;
}


id EVAL(id ast, id env) {
    ast = [ast EVAL: env];
    return ast;
}


NSString* PRINT(id exp) {
    return [exp lispDescriptionReadable: YES];
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


int main(int argc, const char * argv[]) {
    // Create an autorelease pool to manage the memory into the program
    @autoreleasepool {
        
        // Ignore first argument!
        LispFunction plus = ^id(NSArray* args) {
            NSUInteger count = args.count;
            NSInteger result = 0;
            for (int i = 1; i<count; i++) {
                result += [args[i] integerValue];
            }
            return @(result);
        };
        LispFunction minus = ^id(NSArray* args) {
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
        };
        LispFunction multiply = ^id(NSArray* args) {
            NSCParameterAssert(args.count>1);
            NSInteger result = 1;
            NSUInteger count = args.count;
            
            for (int i = 1; i<count; i++) {
                result *= [args[i] integerValue];
            }
            return @(result);
        };
        LispFunction divide = ^id(NSArray* args) {
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
        };
        
        MALEnv* replEnvironment = [[MALEnv alloc] initWithOuterEnvironment: nil];
        
        // Add some functions to the repl environment:
        replEnvironment->data[[@"+" asSymbol]] = plus;
        replEnvironment->data[[@"-" asSymbol]] = minus;
        replEnvironment->data[[@"*" asSymbol]] = multiply;
        replEnvironment->data[[@"/" asSymbol]] = divide;
        
        while (true) {
            char *rawline = readline("user> ");
            if (!rawline) { break; }
            NSString *line = [NSString stringWithUTF8String:rawline];
            if ([line length] == 0) { continue; }
            printf("%s\n", [[REP(line, replEnvironment) description] UTF8String]);
        }
    }
    return 0;
}

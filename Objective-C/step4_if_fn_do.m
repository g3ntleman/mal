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


int main(int argc, const char * argv[]) {
    // Create an autorelease pool to manage the memory into the program
    @autoreleasepool {
        
        
        MALEnv* replEnvironment = [[MALEnv alloc] initWithOuterEnvironment: nil bindings: [MALCoreNameSpace() mutableCopy]];
        
        REP(@"(def! not (fn* (a) (if a false true)))", replEnvironment);
        
//#Warning: a is defined as a symbol and this makes strings "a" appear as symbols. :-(
        
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

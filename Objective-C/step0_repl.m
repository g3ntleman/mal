//
//  step0_repl.m
//  mal
//
//  Created by Dirk Theisen on 26.08.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <readline/readline.h>
#import "step0_repl.h"


id READ(NSString* code) {
    return code;
}

id EVAL(id ast, id env) {
    return ast;
}


NSString* PRINT(id exp) {
    return exp;
}


NSString* REP(NSString* code) {
    return PRINT(EVAL(READ(code), nil));
}


int main(int argc, const char * argv[]) {
    // Create an autorelease pool to manage the memory into the program
    @autoreleasepool {
        while (true) {
            char *rawline = readline("user> ");
            if (!rawline) { break; }
            NSString *line = [NSString stringWithUTF8String:rawline];
            if ([line length] == 0) { continue; }
            printf("%s\n", [[REP(line) description] UTF8String]);
        }
    }
    return 0;
}

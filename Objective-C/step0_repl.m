//
//  step0_repl.m
//  mal
//
//  Created by Dirk Theisen on 26.08.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import <Foundation/Foundation.h>


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
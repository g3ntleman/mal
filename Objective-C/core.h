//
//  MALNamespace.h
//  mal
//
//  Created by Dirk Theisen on 19.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import <Foundation/Foundation.h>

#define EVAL(ast, env) [ast EVAL: env]
#define PRINT(exp) [exp lispDescriptionReadable: YES]
#define pr_str(exp, readably) [exp lispDescriptionReadable: readably]
#define eval_ast(ast, env) [ast eval_ast: env]

NSDictionary* MALCoreNameSpace();

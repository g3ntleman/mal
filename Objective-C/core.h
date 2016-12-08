//
//  MALNamespace.h
//  mal
//
//  Created by Dirk Theisen on 19.09.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PRINT(exp) (exp ? [exp lispDescriptionReadable: YES]: @"nil")
#define pr_str(exp, readably) (exp ? [exp lispDescriptionReadable: readably]: @"nil")
#define eval_ast(ast, env) [ast eval_ast: env]

NSDictionary* MALCoreNameSpace();

id plus_ggx(id a1, ...);

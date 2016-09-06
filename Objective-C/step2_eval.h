//
//  step0_repl.h
//  mal
//
//  Created by Dirk Theisen on 26.08.16.
//  Copyright © 2016 Dirk Theisen. All rights reserved.
//

#ifndef step0_repl_h
#define step0_repl_h

id READ(NSString* code);

id EVAL(id ast, id env);


NSString* PRINT(id exp);


NSString* REP(NSString* code);


#endif
#import <Foundation/Foundation.h>
#import "MALFunction.h"
/*
// Forward declaration of Env (see env.h for full interface)
@class Env;
*/
// Forward declaration of EVAL function
@class MALEnv;

typedef id (^GenericFunction)(NSArray* args);

#define apply(function, args) ((function)->block(args))

id EVAL(id ast, id env);
 
@interface MALFunction : NSObject <NSCopying> {
    @public
    GenericFunction block ;
}

@property (copy) MALEnv* env;
//@property (copy) NSArray* params;
@property (getter=isMacro,setter=setMacro:) BOOL isMacro;
@property (readonly) id meta;

- (id) initWithName: (NSString*) functionName
              block: (GenericFunction) aBlock;

- (id) initWithMetaInfo: (NSDictionary*) meta
                  block: (GenericFunction) aBlock;

@end


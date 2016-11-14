#import <Foundation/Foundation.h>

/*
// Forward declaration of Env (see env.h for full interface)
@class Env;
*/
// Forward declaration of EVAL function
@class MALEnv;

typedef id (^GenericFunction)(NSArray* args);



id EVAL(id ast, id env);
 
@interface MALFunction : NSObject <NSCopying> {
    @public
    GenericFunction block ;
}

@property (copy) MALEnv* env;
//@property (copy) NSArray* params;
@property BOOL isMacro;
@property (readonly) NSMutableDictionary* meta;

- (id) initWithBlock: (GenericFunction) aBlock;

//- (id) apply:(NSArray*) args;

@end

@interface MALMacro : MALFunction

id apply(id f, NSArray* args);

@end

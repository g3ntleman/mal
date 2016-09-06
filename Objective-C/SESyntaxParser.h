//
//  SESyntaxParser.h
//  S-Explorer
//
//  Created by Dirk Theisen on 11.06.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
    /* tokens */
    DOT = 1,
    LEFT_PAR,
    RIGHT_PAR,
    END_OF_INPUT,
    ATOM,
    COMMENT,
    STRING,
    NUMBER,
    CONSTANT,
    QUOTE,
    QUASIQUOTE,
    UNQUOTE,
    SPLICE_UNQUOTE,
    DEREF,
    KEYWORD
} SETokenType;


typedef struct  {
    SETokenType type;
    NSRange range;
    unichar firstChar;
} SETokenOccurrence;

typedef struct  {
    SETokenOccurrence occurrence;
    short depth;
    NSUInteger elementCount;
} SEParserResult;



@class SESyntaxParser;

typedef void (^SESyntaxParserBlock)(SESyntaxParser *parser, SEParserResult result, BOOL* stopRef);

@interface SEExpression : NSObject {
    SETokenOccurrence occurrence;
}

@property (readonly) id value; // can be constants, strings, lists, etc.

- (id) initWithValue: (id) value occurrence: (SETokenOccurrence) occurrence;

- (NSString*) lispDescription;

@end


@interface SESyntaxParser : NSObject

@property (strong, readonly) NSString* string;

- (id) initWithString: (NSString*) sSource
                range: (NSRange) range;

- (SETokenOccurrence) nextToken;

- (void) tokenizeAllWithBlock: (SESyntaxParserBlock) delegateBlock;

- (id) readForm;

@end

extern BOOL isOpeningPar(unichar aChar);
extern BOOL isClosingPar(unichar aChar);
extern unichar matchingPar(unichar aPar);
extern BOOL isPar(unichar aChar);


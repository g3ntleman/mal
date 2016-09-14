//
//  SESyntaxParser.m
//  S-Explorer
//
//  Created by Dirk Theisen on 11.06.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import "SESyntaxParser.h"
#import "NSObject+Types.h"
#import <Foundation/NSNumberFormatter.h>
#import "MALList.h"
#include <ctype.h>

@implementation SESyntaxParser {
    unichar* characters;
    NSUInteger length;
    NSUInteger position;
    NSRange stringRange;
    SETokenOccurrence lastToken;
}

- (id) initWithString: (NSString*) sSource
                range: (NSRange) range {
    
    if (! sSource.length) return nil;
    
    NSParameterAssert(NSMaxRange(range) <= sSource.length);
    
    if (self = [self init]) {
        //delegateBlock = aDelegateBlock;
        _string = sSource;
        length = range.length;
        stringRange = range;
        characters = malloc(sizeof(unichar) * length + 1);
        characters[length] = EOF;
        [sSource getCharacters: characters range: stringRange];
    }
    return self;
}

- (void) dealloc {
    free(characters);
}

- (unichar) getc {
    if (position >= length) return 0;
    return characters[position++];
}

- (unichar) peekc {
    if (position+1 >= length) return 0;
    return characters[position+1];
}

/*_________________Input Routines_________________*/


/* This is the lisp tokenizer; it returns a symbol, or one of `(', `)', `.', or EOF */
- (SETokenOccurrence) nextToken {
    unichar c;
    
    // Skip leading "space" / ignore chars:
    do {
        c = [self getc];
        if (c == ';') {
            // parse line comment:
            lastToken.type = COMMENT;
            lastToken.range.location = position-1;
            lastToken.firstChar = c;
            do c = [self getc]; while (c != '\n' && c);
            lastToken.range.length = position - lastToken.range.location;
            return lastToken;
        }
    } while (c && (isspace(c) || c==','));
    
    lastToken.range.location = position-1;
    lastToken.firstChar = c;
    
    // Beginning of Token found.
    switch (c) {
        case 0: {
            lastToken.type = END_OF_INPUT;
            lastToken.range.length = 0;
            return lastToken;
        }
        case '{':
        case '(':
        case '[': {
            lastToken.type = LEFT_PAR;
            lastToken.range.length = 1;
            return lastToken;
        }
        case '}':
        case ')':
        case ']': {
            lastToken.type = RIGHT_PAR;
            lastToken.range.length = 1;
            return lastToken;
        }
        case '.': {
            lastToken.type = DOT;
            lastToken.range.length = 1;
            return lastToken;
        }
        case '\'': {
            lastToken.type = QUOTE;
            lastToken.range.length = 1;
            return lastToken;
        }
        case '`': {
            lastToken.type = QUASIQUOTE;
            lastToken.range.length = 1;
            return lastToken;
        }
        case '^': {
            lastToken.type = WITH_META;
            lastToken.range.length = 1;
            return lastToken;
        }
            
        case '~': {
            if (position<length && characters[position] == '@') {
                [self getc];
                lastToken.type = SPLICE_UNQUOTE;
                lastToken.range.length = 2;
                return lastToken;
            }
            lastToken.type = UNQUOTE;
            lastToken.range.length = 1;
            return lastToken;
        }
        case '@': {
            lastToken.type = DEREF;
            lastToken.range.length = 1;
            return lastToken;
        }
        case '"': {
            register unichar prev = 0;
            lastToken.type = STRING;
            do {
                prev = c;
                c = [self getc];
            } while (c != 0 && (c != '"' || prev=='\\'));
            lastToken.range.length = position-lastToken.range.location;
            
            return lastToken;
        }

        default:
            
            do {
                c = [self getc];
            } while (c && !isspace(c) && c != ';' && ! isPar(c) && c!=',');
            
            if (c) position -= 1;
            lastToken.range.length = position-lastToken.range.location;
            unichar firstChar = lastToken.firstChar;
            
            switch (firstChar) {
                case '#':
                    lastToken.type = CONSTANT;
                    break;
                    
                case ':':
                    lastToken.type = KEYWORD;
                    break;
                    
                    
                case '-':
                case '+': {
                    if (lastToken.range.length<=1) {
                        lastToken.type = ATOM;
                        break;
                    } // else fall through to number
                    if (firstChar=='+') {
                        // Skip leading '+' - scanner can't handle it.
                        lastToken.range.length -=1;
                        lastToken.range.location +=1;
                    }
                }
                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':
                case '7':
                case '8':
                case '9':
                case '0': {
                    lastToken.type = NUMBER;
                    break;
                }
                case 't': {
                    unichar* token = characters+lastToken.range.location;
                    if (lastToken.range.length==4 && token[1]=='r' && token[2]=='u' && token[3]=='e') {
                        lastToken.type = BOOL_TRUE;
                        break;
                    }
                }
                case 'f': {
                    unichar* token = characters+lastToken.range.location;
                    if (lastToken.range.length==5 && token[1]=='a' && token[2]=='l' && token[3]=='s' && token[3]=='e') {
                        lastToken.type = BOOL_FALSE;
                        break;
                    }
                }
                    
                default:
                    lastToken.type = ATOM;
                    break;
            }
            
    }
    return lastToken;
}

- (SETokenOccurrence) peekToken {
    SETokenOccurrence token = [self nextToken];
    position = token.range.location; // push back position
    return token;
}

- (void) tokenizeAllWithBlock: (SESyntaxParserBlock) delegateBlock {
    
    position = 0;
    SEParserResult pResult;
    pResult.depth = 0;
    pResult.elementCount = 0;
    BOOL stop = NO;
    
    while (! stop && (pResult.occurrence = [self nextToken]).type != END_OF_INPUT) {
        //NSLog(@"Found Token '%@'(%d) at %@", [schemeString substringWithRange:tokenInstance.occurrence], tokenInstance.token, NSStringFromRange(tokenInstance.occurrence));
        
        // Adjust offset from -init:
        pResult.occurrence.range.location += stringRange.location;
        
        switch (pResult.occurrence.type) {
            case LEFT_PAR:
                pResult.depth += 1;
                pResult.elementCount = 0;
                delegateBlock(self, pResult, &stop);
                break;
            case RIGHT_PAR:
                pResult.elementCount = 0;
                delegateBlock(self, pResult, &stop);
                pResult.depth -= 1;
                break;
            case ATOM: 
            case NUMBER:
            case STRING:
                delegateBlock(self, pResult, &stop);
                pResult.elementCount += 1;
                break;
            default:
                delegateBlock(self, pResult, &stop);
                break;
        }
    }
}

/**
 * Also Reads Vectors / Arrays.
 **/
- (id) readList {
    SETokenOccurrence leftPar = [self nextToken];
    
    NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity: 4];
    id element;
    while ((element = [self readForm])) {
        [array addObject: element];
    }
    
    if (lastToken.type != RIGHT_PAR) {
        NSLog(@"Unterminated List starting at %ld", leftPar.range.location);
    } else {
        if (matchingPar(leftPar.firstChar) != lastToken.firstChar) {
            NSLog(@"Unmatched Pars '%C':%ld and '%C':%ld.", leftPar.firstChar, leftPar.range.location, lastToken.firstChar, lastToken.range.location);
        }
    }
    if (leftPar.firstChar == '(') {
        return [MALList listFromArray: array]; // Turn it into a List

    }
    return array;
}


- (id) readMap {
    SETokenOccurrence leftPar = [self nextToken];
    
    if (leftPar.type != LEFT_PAR) {
        NSLog(@"Expected '{' but got '%@'", [NSString stringWithCharacters: &characters[leftPar.range.location] length: leftPar.range.length]);
    }
    
    NSMutableDictionary* map = [[NSMutableDictionary alloc] initWithCapacity: 4];
    id key, value;
    while ((key = [self readForm])) {
        if ((value = [self readForm])) {
            [map setObject: value forKey: key];
        }
    }
    
    if (lastToken.type != RIGHT_PAR) {
        NSLog(@"Unterminated List starting at %ld", leftPar.range.location);
    } else {
        if (matchingPar(leftPar.firstChar) != lastToken.firstChar) {
            NSLog(@"Unterminated List starting at %ld", leftPar.range.location);
        }
    }
    
    return map;
}

- (id) readForm {
    
    do {
        SETokenOccurrence nextToken = [self nextToken];
        switch (nextToken.type) {
            case END_OF_INPUT:
                return nil;
                break;
            case RIGHT_PAR:
                // Signal Error!
                return nil;
                break;
            case COMMENT:
                // NOP
                break;
            case LEFT_PAR:
                position = nextToken.range.location; // push back the reader
                if (nextToken.firstChar == '{') {
                    return [self readMap];
                } else {
                    return [self readList];
                }
                break;
            case NUMBER: {
                NSNumberFormatter* f= [[NSNumberFormatter alloc] init]; // TODO: reuse
                f.numberStyle = NSNumberFormatterDecimalStyle;
                NSString* string = [NSString stringWithCharacters: &characters[nextToken.range.location] length: nextToken.range.length];
                NSNumber* number = [f numberFromString: string];
                return number;
                break;
            }
            case KEYWORD: {
                NSString* keyword = [[NSString stringWithCharacters: &characters[nextToken.range.location] length:nextToken.range.length] asSymbol];
                return keyword;
                break;
            }
            case BOOL_TRUE: {
                return @YES;
                break;
            }
            case BOOL_FALSE: {
                return @NO;
                break;
            }
            case QUOTE:
                return [MALList listFromFirstObject: @"quote" rest: [self readForm]];
                break;
                
            case UNQUOTE:
                return [MALList listFromFirstObject: @"unquote" rest: [self readForm]];
                break;
                
            case SPLICE_UNQUOTE:
                return [MALList listFromFirstObject: @"splice-unquote" rest: [self readForm]];
                break;
                
            case DEREF:
                return [MALList listFromFirstObject: @"deref" rest: [self readForm]];
                break;
                
            case QUASIQUOTE:
                return [MALList listFromFirstObject: @"quasiquote" rest: [self readForm]];
                break;
               
            case WITH_META: {
                id form1 = [self readMap];
                id form2 = [self readForm];
                return [MALList listFromArray: @[@"with-meta", form2, form1]];
                break;
            }
            case ATOM:
                return [[NSString stringWithCharacters: &characters[nextToken.range.location] length:nextToken.range.length] asSymbol];
                break;
            case STRING:
            default:
                return [NSString stringWithCharacters: &characters[nextToken.range.location] length:nextToken.range.length];
                break;
                
                //@throw @"Unexpected Token";
                //break;
        }
    } while (YES);
    
    return nil;
}


@end


inline BOOL isOpeningPar(unichar aChar) {
    return aChar == '(' || aChar == '[' || aChar == '{';
}

inline BOOL isClosingPar(unichar aChar) {
    return aChar == ')' || aChar == ']' || aChar == '}';
}


unichar matchingPar(unichar aPar) {
    switch (aPar) {
        case '(': return ')';
        case ')': return '(';
        case '[': return ']';
        case ']': return '[';
        case '{': return '}';
        case '}': return '{';
    }
    return 0;
}

BOOL isPar(unichar aChar) {
    return matchingPar(aChar) != 0;
}
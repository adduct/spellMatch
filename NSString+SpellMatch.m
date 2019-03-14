//
//  NSString+SpellMatch.m
//
//
//  Created by white on 2019/3/7.
//  Copyright © 2019 white. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "NSString+SpellMatch.h"

@implementation NSString (SpellMatch)

- (nullable NSString *)spellMatch:(NSString *)matchString {
    NSString *spellLetterString = [NSString string];
    NSString *spellString = [NSString string];
    NSArray <NSString *>*spellStringArray = [self __spellStringArrayWithSpellLetter:&spellLetterString spellString:&spellString];
    if ([spellLetterString containsString:matchString] || [spellString containsString:matchString]) {
        return [self __subStringMatchedString:matchString spellString:spellString spellLetter:spellLetterString spellStringArray:spellStringArray];
    } else {
        return nil;
    }
}

- (nullable NSString *)__subStringMatchedString:(NSString *)matchString
                                    spellString:(NSString *)spellString
                                    spellLetter:(NSString *)spellLetter
                               spellStringArray:(NSArray <NSString *>*)spellStringArray {
#ifdef DEBUG
    NSLog(@" string: %@\n match string:%@\n spell string:%@\n spell letter:%@\n spell string array:%@",self,matchString,spellString,spellLetter,spellStringArray);
#endif

    NSUInteger matchStringLen = matchString.length;
    NSUInteger stringLen = self.length;

    BOOL isStringsEmpty = matchString == nil || matchStringLen < 1 || \
    spellString == nil || spellString.length < 1 || \
    spellLetter == nil || spellLetter.length < 1 ;
    if (isStringsEmpty) {
        NSLog(@"parameters are not valid.\nEnsure matchString(%@),spellString(%@) and spellLetter(%@) are all nonempty.",matchString,spellString,spellLetter);
        return nil;
    }

    BOOL isStringValid = matchStringLen <= spellString.length && spellLetter.length <= spellString.length;
    if (!isStringValid) {
        NSLog(@"parameters are not valid.\nEnsure matchString(%@)'s length <= spellString(%@)'s length and\n spellLetter(%@)'s length <= spellString(%@)'s length.",matchString,spellString,spellLetter,spellString);
        return nil;
    }

    BOOL isParamValid = spellStringArray.count == spellLetter.length && spellLetter.length == stringLen;
    if (!isParamValid) {
        NSLog(@"parameters are not valid.\nEnsure spellStringArray(%@)'s length == spellLetter(%@)'s length and\n spellLetter'slength == string(%@)'s length.",spellStringArray,spellLetter,self);
        return nil;
    }

    NSString *matchResultString = nil;
    if (1 == matchStringLen) {
        //match spell letter
        NSRange matchRange = [spellLetter rangeOfString:matchString];
        if (matchRange.length > 0) {
            NSUInteger idx = matchRange.location;
            if (idx < self.length) {
                matchResultString = [self substringWithRange:matchRange];
            }
        }
    } else {
        //first step: match spell letter
        if ([spellLetter rangeOfString:matchString].length > 0) {
            NSRange matchRange = [spellLetter rangeOfString:matchString];

            NSUInteger idx = matchRange.location;
            NSUInteger len = matchRange.length;
            if (idx < stringLen &&
                len <= stringLen &&
                idx + len <= stringLen) {
                matchResultString = [self substringWithRange:matchRange];
            }
        } else {
            //match spell for 1 or more than 1 character
            if ([spellString rangeOfString:matchString].length > 0) {
                NSString *firStr = [matchString substringToIndex:1];
                NSRange firstRange = [spellLetter rangeOfString:firStr];

                BOOL hasFound = NO;
                NSUInteger len = 0;
                NSUInteger locInSpellLetter = firstRange.location;
                while (firstRange.length > 0) {
                    NSMutableString *mutableString = [NSMutableString string];

                    for (NSUInteger idx = locInSpellLetter;idx < spellStringArray.count;idx++) {
                        NSString *str = spellStringArray[idx];
                        [mutableString appendString:str];
                        //check wether matchString is prefix of mutableString
                        //only when mutableString.length >= matchStringLen
                        if (mutableString.length >= matchStringLen) {
                            if ([mutableString hasPrefix:matchString]) {
                                len = idx - locInSpellLetter + 1;
                                hasFound = YES;
                            }

                            break;
                        }//if
                    }//for

                    if (hasFound) {
                        break;
                    } else {
                        //find location of firstStr in the remaing spell letter string.
                        NSString *subSpellLetter = [spellLetter substringFromIndex:locInSpellLetter+1];
                        NSRange spellRange = [subSpellLetter rangeOfString:firStr];
                        firstRange = spellRange;
                        if (spellRange.length > 0) {
                            //location of firstStr in spell letter should be updated
                            locInSpellLetter += spellRange.location + spellRange.length;
                        }
                    }//else
                }//while

                if (hasFound) {
                    NSRange spellRange = NSMakeRange(locInSpellLetter, len);
                    matchResultString = [self substringWithRange:spellRange];
                }
            }//if ([spellString rangeOfString:matchString].length > 0)
        }//else
    }

#ifdef DEBUG
    NSLog(@"matched result string:%@",matchResultString);
#endif
    return matchResultString;
}

- (NSArray <NSString*>*)__spellStringArrayWithSpellLetter:(NSString **)spellLetter spellString:(NSString **)spellString {
    NSMutableString *mutableSpell = [NSMutableString string];
    NSMutableString *mutableSpellLetter = [NSMutableString string];
    NSMutableArray <NSString *>*mutableSpellArray = [NSMutableArray array];
    [self enumerateSubstringsInRange:NSMakeRange(0, self.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        NSMutableString *mutableString = [NSMutableString stringWithString:substring];
        CFStringTransform((CFMutableStringRef)mutableString, NULL, kCFStringTransformToLatin, false);
        NSString *spellString = [mutableString stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]];
        NSString *uppercaseSpell = [spellString uppercaseString];
        [mutableSpell appendString:uppercaseSpell];
        
        NSString *letter = [uppercaseSpell substringToIndex:1];
        [mutableSpellLetter appendString:letter];
        
        [mutableSpellArray addObject:uppercaseSpell];
    }];
    *spellString = [NSString stringWithString:mutableSpell];
    *spellLetter = [NSString stringWithString:mutableSpellLetter];
    
    NSArray <NSString *>*spellStringArray = [NSArray arrayWithArray:mutableSpellArray];
    return spellStringArray;
}

@end

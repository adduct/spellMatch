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

- (nullable NSString *)spellMatch:(nullable NSString *)matchString {
    return [self _spellMatcth:matchString useFullPinyin:NO];
}

- (nullable NSString *)fullSpellMatch:(nullable NSString *)matchString {
    return [self _spellMatcth:matchString useFullPinyin:YES];
}

- (nullable NSArray <__kindof NSString *> *)spellsMatch:(nullable NSString *)matchString {
    return [self _spellsMatcthTo:matchString];
}

- (nullable NSArray <__kindof NSDictionary *> *)spellsWithRangeValuesMatch:(nullable NSString *)matchString {
    return [self _spellsDictionayMatcthTo:matchString];
}

- (nullable NSString *)_spellMatcth:(nullable NSString *)matchString
                      useFullPinyin:(BOOL)fullFlag {
    if (self == nil || self.length == 0 || \
        matchString == nil || matchString.length == 0) {
        return nil;
    }
    
    NSString *spellLetterString = [NSString string];
    NSString *spellString = [NSString string];
    NSArray <NSString *>*spellStringArray = [self __spellStringArrayWithSpellLetter:&spellLetterString
                                                                        spellString:&spellString];
    matchString = [matchString uppercaseString];
    
    if ([spellLetterString containsString:matchString] ||
        [spellString containsString:matchString]) {
        return [self __subStringMatchedString:matchString
                                  spellString:spellString
                                  spellLetter:spellLetterString
                             spellStringArray:spellStringArray
                                    fullMatch:fullFlag];
    } else {
        return nil;
    }
}

- (nullable NSString *)__subStringMatchedString:(nullable NSString *)matchString
                                    spellString:(nullable NSString *)spellString
                                    spellLetter:(nullable NSString *)spellLetter
                               spellStringArray:(nullable NSArray <__kindof NSString *> *)spellStringArray
                                      fullMatch:(BOOL)fullFlag {
#ifdef DEBUG
    NSLog(@" string: %@\n match string:%@\n spell string:%@\n spell letter:%@\n\
          spell string array:%@",self,matchString,spellString,spellLetter,spellStringArray);
#endif

    NSUInteger matchStringLen = matchString.length;
    NSUInteger stringLen = self.length;

    BOOL isStringsEmpty = matchString == nil || matchStringLen < 1 || \
                          spellString == nil || spellString.length < 1 || \
                          spellLetter == nil || spellLetter.length < 1 ;
    if (isStringsEmpty) {
        NSLog(@"parameters are not valid.\nEnsure matchString(%@),spellString(%@)\
              and spellLetter(%@) are all nonempty.",matchString,spellString,spellLetter);
        return nil;
    }

    BOOL isStringValid = matchStringLen <= spellString.length && \
                         spellLetter.length <= spellString.length;
    if (!isStringValid) {
        NSLog(@"parameters are not valid.\nEnsure matchString(%@)'s \
              length <= spellString(%@)'s length and\n spellLetter(%@)'s \
              length <= spellString(%@)'s length.",matchString,spellString,spellLetter,spellString);
        return nil;
    }

    BOOL isParamValid = spellStringArray.count == spellLetter.length && \
                        spellLetter.length == stringLen;
    if (!isParamValid) {
        NSLog(@"parameters are not valid.\nEnsure spellStringArray(%@)'s \
              length == spellLetter(%@)'s length and\n \
              spellLetter'slength == string(%@)'s length.",spellStringArray,spellLetter,self);
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
                            if ([self _fullMatchString:mutableString withString:matchString  fullFlag:fullFlag]) {
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

- (nullable NSArray <__kindof NSString *> *)_spellsMatcthTo:(nullable NSString *)matchString {
    if (self == nil || self.length == 0 || \
        matchString == nil || matchString.length == 0) {
        return nil;
    }
    
    NSString *spellLetterString = [NSString string];
    NSString *spellString = [NSString string];
    NSArray <NSString *>*spellStringArray = [self __spellStringArrayWithSpellLetter:&spellLetterString
                                                                        spellString:&spellString];
    matchString = [matchString uppercaseString];
    
    if ([spellLetterString containsString:matchString] ||
        [spellString containsString:matchString]) {
        return [self __subStringsMatchedString:matchString
                                   spellString:spellString
                                   spellLetter:spellLetterString
                              spellStringArray:spellStringArray];
    } else {
        return nil;
    }
}

- (nullable NSArray <__kindof NSDictionary *> *)_spellsDictionayMatcthTo:(nullable NSString *)matchString {
    if (self == nil || self.length == 0 || \
        matchString == nil || matchString.length == 0) {
        return nil;
    }
    
    NSString *spellLetterString = [NSString string];
    NSString *spellString = [NSString string];
    NSArray <NSString *>*spellStringArray = [self __spellStringArrayWithSpellLetter:&spellLetterString
                                                                        spellString:&spellString];
    matchString = [matchString uppercaseString];
    
    if ([spellLetterString containsString:matchString] ||
        [spellString containsString:matchString]) {
        return [self __subStringsDictionaryMatchedString:matchString
                                             spellString:spellString
                                             spellLetter:spellLetterString
                                        spellStringArray:spellStringArray];
    } else {
        return nil;
    }
}

- (nullable NSArray <__kindof NSString *> *)__subStringsMatchedString:(nullable NSString *)matchString
                                                          spellString:(nullable NSString *)spellString
                                                          spellLetter:(nullable NSString *)spellLetter
                                                     spellStringArray:(nullable NSArray <__kindof NSString *> *)spellStringArray {
#ifdef DEBUG
    NSLog(@" string: %@\n match string:%@\n spell string:%@\n spell letter:%@\n\
          spell string array:%@",self,matchString,spellString,spellLetter,spellStringArray);
#endif

    NSUInteger matchStringLen = matchString.length;
    NSUInteger stringLen = self.length;

    BOOL isStringsEmpty = matchString == nil || matchStringLen < 1 || \
                          spellString == nil || spellString.length < 1 || \
                          spellLetter == nil || spellLetter.length < 1 ;
    if (isStringsEmpty) {
        NSLog(@"parameters are not valid.\nEnsure matchString(%@),spellString(%@)\
              and spellLetter(%@) are all nonempty.",matchString,spellString,spellLetter);
        return nil;
    }

    BOOL isStringValid = matchStringLen <= spellString.length && \
                         spellLetter.length <= spellString.length;
    if (!isStringValid) {
        NSLog(@"parameters are not valid.\nEnsure matchString(%@)'s \
              length <= spellString(%@)'s length and\n spellLetter(%@)'s \
              length <= spellString(%@)'s length.",matchString,spellString,spellLetter,spellString);
        return nil;
    }

    BOOL isParamValid = spellStringArray.count == spellLetter.length && \
                        spellLetter.length == stringLen;
    if (!isParamValid) {
        NSLog(@"parameters are not valid.\nEnsure spellStringArray(%@)'s \
              length == spellLetter(%@)'s length and\n \
              spellLetter'slength == string(%@)'s length.",spellStringArray,spellLetter,self);
        return nil;
    }

    NSMutableArray <__kindof NSString *> *matchResultStringArray = [NSMutableArray arrayWithCapacity:spellStringArray.count];
    if (1 == matchStringLen) {
        //match spell letter
        NSRange matchRange = [spellLetter rangeOfString:matchString];
        for (NSUInteger idx = matchRange.location;idx < spellStringArray.count;idx++) {
            if (spellStringArray[idx].length == 1) {
                if ([self _fullMatchString:spellStringArray[idx] withString:matchString fullFlag:YES]) {
                    matchRange = NSMakeRange(idx, 1);
                    NSString *matchResultString = [self substringWithRange:matchRange];
                    if (matchResultString != nil && matchResultString.length > 0) {
                        [matchResultStringArray addObject:matchResultString];
                    }
                }
            }
        }
    } else {
        //first step: match spell letter
        NSString *matchResultString = [[NSString alloc] init];
        if ([spellLetter rangeOfString:matchString].length > 0) {
            NSRange matchRange = [spellLetter rangeOfString:matchString];

            NSUInteger idx = matchRange.location;
            NSUInteger len = matchRange.length;
            if (idx < stringLen &&
                len <= stringLen &&
                idx + len <= stringLen) {
                matchResultString = [self substringWithRange:matchRange];
                if (matchResultString && matchResultString.length > 0) {
                    [matchResultStringArray addObject:matchResultString];
                }
            }
        } else {
            //match spell for 1 or more than 1 character
            if ([spellString rangeOfString:matchString].length > 0) {
                NSString *firStr = [matchString substringToIndex:1];
                NSRange firstRange = [spellLetter rangeOfString:firStr];

                NSUInteger locInSpellLetter = firstRange.location;
                if (firstRange.length > 0) {
                    for (NSUInteger idx = locInSpellLetter;firstRange.length > 0 &&
                         idx < spellStringArray.count;
                         idx++) {
                        if (locInSpellLetter == spellStringArray.count) {
                            break;
                        }
                        
                        NSString *str = spellStringArray[locInSpellLetter];
                        if ([self _fullMatchString:str withString:matchString  fullFlag:YES]) {
                            // check 1 by 1
                            NSUInteger resultLen = 1;
                            NSRange resultRange = NSMakeRange(locInSpellLetter, resultLen);
                            locInSpellLetter += resultLen;
                            matchResultString = [self substringWithRange:resultRange];
                            if (matchResultString != nil && matchResultString.length > 0) {
                                [matchResultStringArray addObject:matchResultString];
                                #ifdef DEBUG
                                    NSLog(@"matched result string:%@",matchResultString);
                                #endif
                            }
                        } else {
                           NSString *subSpellLetter = [spellLetter substringFromIndex:locInSpellLetter+1];
                           NSRange spellRange = [subSpellLetter rangeOfString:firStr];
                           if (spellRange.length > 0) {
                               firstRange = spellRange;
                               locInSpellLetter += spellRange.location + spellRange.length;
                           }
                        }
                    }//for
                }//while
            }//if ([spellString rangeOfString:matchString].length > 0)
        }//else
    }
    return [matchResultStringArray copy];
}

- (nullable NSArray <__kindof NSDictionary *> *)__subStringsDictionaryMatchedString:(nullable NSString *)matchString
                                                                        spellString:(nullable NSString *)spellString
                                                                        spellLetter:(nullable NSString *)spellLetter
                                                                   spellStringArray:(nullable NSArray <__kindof NSString *> *)spellStringArray {
#ifdef DEBUG
    NSLog(@" string: %@\n match string:%@\n spell string:%@\n spell letter:%@\n\
          spell string array:%@",self,matchString,spellString,spellLetter,spellStringArray);
#endif

    NSUInteger matchStringLen = matchString.length;
    NSUInteger stringLen = self.length;

    BOOL isStringsEmpty = matchString == nil || matchStringLen < 1 || \
                          spellString == nil || spellString.length < 1 || \
                          spellLetter == nil || spellLetter.length < 1 ;
    if (isStringsEmpty) {
        NSLog(@"parameters are not valid.\nEnsure matchString(%@),spellString(%@)\
              and spellLetter(%@) are all nonempty.",matchString,spellString,spellLetter);
        return nil;
    }

    BOOL isStringValid = matchStringLen <= spellString.length && \
                         spellLetter.length <= spellString.length;
    if (!isStringValid) {
        NSLog(@"parameters are not valid.\nEnsure matchString(%@)'s \
              length <= spellString(%@)'s length and\n spellLetter(%@)'s \
              length <= spellString(%@)'s length.",matchString,spellString,spellLetter,spellString);
        return nil;
    }

    BOOL isParamValid = spellStringArray.count == spellLetter.length && \
                        spellLetter.length == stringLen;
    if (!isParamValid) {
        NSLog(@"parameters are not valid.\nEnsure spellStringArray(%@)'s \
              length == spellLetter(%@)'s length and\n \
              spellLetter'slength == string(%@)'s length.",spellStringArray,spellLetter,self);
        return nil;
    }

    NSMutableArray <__kindof NSDictionary *> *matchResultDictionaryArray = [NSMutableArray arrayWithCapacity:spellStringArray.count];
    if (1 == matchStringLen) {
        //match spell letter
        NSRange matchRange = [spellLetter rangeOfString:matchString];
        for (NSUInteger idx = matchRange.location;idx < spellStringArray.count;idx++) {
            if (spellStringArray[idx].length == 1) {
                if ([self _fullMatchString:spellStringArray[idx] withString:matchString fullFlag:YES]) {
                    matchRange = NSMakeRange(idx, 1);
                    NSString *matchResultString = [self substringWithRange:matchRange];
                    if (matchResultString != nil && matchResultString.length > 0) {
                        NSValue *matchRangeValue = [NSValue valueWithRange:matchRange];
                        NSDictionary *matchDictionary = @{matchResultString : matchRangeValue};
                        [matchResultDictionaryArray addObject:matchDictionary];
                    }
                }
            }
        }
    } else {
        //first step: match spell letter
        NSString *matchResultString = [[NSString alloc] init];
        if ([spellLetter rangeOfString:matchString].length > 0) {
            NSRange matchRange = [spellLetter rangeOfString:matchString];

            NSUInteger idx = matchRange.location;
            NSUInteger len = matchRange.length;
            if (idx < stringLen &&
                len <= stringLen &&
                idx + len <= stringLen) {
                matchResultString = [self substringWithRange:matchRange];
                if (matchResultString && matchResultString.length > 0) {
                    [matchResultDictionaryArray addObject:@{matchResultString:[NSValue valueWithRange:matchRange]}];
                }
            }
        } else {
            //match spell for 1 or more than 1 character
            if ([spellString rangeOfString:matchString].length > 0) {
                NSString *firStr = [matchString substringToIndex:1];
                NSRange firstRange = [spellLetter rangeOfString:firStr];

                NSUInteger locInSpellLetter = firstRange.location;
                if (firstRange.length > 0) {
                    for (NSUInteger idx = locInSpellLetter;firstRange.length > 0 &&
                         idx < spellStringArray.count;
                         idx++) {
                        if (locInSpellLetter == spellStringArray.count) {
                            break;
                        }
                        
                        NSString *str = spellStringArray[locInSpellLetter];
                        if ([self _fullMatchString:str withString:matchString  fullFlag:YES]) {
                            // check 1 by 1
                            NSUInteger resultLen = 1;
                            NSRange resultRange = NSMakeRange(locInSpellLetter, resultLen);
                            locInSpellLetter += resultLen;
                            matchResultString = [self substringWithRange:resultRange];
                            if (matchResultString != nil && matchResultString.length > 0) {
                                [matchResultDictionaryArray addObject:@{matchResultString : [NSValue valueWithRange:resultRange]}];
                                #ifdef DEBUG
                                    NSLog(@"matched result string:%@",matchResultString);
                                #endif
                            }
                        } else {
                           NSString *subSpellLetter = [spellLetter substringFromIndex:locInSpellLetter+1];
                           NSRange spellRange = [subSpellLetter rangeOfString:firStr];
                           if (spellRange.length > 0) {
                               firstRange = spellRange;
                               locInSpellLetter += spellRange.location + spellRange.length;
                           }
                        }
                    }//for
                }//while
            }//if ([spellString rangeOfString:matchString].length > 0)
        }//else
    }
    return [matchResultDictionaryArray copy];
}

- (BOOL)_fullMatchString:(nonnull NSString *)str
              withString:(nonnull NSString *)matchString
                fullFlag:(BOOL)fullFlag {
    if (fullFlag) {
        return [str isEqualToString:matchString];
    } else {
        return [str hasPrefix:matchString];
    }
}

- (NSArray <__kindof NSString*> *)__spellStringArrayWithSpellLetter:(NSString **)spellLetter
                                                        spellString:(NSString **)spellString {
    NSMutableString *mutableSpell = [NSMutableString string];
    NSMutableString *mutableSpellLetter = [NSMutableString string];
    NSMutableArray <NSString *>*mutableSpellArray = [NSMutableArray array];
    [self enumerateSubstringsInRange:NSMakeRange(0, self.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
                              NSMutableString *mutableString = [NSMutableString stringWithString:substring];
                              CFStringTransform((CFMutableStringRef)mutableString, NULL, kCFStringTransformToLatin, false);
                              NSLocale *currentLocale = [self _chineseLocale];
                              NSString *spellString = [mutableString stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:currentLocale];
                              
                              NSString *uppercaseSpell = [spellString uppercaseString];
                              if (uppercaseSpell && uppercaseSpell.length > 0) {
                                  [mutableSpell appendString:uppercaseSpell];
                                  NSString *letter = [uppercaseSpell substringToIndex:1];
                                  [mutableSpellLetter appendString:letter];
                                  [mutableSpellArray addObject:uppercaseSpell];
                              } else {
#ifdef DEBUG
                                  NSLog(@"uppercaseSpell is nil converted from substring:%@",substring);
#endif
                              }
                          }];
    *spellString = [NSString stringWithString:mutableSpell];
    *spellLetter = [NSString stringWithString:mutableSpellLetter];
    
    NSArray <__kindof NSString *> *spellStringArray = [NSArray arrayWithArray:mutableSpellArray];
    return spellStringArray;
}

//chinese locale
- (NSLocale *)_chineseLocale {
    NSLocale *chLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh-Hans"];
    
    if (@available(iOS 9, *)) {
        chLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh-Hans-CN"];
    }
    
    return chLocale;
}

@end

//
//  NSString+SpellMatch.m
//
//
//  Created by white on 2019/1/24.
//  Copyright © 2019 NetEase. All rights reserved.
//

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
    BOOL isStringsEmpty = matchString == nil || matchString.length < 1 || \
    spellString == nil || spellString.length < 1 || \
    spellLetter == nil || spellLetter.length < 1 ;
    if (isStringsEmpty) {
        return nil;
    }
    
    BOOL isStringValid = matchString.length <= spellString.length && spellLetter.length <= spellString.length;
    if (!isStringValid) {
        return nil;
    }
    
    if (1 == matchString.length) {
        if ([spellLetter rangeOfString:matchString].length > 0) {
            NSUInteger idx = [spellLetter rangeOfString:matchString].location;
            if (idx < self.length) {
                return [self substringWithRange:[spellLetter rangeOfString:matchString]];
            }
        }
    } else {
        if ([spellLetter rangeOfString:matchString].length > 0) {
            NSRange matchRange = [spellLetter rangeOfString:matchString];
            
            NSUInteger idx = matchRange.location;
            NSUInteger len = matchRange.length;
            if (idx < self.length &&
                len <= self.length &&
                idx+len <= self.length) {
                return [self substringWithRange:matchRange];
            }
        } else {
            if ([spellString rangeOfString:matchString].length > 0) {
                if (spellLetter.length == spellStringArray.count) {
                    NSString *firStr = [matchString substringToIndex:1];
                    NSRange firstRange = [spellLetter rangeOfString:firStr];
                    
                    BOOL hasFound = NO;
                    NSUInteger len = 0;
                    
                    NSUInteger locInSpellLetter = firstRange.location;
                    while (!hasFound && firstRange.length > 0) {
                        NSMutableString *mutableString = [NSMutableString string];
                        
                        for (NSUInteger idx = locInSpellLetter;idx < spellStringArray.count;idx++) {
                            NSString *str = spellStringArray[idx];
                            
                            [mutableString appendString:str];
                            if ([mutableString hasPrefix:matchString]) {
                                if (locInSpellLetter < self.length &&
                                    idx - locInSpellLetter < self.length &&
                                    idx + 1 <= self.length) {
                                    len = idx - locInSpellLetter + 1;
                                    hasFound = YES;
                                    break;
                                }//if
                            }//if
                        }
                        
                        if (!hasFound) {
                            NSString *subSpellLetter = [spellLetter substringFromIndex:locInSpellLetter+1];
                            NSRange newRange = [subSpellLetter rangeOfString:firStr];
                            firstRange = newRange;
                            if (newRange.length > 0) {
                                locInSpellLetter += newRange.location + newRange.length;
                            }
                        }
                    }//while
                    
                    if (hasFound) {
                        if (locInSpellLetter < self.length &&
                            len <= self.length &&
                            locInSpellLetter + len <= self.length) {
                            NSRange newRange = NSMakeRange(locInSpellLetter, len);
                            return [self substringWithRange:newRange];
                        }
                    }
                //if (spellLetter.length == spellStringArray.count)
                } else {
                    NSAssert(NO, @"error. spell letter's:%@ length should be equal to array.count",spellLetter);
                    return nil;
                }                
            }
        }
    }
    return nil;
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

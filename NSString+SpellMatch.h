//
//  NSString+SpellMatch.h
//  
//
//  Created by white on 2019/3/7.
//  Copyright © 2019. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (SpellMatch)
/**
 matching string result
 
 @param matchString string that will be use to match
 @return matching string result. return nil if none
 */
- (nullable NSString *)spellMatch:(NSString *)matchString;
@end

NS_ASSUME_NONNULL_END

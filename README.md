# NSString+SpellMatch
This NSString category is a useful function for match spell or spell first letter of string.
It can match the spell's first letter or uncompleted spell string. Then returns the matched string.
It not rely any third party code.

For example:
To search "风雨" in "阳光总在风雨后"。
You can just input:
1. pinyin's first letter: 

    fy or Fy, fY, FY.

The uppercase state doesn't matter.
Where f is the first letter of "风"'s pinyin string(feng), 
y is the first letter of "雨"'s pinyin string(yu), ;

Or input :
2. complete pinying string：

    fengyu



3. incomplete pinying string: 

    fengy



# Features
Match spell's first letter; or match spell string
# Installation
Just add the following 2 files into your project:

    NSString+SpellMatch.h
    NSString+SpellMatch.m

# Usage:
Create an NSString object(ie. **str**) your will be searching for.
Use function:

    [str spellMatch:matchString];
or

    [str fullSpellMatch:matchString];

where:
parameter: "matchString" is a nullable string to be matched.

# More details:
See this website address for function design details.
https://www.jianshu.com/p/33f29eb598d9

# Licence
SpellMatch category is available under the MIT license. See the LICENSE file for detail.

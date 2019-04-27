# NSString+SpellMatch
This NSString category provides 2 useful functions. One function provide matching spell in string, another one provides searching spell's first letter in string.
It can match uncompleted spell string. 
It not rely on any third party's code.

For example:
To search "风雨" in "阳光总在风雨后",
You can just input:
1. pinyin's first letter: 

    fy or Fy, fY, FY.

The uppercase state doesn't matter.
Where f is the first letter of "风"'s pinyin string: feng, 
y is the first letter of "雨"'s pinyin string: yu;

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
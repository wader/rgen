//
//  NSString+extra.m
//  rgen
//
//  Created by Mattias Wadman on 2011-02-17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSString+toCamelCase.h"

// based on http://stackoverflow.com/questions/1918972
@implementation NSString (toCamelCase)
- (NSString *)toCamelCase:(NSCharacterSet *)charSet {
  NSMutableString *output = [NSMutableString string];
  
  BOOL makeNextCharacterUpperCase = NO;
  for (NSInteger idx = 0; idx < [self length]; idx += 1) {
    unichar c = [self characterAtIndex:idx];
    if ([charSet characterIsMember:c]) {
      makeNextCharacterUpperCase = YES;
    } else if (makeNextCharacterUpperCase) {
      [output appendString:[[NSString stringWithCharacters:&c length:1]
			    uppercaseString]];
      makeNextCharacterUpperCase = NO;
    } else {
      [output appendString:[[NSString stringWithCharacters:&c length:1]
			    lowercaseString]];
    }
  }
  
  return output;
}
@end
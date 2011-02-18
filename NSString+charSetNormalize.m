//
//  NSString+charSetNormalize.m
//  rgen
//
//  Created by Mattias Wadman on 2011-02-17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSString+charSetNormalize.h"

@implementation NSString (charSetNormalize)
- (NSString *)charSetNormalize:(NSCharacterSet *)charSet {
  NSMutableString *output = [NSMutableString string];
  
  for (NSInteger idx = 0; idx < [self length]; idx += 1) {
    unichar c = [self characterAtIndex:idx];
    if (![charSet characterIsMember:c]) {
      continue;
    }
    
    [output appendString:[NSString stringWithCharacters:&c length:1]];
  }
  
  return output;
}
@end
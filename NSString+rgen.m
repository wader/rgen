//
//  NSString+rgen.m
//  rgen
//
//  Created by Mattias Wadman on 2011-02-26.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSString+rgen.h"

@implementation NSString (rgen)

// based on http://stackoverflow.com/questions/1918972
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

- (NSString *)charSetNormalize:(NSCharacterSet *)charSet {
  NSMutableString *output = [NSMutableString string];
  
  for (NSInteger i = 0; i < [self length]; i++) {
    unichar c = [self characterAtIndex:i];
    if (![charSet characterIsMember:c]) {
      continue;
    }
    
    [output appendString:[NSString stringWithCharacters:&c length:1]];
  }
  
  return output;
}

- (NSString *)stripSuffix:(NSArray *)suffixes {
  for (NSString *suffix in suffixes) {
    if ([self hasSuffix:suffix]) {
      return [self substringToIndex:[self length] - [suffix length]];
    }
  }
  
  return self;
}

- (NSString *)escapeCString {
  return [self stringByReplacingOccurrencesOfString:@"\""
					 withString:@"\\\""];
}

@end
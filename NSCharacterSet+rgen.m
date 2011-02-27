//
//  NSSet+rgen.m
//  rgen
//
//  Created by Mattias Wadman on 2011-02-27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSCharacterSet+rgen.h"

@implementation NSCharacterSet (rgen)

+ (NSCharacterSet *)propertyNameCharacterSet {
  static NSCharacterSet *charSet = nil;
  if (charSet == nil) {
    charSet = [[NSCharacterSet characterSetWithCharactersInString:
		@"abcdefghijklmnopqrstuvwxyz"
		@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		@"_0123456789"]
	       retain];
  }
  
  return charSet;
}

+ (NSCharacterSet *)propertyNameStartCharacterSet {
  static NSCharacterSet *charSet = nil;
  if (charSet == nil) {
    charSet = [[NSCharacterSet characterSetWithCharactersInString:
		@"abcdefghijklmnopqrstuvwxyz"
		@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		@"_"]
	       retain];
  }
  
  return charSet;
}

@end

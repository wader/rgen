//
//  NSString+rgen.m
//  rgen
//
//  Created by Mattias Wadman on 2011-02-26.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSString+rgen.h"
#import "NSCharacterSet+rgen.h"

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

// avoid C keywords and some Objective-C stuff
- (BOOL)isReservedRgenName {
  static NSSet *names = nil;
  if (names == nil) {
    names = [[NSSet setWithObjects:
	      @"alloc",
	      @"autorelease",
	      @"bycopy",
	      @"byref",
	      @"char",
	      @"const",
	      @"copy",
	      @"dealloc",
	      @"default",
	      @"delete",
	      @"double",
	      @"float",
	      @"id",
	      @"in",
	      @"inout",
	      @"int",
	      @"long",
	      @"new",
	      @"nil",
	      @"oneway",
	      @"out",
	      @"release",
	      @"retain",
	      @"self",
	      @"short",
	      @"signed",
	      @"super",
	      @"unsigned",
	      @"void",
	      @"volatile",
	      // rgen reserved
	      @"loadImages",
	      @"releaseImages",
	      nil]
	     retain];
  }
  
  return [names containsObject:self];  
}

- (BOOL)isSupportedImageExtByIOS {
  static NSSet *exts = nil;
  if (exts == nil) {
    // from UIImage class reference "Supported Image Formats"
    exts = [[NSSet setWithObjects:
	     @"tiff", @"tif",
	     @"jpg", @"jpeg",
	     @"gif",
	     @"png",
	     @"bmp", @"bmpf",
	     @"ico",
	     @"cur",
	     @"xbm",
	     nil]
	    retain];
  }
  
  return [exts containsObject:self];
}

+ (NSArray *)imageScaleSuffixArray {
  static NSArray *suffixes = nil;
  if (suffixes == nil) {
    suffixes = [[NSArray arrayWithObjects:
		 @"@2x",
		 nil]
		retain];
  }
  
  return suffixes;
}

- (NSString *)normalizIOSPath {
  if ([[[self pathExtension] lowercaseString] isSupportedImageExtByIOS]) {
    return [[[self stringByDeletingPathExtension]
	     stripSuffix:[[self class] imageScaleSuffixArray]]
	    stringByAppendingPathExtension:[self pathExtension]];
  }
  
  return self;
}

- (NSString *)propertyNameIsDir:(BOOL)isDir {
  NSString *name = self;
  if (!isDir) {
    NSString *ext = [[name pathExtension] lowercaseString];
    name = [self stringByDeletingPathExtension];
    
    if ([ext isSupportedImageExtByIOS]) {
      name = [name stripSuffix:[[self class] imageScaleSuffixArray]];
    }
  }
  
  name = [[name toCamelCase:
	   [NSCharacterSet characterSetWithCharactersInString:@"._-"]]
	  charSetNormalize:
	  [NSCharacterSet propertyNameCharacterSet]];
  
  if ([name isReservedRgenName]) {
    name = [name stringByAppendingString:@"_"];
  }
  
  if (![[NSCharacterSet propertyNameStartCharacterSet]
	characterIsMember:[name characterAtIndex:0]]) {
    name = [@"_" stringByAppendingString:name];
  }
  
  return name;
}

@end
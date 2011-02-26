//
//  NSString+rgen.h
//  rgen
//
//  Created by Mattias Wadman on 2011-02-26.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (rgen)
- (NSString *)toCamelCase:(NSCharacterSet *)charSet;
- (NSString *)charSetNormalize:(NSCharacterSet *)charSet;
- (NSString *)stripSuffix:(NSArray *)suffixes;
- (NSString *)escapeCString;
@end

//
//  NSString+extra.h
//  rgen
//
//  Created by Mattias Wadman on 2011-02-17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// adapted from http://stackoverflow.com/questions/1918972
@interface NSString (toCamelCase)
- (NSString *)toCamelCase:(NSCharacterSet *)charSet;
@end


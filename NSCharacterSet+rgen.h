//
//  NSSet+rgen.h
//  rgen
//
//  Created by Mattias Wadman on 2011-02-27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSCharacterSet (rgen)
+ (NSCharacterSet *)propertyNameCharacterSet;
+ (NSCharacterSet *)propertyNameStartCharacterSet;
+ (NSCharacterSet *)classNameCharacterSet;
+ (NSCharacterSet *)classNameStartCharacterSet;
@end

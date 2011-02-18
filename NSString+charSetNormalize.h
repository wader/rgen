//
//  NSString+charSetNormalize.h
//  rgen
//
//  Created by Mattias Wadman on 2011-02-17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSString (charSetNormalize)
- (NSString *)charSetNormalize:(NSCharacterSet *)charSet;
@end

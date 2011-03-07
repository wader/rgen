//
//  PathProperty.m
//  rgen
//
//  Created by Mattias Wadman on 2011-02-27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PathProperty.h"
#import "NSString+rgen.h"

@implementation PathProperty

- (void)generate:(ClassGenerator *)classGenerator
       generator:(ResourcesGenerator *)generator {
  [classGenerator
   addPropertyName:self.name
   line:@"@property(nonatomic, readonly) NSString *%@; // %@",
   self.name,
   self.path];
  
  [classGenerator addSynthesizerName:self.name
				line:@"@synthesize %@;", self.name];
  
  ClassMethod *method = [classGenerator
			 addMethodName:self.name
			 declaration:NO
			 signature:@"- (NSString *)%@", self.name];
  [method
   addLineIndent:1
   format:
   @"return p(@\"%@\");",
   [self.path escapeCString]];
}
@end

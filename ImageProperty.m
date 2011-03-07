//
//  ImageProperty.m
//  rgen
//
//  Created by Mattias Wadman on 2011-02-27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ImageProperty.h"
#import "ClassGenerator.h"
#import "NSString+rgen.h"

@implementation ImageProperty : Property

- (void)generate:(ClassGenerator *)classGenerator
       generator:(ResourcesGenerator *)generator {
  [classGenerator
   addPropertyName:self.name
   line:@"@property(nonatomic, readonly) UIImage *%@; // %@",
   self.name,
   self.path];
  
  [classGenerator addSynthesizerName:self.name
				line:@"@synthesize %@;", self.name];
  
  ClassMethod *method = [classGenerator
			 addMethodName:self.name
			 declaration:NO
			 signature:@"- (UIImage *)%@", self.name];
  if (generator.optionLoadImages) {
    [classGenerator
     addVariableName:self.name
     line:@"UIImage *%@;",
     self.name];
    
    [method
     addLineIndent:1
     format:
     @"return self->%@ == nil ? i(@\"%@\") : [[self->%@ retain] autorelease];",
     self.name,
     [self.path escapeCString],
     self.name];
  } else {
    [method
     addLineIndent:1
     format:
     @"return i(@\"%@\");",
     [self.path escapeCString]];
  }
}

@end
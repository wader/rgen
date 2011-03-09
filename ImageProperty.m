/*
 * ImageProperty.m, image property
 *
 * Copyright (c) 2011 <mattias.wadman@gmail.com>
 *
 * MIT License:
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "ImageProperty.h"
#import "ClassGenerator.h"
#import "ResourcesGenerator.h"
#import "NSString+rgen.h"

@implementation ImageProperty : Property

- (void)generate:(ClassGenerator *)classGenerator
       generator:(ResourcesGenerator *)generator {
  [classGenerator
   addPropertyName:self.name
   line:@"@property(nonatomic, readonly) UIImage *%@; // %@",
   self.name,
   self.path];
  
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
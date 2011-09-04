/*
 * ImagesProperty.m, concrete class representing a directory with images
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

#import "ImagesProperty.h"
#import "ImageProperty.h"
#import "ClassGenerator.h"
#import "ResourcesGenerator.h"
#import "NSString+rgen.h"

@implementation ImagesProperty : ClassProperty

- (NSString *)headerProlog:(ResourcesGenerator *)generator {
  return [NSString stringWithFormat:@"%@ *I;\n", self.className];
}

- (NSString *)implementationProlog:(ResourcesGenerator *)generator {
  NSMutableString *s = [NSMutableString string];
  NSMutableArray *ipadSuffixes = [NSMutableArray array];
  if (generator.optionIpadImageSuffx) {
    [ipadSuffixes addObject:@"@ipad"];
  }
  if (generator.optionIpad2xImageSuffx) {
    [ipadSuffixes addObject:@"@2x"];
  }
  
  MethodGenerator *iMethod = [[[MethodGenerator alloc]
			       initWithSignature:@"static UIImage *i(NSString *path)"]
			      autorelease];
  if ([ipadSuffixes count] > 0) {
    MethodGenerator *isIpadMethod = [[[MethodGenerator alloc] 
				      initWithSignature:@"static BOOL isPad()"]
				     autorelease];
    [isIpadMethod addLineIndent:0 format:@"#ifdef UI_USER_INTERFACE_IDIOM"];
    [isIpadMethod addLineIndent:1 format:@"return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);"];
    [isIpadMethod addLineIndent:0 format:@"#else"];
    [isIpadMethod addLineIndent:1 format:@"return NO;"];
    [isIpadMethod addLineIndent:0 format:@"#endif"];
    [s appendFormat:@"%@\n", isIpadMethod];
    
    [iMethod addLineIndent:1 format:@"if (isPad()) {"];
    [iMethod addLineIndent:2 format:@"static NSArray *suffixes = nil;"];
    [iMethod addLineIndent:2 format:@"if (suffixes == nil) {"];
    
    NSMutableString *arrayString = [NSMutableString string];
    for (NSString *suffix in ipadSuffixes) {
      [arrayString appendFormat:@"@\"%@\", ", suffix];
    }
    [arrayString appendString:@"nil"];
    [iMethod addLineIndent:3 format:
     @"suffixes = [NSArray arrayWithObjects:%@];",
     arrayString];
    
    [iMethod addLineIndent:2 format:@"}"];
    [iMethod addLineIndent:2 format:@"NSString *prefix = [path stringByDeletingPathExtension];"];
    [iMethod addLineIndent:2 format:@"NSString *ext = [path pathExtension];"];
    [iMethod addLineIndent:2 format:@"for (NSString *suffix in suffixes) {"];
    [iMethod addLineIndent:3 format:@"UIImage *image = [UIImage imageNamed:[[prefix stringByAppendingString:suffix] stringByAppendingPathExtension:ext]];"];
    [iMethod addLineIndent:3 format:@"if (image != nil) {"];
    [iMethod addLineIndent:4 format:@"return image;"];
    [iMethod addLineIndent:3 format:@"}"];
    [iMethod addLineIndent:2 format:@"}"];
    [iMethod addLineIndent:1 format:@"}"];
  }
  [iMethod addLineIndent:1 format:@"return [UIImage imageNamed:path];"];
  
  [s appendFormat:@"%@\n", iMethod];
  [s appendFormat:@"%@ *I;\n", self.className];
  
  return s;
}

- (void)generate:(ClassGenerator *)classGenerator
       generator:(ResourcesGenerator *)generator {
  if (self.parent == nil) {
    MethodGenerator *loadMethod = [classGenerator addMethodName:@"0load"
						    declaration:NO
						      signature:@"+ (void)load"];
    [loadMethod
     addLineIndent:1
     format:@"I = [[%@ alloc] init];", self.className];
  }
  
  if ([self countPropertiesOfClass:[self class]] > 0) {
    MethodGenerator *initMethod = [classGenerator addMethodName:@"1init"
						    declaration:NO
						      signature:@"- (id)init"];
    [initMethod addLineIndent:1 format:@"self = [super init];"];
    
    [self forEachPropertyOfClass:[ImagesProperty class] block:^(Property *property) {
      ImagesProperty *imagesProperty = (ImagesProperty *)property;
      
      [classGenerator
       addVariableName:imagesProperty.name
       line:@"%@ *%@;",
       imagesProperty.className,
       imagesProperty.name];
      
      [classGenerator
       addPropertyName:imagesProperty.name
       line:@"@property(nonatomic, readonly) %@ *%@; //!< %@",
       imagesProperty.className,
       imagesProperty.name,
       imagesProperty.path];
      
      [classGenerator
       addSynthesizerName:imagesProperty.name
       line:@"@synthesize %@;",
       imagesProperty.name];
      
      [initMethod
       addLineIndent:1
       format:@"self->%@ = [[%@ alloc] init];",
       imagesProperty.name,
       imagesProperty.className];
    }];
    
    [initMethod addLineIndent:1 format:@"return self;"];
  }
  
  if (generator.optionLoadImages) {
    MethodGenerator *loadImagesMethod = [classGenerator
					 addMethodName:@"2loadImages"
                                         comment:@"//! Load and retain images recursively"
					 declaration:YES
					 signature:@"- (void)loadImages"];
    MethodGenerator *releaseImagesMethod = [classGenerator
					    addMethodName:@"3releaseImages"
                                            comment:@"//! Release images recursively"
					    declaration:YES
					    signature:@"- (void)releaseImages"];
    [self forEachProperty:^(Property *property) {
      if ([property isKindOfClass:[ImageProperty class]]) {
	ImageProperty *imageProperty = (ImageProperty *)property;
        
	[loadImagesMethod
	 addLineIndent:1
	 format:@"self->%@ = self->%@ != nil ? self->%@ : [i(@\"%@\") retain];",
	 imageProperty.name,
	 imageProperty.name,
	 imageProperty.name,
	 [imageProperty.path escapeCString]];
        
	[releaseImagesMethod
	 addLineIndent:1
	 format:@"[self->%@ release];",
	 imageProperty.name];
	[releaseImagesMethod
	 addLineIndent:1
	 format:@"self->%@ = nil;",
	 imageProperty.name];
      } else if ([property isKindOfClass:[ImagesProperty class]]) {
	ImagesProperty *imagesProperty = (ImagesProperty *)property;
        
	[loadImagesMethod
	 addLineIndent:1
	 format:@"[self->%@ loadImages];",
	 imagesProperty.name];
        
	[releaseImagesMethod
	 addLineIndent:1
	 format:@"[self->%@ releaseImages];",
	 imagesProperty.name];
      }
    }];
  }
  
  [self forEachPropertyOfClass:[ImageProperty class] block:^(Property *property) {
    [((ImageProperty *)property) generate:classGenerator generator:generator];
  }];
}

@end

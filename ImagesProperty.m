//
//  ImagesProperty.m
//  rgen
//
//  Created by Mattias Wadman on 2011-02-27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ImagesProperty.h"
#import "ImageProperty.h"
#import "ClassGenerator.h"
#import "NSString+rgen.h"

@implementation ImagesProperty : ClassProperty

- (NSString *)headerProlog:(ResourcesGenerator *)generator {
  return [NSString stringWithFormat:@"%@ *I;\n", self.className];
}

- (NSString *)implementationProlog:(ResourcesGenerator *)generator {
  NSMutableString *s = [NSMutableString string];
  
  if (generator.optionIpadImageSuffx) {
    ClassMethod *isIpadMethod = [[[ClassMethod alloc] 
				  initWithSignature:@"static BOOL isPad()"]
				 autorelease];
    [isIpadMethod addLineIndent:0 format:@"#ifdef UI_USER_INTERFACE_IDIOM"];
    [isIpadMethod addLineIndent:1 format:@"return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);"];
    [isIpadMethod addLineIndent:0 format:@"#else"];
    [isIpadMethod addLineIndent:1 format:@"return NO;"];
    [isIpadMethod addLineIndent:0 format:@"#endif"];
    
    [s appendFormat:@"%@\n", isIpadMethod];
  }
  
  ClassMethod *iMethod = [[[ClassMethod alloc] 
			   initWithSignature:@"static UIImage *i(NSString *path)"]
			  autorelease];
  if (generator.optionIpadImageSuffx) {
    [iMethod addLineIndent:1 format:@"if (isPad()) {"];
    [iMethod addLineIndent:2 format:@"NSString *prefix = [path stringByDeletingPathExtension];"];
    [iMethod addLineIndent:2 format:@"NSString *ext = [path pathExtension];"];
    [iMethod addLineIndent:2 format:
     @"for (NSString *suffix in [NSArray arrayWithObjects:%@, nil]) {",
     generator.optionIpad2xImageSuffx ? @"@\"@ipad\", @\"@2x\"" : @"@\"@ipad\""];
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
    ClassMethod *loadMethod = [classGenerator addMethodName:@"0load"
						declaration:NO
						  signature:@"+ (void)load"];
    [loadMethod
     addLineIndent:1
     format:@"I = [[%@ alloc] init];", self.className];
  }
  
  ClassMethod *initMethod = [classGenerator addMethodName:@"1init"
					      declaration:NO
						signature:@"- (id)init"];
  [initMethod addLineIndent:1 format:@"self = [super init];"];
  for(ImagesProperty *imagesProperty in [self.properties allValues]) {
    if (![imagesProperty isKindOfClass:[ImagesProperty class]]) {
      continue;
    }
    
    [classGenerator
     addVariableName:imagesProperty.name
     line:@"%@ *%@;",
     imagesProperty.className,
     imagesProperty.name];
    
    [classGenerator
     addPropertyName:imagesProperty.name
     line:@"@property(nonatomic, readonly) %@ *%@; // %@",
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
  }
  [initMethod addLineIndent:1 format:@"return self;"];
  
  if (generator.optionLoadImages) {
    ClassMethod *loadImagesMethod = [classGenerator
				     addMethodName:@"loadImages"
				     declaration:YES
				     signature:@"- (void)loadImages"];
    for(Property *property in [self.properties allValues]) {
      if ([property isKindOfClass:[ImageProperty class]]) {
	ImageProperty *imageProperty = (ImageProperty *)property;
	[loadImagesMethod
	 addLineIndent:1
	 format:@"self->%@ = [i(@\"%@\") retain];",
	 imageProperty.name,
	 [imageProperty.path escapeCString]];
      } else if ([property isKindOfClass:[ImagesProperty class]]) {
	ImagesProperty *imagesProperty = (ImagesProperty *)property;
	[loadImagesMethod
	 addLineIndent:1
	 format:@"[self->%@ loadImages];",
	 imagesProperty.name];
      }
    }
    
    ClassMethod *releaseImagesMethod = [classGenerator
					addMethodName:@"releaseImages"
					declaration:YES
					signature:@"- (void)releaseImages"];
    for(Property *property in [self.properties allValues]) {
      if ([property isKindOfClass:[ImageProperty class]]) {
	ImageProperty *imageProperty = (ImageProperty *)property;
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
	[releaseImagesMethod
	 addLineIndent:1
	 format:@"[self->%@ releaseImages];",
	 imagesProperty.name];
      }
    }
  }
  
  for(ImageProperty *imageProperty in [self.properties allValues]) {
    if (![imageProperty isKindOfClass:[ImageProperty class]]) {
      continue;
    }
    
    [imageProperty generate:classGenerator generator:generator];
  }
}

@end

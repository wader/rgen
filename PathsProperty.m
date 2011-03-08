/*
 * PathsProperty.m, concrete class representing a directory with files
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

#import "PathsProperty.h"
#import "PathProperty.h"
#import "ClassGenerator.h"
#import "NSString+rgen.h"

@implementation PathsProperty

+ (ClassGenerator *)descriptionStringClass {
  static ClassGenerator *c = nil;
  if (c == nil) {
    c = [[[ClassGenerator alloc]
	  initWithClassName:@"DescriptionString"
	  inheritName:@"NSString"]
	 autorelease];
    [[c addMethodName:@"length"
	  declaration:NO
	    signature:@"- (NSUInteger)length"]
     addLineIndent:1
     format:@"return [[self description] length];"];
    [[c addMethodName:@"characterAtIndex:"
	  declaration:NO
	    signature:@"- (unichar)characterAtIndex:(NSUInteger)index"]
     addLineIndent:1
     format:@"return [[self description] characterAtIndex:index];"];
    [[c addMethodName:@"getCharacters:range:"
	  declaration:NO
	    signature:@"- (void)getCharacters:(unichar *)buffer range:(NSRange)aRange"]
     addLineIndent:1
     format:@"return [[self description] getCharacters:buffer range:aRange];"];
  }
  
  return c;
}

- (NSString *)headerProlog:(ResourcesGenerator *)generator {
  return [NSString stringWithFormat:
	  @"%@"
	  @"\n"
	  @"%@ *P;\n",
	  [[[self class] descriptionStringClass] header],
	  self.className];
}

- (NSString *)implementationProlog:(ResourcesGenerator *)generator {
  ClassMethod *pMethod = [[[ClassMethod alloc] 
			   initWithSignature:@"static NSString *p(NSString *path)"]
			  autorelease];
  [pMethod addLineIndent:1 format:@"static NSString *resourcePath = nil;"];
  [pMethod addLineIndent:1 format:@"if (resourcePath == nil) {"];
  [pMethod addLineIndent:2 format:@"resourcePath = [[[NSBundle mainBundle] resourcePath] retain];"];
  [pMethod addLineIndent:1 format:@"}"];
  [pMethod addLineIndent:1 format:@"return [resourcePath stringByAppendingPathComponent:path];"];
  
  return [NSString stringWithFormat:
	  @"%@"
	  @"\n"
	  @"%@"
	  @"\n"
	  @"%@ *P;\n",
	  pMethod,
	  [[[self class] descriptionStringClass] implementation],
	  self.className];
}

- (NSString *)inheritClassName {
  return @"DescriptionString";
}

- (void)generate:(ClassGenerator *)classGenerator
       generator:(ResourcesGenerator *)generator {
  if (self.parent == nil) {
    ClassMethod *loadMethod = [classGenerator addMethodName:@"0load"
						declaration:NO
						  signature:@"+ (void)load"];
    [loadMethod
     addLineIndent:1
     format:@"P = [[%@ alloc] init];", self.className];
  }
  
  ClassMethod *initMethod = [classGenerator addMethodName:@"1init"
					      declaration:NO
						signature:@"- (id)init"];
  [initMethod addLineIndent:1 format:@"self = [super init];"];
  for(Property *property in [self.properties allValues]) {
    if ([property isKindOfClass:[PathsProperty class]]) {
      PathsProperty *pathsProperty = (PathsProperty *)property;
      
      [classGenerator
       addVariableName:pathsProperty.name
       line:@"%@ *%@;",
       pathsProperty.className,
       pathsProperty.name];
      
      [classGenerator
       addPropertyName:pathsProperty.name
       line:@"@property(nonatomic, readonly) %@ *%@; // %@",
       pathsProperty.className,
       pathsProperty.name,
       pathsProperty.path];
      
      [classGenerator
       addSynthesizerName:pathsProperty.name
       line:@"@synthesize %@;",
       pathsProperty.name];
      
      [initMethod
       addLineIndent:1
       format:@"self->%@ = [[%@ alloc] init];",
       pathsProperty.name,
       pathsProperty.className];
    } else {
      [property generate:classGenerator generator:generator];
    }
  }
  [initMethod addLineIndent:1 format:@"return self;"];
  
  ClassMethod *descriptionMethod = [classGenerator
				    addMethodName:@"1description"
				    declaration:NO
				    signature:@"- (NSString *)description"];  
  [descriptionMethod
   addLineIndent:1
   format:@"return p(@\"%@\");",
   [self.path escapeCString]];
}

@end

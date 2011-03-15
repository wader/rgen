/*
 * StringsProperty.m, concrete class representing localizable string keys
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

#import "StringKeysProperty.h"
#import "ClassGenerator.h"
#import "NSString+rgen.h"

@implementation StringKeysProperty

- (NSString *)headerProlog:(ResourcesGenerator *)generator {
  return [NSString stringWithFormat:@"%@ *S;\n", self.className];
}

- (NSString *)implementationProlog:(ResourcesGenerator *)generator {
  return [NSString stringWithFormat:@"%@ *S;\n", self.className];
}

- (void)generate:(ClassGenerator *)classGenerator
       generator:(ResourcesGenerator *)generator {
  if (self.parent == nil) {
    MethodGenerator *loadMethod = [classGenerator addMethodName:@"0load"
						    declaration:NO
						      signature:@"+ (void)load"];
    [loadMethod
     addLineIndent:1
     format:@"S = [[%@ alloc] init];", self.className];
  }
  
  MethodGenerator *initMethod = [classGenerator addMethodName:@"1init"
						  declaration:NO
						    signature:@"- (id)init"];
  [self forEachProperty:^(Property *property) {
    [classGenerator
     addVariableName:property.name
     line:@"NSString *%@;",
     property.name];
    
    [classGenerator
     addPropertyName:property.name
     line:@"@property(nonatomic, readonly) NSString *%@; // %@",
     property.name,
     property.path]; // path is used for string key
    
    [classGenerator
     addSynthesizerName:property.name
     line:@"@synthesize %@;",
     property.name];
    
    [initMethod
     addLineIndent:1
     format:@"self->%@ = @\"%@\";",
     property.name,
     [property.path escapeCString]];
  }];

  [initMethod addLineIndent:1 format:@"return self;"];
}

@end

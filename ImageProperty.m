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

- (void)generate:(ClassGenerator *)classGenerator {
  [classGenerator.variables addObject:
   [NSString stringWithFormat:
    @"  UIImage *%@; // %@",
    self.name,
    self.path
    ]];
  
  [classGenerator.properties addObject:
   [NSString stringWithFormat:
    @"@property(nonatomic, readonly) UIImage *%@; // %@",
    self.name,
    self.path
    ]];
  
  [classGenerator.synthesizes addObject:
   [NSString stringWithFormat:@"@synthesize %@;", self.name]];
  
  [classGenerator.implementations addObject:
   [NSString stringWithFormat:
    @"- (UIImage *)%@ {\n"
    @"  if (%@ == nil)\n"
    @"    return [UIImage imageNamed:@\"%@\"];\n"
    @"  else\n"
    @"    return [[self->%@ retain] autorelease];\n"
    @"}",
    self.name,
    self.name,
    [self.path escapeCString],
    self.name
    ]];
}

@end
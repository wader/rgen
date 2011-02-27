//
//  ResourcesProperty.m
//  rgen
//
//  Created by Mattias Wadman on 2011-02-27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ResourcesProperty.h"
#import "ImageProperty.h"
#import "ClassGenerator.h"
#import "NSString+rgen.h"

@implementation ResourcesProperty : ClassProperty
- (void)generate:(ClassGenerator *)classGenerator {
  [classGenerator.declarations addObject:
   [NSString stringWithString:
    @"- (void)loadImages;\n"
    @"- (void)releaseImages;"
    ]];
  
  [classGenerator.implementations addObject:
   [NSString stringWithString:
    @"- (id)init {\n"
    @"  self = [super init];"
    ]];
  for(id key in [self.properties keysSortedByValueUsingComparator:
		 propertySortBlock]) {
    ResourcesProperty *resourcesProperty = [self.properties objectForKey:key];
    if (![resourcesProperty isKindOfClass:[ResourcesProperty class]]) {
      continue;
    }
    
    [classGenerator.variables addObject:
     [NSString stringWithFormat:
      @"  %@ *%@; // %@",
      resourcesProperty.className,
      resourcesProperty.name,
      resourcesProperty.path
      ]];
    
    [classGenerator.properties addObject:
     [NSString stringWithFormat:
      @"@property(nonatomic, readonly) %@ *%@; // %@",
      resourcesProperty.className,
      resourcesProperty.name,
      resourcesProperty.path
      ]];
    
    [classGenerator.synthesizes addObject:
     [NSString stringWithFormat:@"@synthesize %@;", resourcesProperty.name]];
    
    [classGenerator.implementations addObject:
     [NSString stringWithFormat:
      @"  self->%@ = [[%@ alloc] init];",
      resourcesProperty.name,
      resourcesProperty.className
      ]];
  }
  [classGenerator.implementations addObject:
   [NSString stringWithString:
    @"  return self;\n"
    @"}"
    ]];
  
  [classGenerator.implementations addObject:
   [NSString stringWithString:@"- (void)loadImages {"]];
  for(id key in [self.properties keysSortedByValueUsingComparator:
		 propertySortBlock]) {
    Property *property = [self.properties objectForKey:key];
    if ([property isKindOfClass:[ImageProperty class]]) {
      ImageProperty *imageProperty = (ImageProperty *)property;
      [classGenerator.implementations addObject:
       [NSString stringWithFormat:
	@"  self->%@ = [[UIImage imageNamed:@\"%@\"] retain];",
	imageProperty.name,
	[imageProperty.path escapeCString]
	]];
    } else if ([property isKindOfClass:[ResourcesProperty class]]) {
      ResourcesProperty *resourcesProperty = (ResourcesProperty *)property;
      [classGenerator.implementations addObject:
       [NSString stringWithFormat:
	@"  [self->%@ loadImages];",
	resourcesProperty.name
	]];
    }
  }
  [classGenerator.implementations addObject:
   [NSString stringWithString:@"}"]];
  
  [classGenerator.implementations addObject:
   [NSString stringWithString:@"- (void)releaseImages {"]];
  for(id key in [self.properties keysSortedByValueUsingComparator:
		 propertySortBlock]) {
    Property *property = [self.properties objectForKey:key];
    if ([property isKindOfClass:[ImageProperty class]]) {
      ImageProperty *imageProperty = (ImageProperty *)property;
      // TODO: escape path
      [classGenerator.implementations addObject:
       [NSString stringWithFormat:
	@"  [self->%@ release];\n"
	@"  self->%@ = nil;",
	imageProperty.name,
	imageProperty.name
	]];
    } else if ([property isKindOfClass:[ResourcesProperty class]]) {
      ResourcesProperty *resourcesProperty = (ResourcesProperty *)property;
      [classGenerator.implementations addObject:
       [NSString stringWithFormat:
	@"  [self->%@ releaseImages];",
	resourcesProperty.name
	]];
    }
  }
  [classGenerator.implementations addObject:
   [NSString stringWithString:@"}"]];
  
  for(id key in [self.properties keysSortedByValueUsingComparator:
		 propertySortBlock]) {
    ImageProperty *imageProperty = [self.properties objectForKey:key];
    if (![imageProperty isKindOfClass:[ImageProperty class]]) {
      continue;
    }
    
    [imageProperty generate:classGenerator];
  }
}

@end

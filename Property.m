//
//  Property.m
//  rgen
//
//  Created by Mattias Wadman on 2011-02-27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Property.h"

NSComparator propertySortBlock = ^(id a, id b) {
  return [((NSString *)[a valueForKey:@"name"])
	  compare:[b valueForKey:@"name"]];
};

@implementation Property
@synthesize name;
@synthesize path;

- (id)initWithName:(NSString *)aName
	      path:(NSString *)aPath {
  self = [super init];
  self.name = aName;
  self.path = aPath;
  return self;
}

- (void)generate:(ClassGenerator *)classGenerator
       generator:(ResourcesGenerator *)generator {
}

- (void)dealloc {
  self.name = nil;
  self.path = nil;
  [super dealloc];
}

@end
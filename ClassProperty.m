//
//  ClassProperty.m
//  rgen
//
//  Created by Mattias Wadman on 2011-02-27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ClassProperty.h"

@implementation ClassProperty : Property
@synthesize className;
@synthesize properties;

- (id)initWithName:(NSString *)aName
	      path:(NSString *)aPath
	 className:(NSString *)aClassName {
  self = [super initWithName:aName path:aPath];
  self.className = aClassName;
  self.properties = [NSMutableDictionary dictionary];
  return self;
}

- (void)rescursePostOrder:(BOOL)postOrder
	     propertyPath:(NSArray *)propertyPath
		    block:(void (^)(NSArray *propertyPath, ClassProperty *classProperty))block {
  if (!postOrder) {
    block(propertyPath, self);
  }
  
  for (id key in [self.properties keysSortedByValueUsingComparator:
		  propertySortBlock]) {
    ClassProperty *classProperty = [self.properties objectForKey:key];
    if (![classProperty isKindOfClass:[ClassProperty class]]) {
      continue;
    }
    
    [classProperty rescursePostOrder:postOrder
			propertyPath:[propertyPath arrayByAddingObject:self.name]
			       block:block];
  }
  
  if (postOrder) {
    block(propertyPath, self);
  }
}

- (void)rescursePostOrder:(void (^)(NSArray *propertyPath,
				    ClassProperty *classProperty))block {
  [self rescursePostOrder:YES
	     propertyPath:[NSArray array]
		    block:block];
}

- (void)rescursePreOrder:(void (^)(NSArray *propertyPath,
				   ClassProperty *classProperty))block {
  [self rescursePostOrder:NO
	     propertyPath:[NSArray array]
		    block:block];
}

- (void)pruneEmptyClasses {
  [self rescursePostOrder:^(NSArray *propertyPath,
			    ClassProperty *classProperty) {
    NSMutableArray *remove = [NSMutableArray array];
    for(id key in [classProperty.properties allKeys]) {
      ClassProperty *subClassProperty = [classProperty.properties
					 objectForKey:key];
      if (![subClassProperty isKindOfClass:[ClassProperty class]] ||
	  [subClassProperty.properties count] > 0) {
	continue;
      }
      
      [remove addObject:key];
    }
    
    [classProperty.properties removeObjectsForKeys:remove];
  }];
}

- (void)dealloc {
  self.className = nil;
  self.properties = nil;
  [super dealloc];
}

@end

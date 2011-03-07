//
//  ClassProperty.m
//  rgen
//
//  Created by Mattias Wadman on 2011-02-27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ClassProperty.h"
#import "NSString+rgen.h"

@interface ClassProperty ()
- (ClassProperty *)lookupPropertyPathFromDir:(NSArray *)dirComponents 
				   dirPrefix:(NSArray *)dirPrefix
			     classNamePrefix:(NSString *)classNamePrefix;
@end

@implementation ClassProperty : Property
@synthesize className;
@synthesize parent;
@synthesize properties;

- (NSString *)headerProlog:(ResourcesGenerator *)generator {
  return @"";
}

- (NSString *)implementationProlog:(ResourcesGenerator *)generator {
  return @"";
}

- (NSString *)inheritClassName {
  return @"NSObject";
}

- (id)initWithName:(NSString *)aName
	    parent:(ClassProperty *)aParent
	      path:(NSString *)aPath
	 className:(NSString *)aClassName {
  self = [super initWithName:aName path:aPath];
  self.parent = aParent;
  self.className = aClassName;
  self.properties = [NSMutableDictionary dictionary];
  return self;
}

- (void)rescursePostOrder:(BOOL)postOrder
	     propertyPath:(NSArray *)propertyPath
		    block:(void (^)(NSArray *propertyPath,
				    ClassProperty *classProperty))block {
  if (!postOrder) {
    block(propertyPath, self);
  }
  
  for (id key in [self.properties keysSortedByValueUsingComparator:
		  propertySortBlock]) {
    ClassProperty *classProperty = [self.properties objectForKey:key];
    if (![classProperty isKindOfClass:[self class]]) {
      continue;
    }
    
    [classProperty rescursePostOrder:postOrder
			propertyPath:[propertyPath
				      arrayByAddingObject:self.name]
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

- (ClassProperty *)lookupPropertyPathFromDir:(NSArray *)dirComponents 
				   dirPrefix:(NSArray *)dirPrefix
			     classNamePrefix:(NSString *)classNamePrefix {
  if ([dirComponents count] == 0) {
    return self;
  }
  
  NSString *dirName = [dirComponents objectAtIndex:0];
  NSString *nextPropertyName = [dirName dirPropertyName];
  NSString *nextPath = [NSString pathWithComponents:
			[dirPrefix arrayByAddingObject:dirName]];
  NSString *nextClassName = [classNamePrefix stringByAppendingString:
			     [dirName className]];
  
  ClassProperty *next = [self.properties objectForKey:nextPropertyName];
  
  if (next == nil) {
    next = [[[[self class] alloc]
	     initWithName:nextPropertyName
	     parent:self
	     path:nextPath
	     className:nextClassName]
	    autorelease];
    [self.properties setObject:next forKey:nextPropertyName];
  } else if (![next isKindOfClass:[self class]]) {
    // caller should check class type
    return self;
  }
  
  return [next
	  lookupPropertyPathFromDir: [dirComponents subarrayWithRange:
				      NSMakeRange(1,[dirComponents count] - 1)]
	  dirPrefix:[dirPrefix arrayByAddingObject:dirName]
	  classNamePrefix:className];
}

- (ClassProperty *)lookupPropertyPathFromDir:(NSArray *)dirComponents {
  return [self lookupPropertyPathFromDir:dirComponents
			       dirPrefix:[NSArray array]
			 classNamePrefix:self.className];
}

- (void)dealloc {
  self.className = nil;
  self.parent = nil;
  self.properties = nil;
  [super dealloc];
}

@end

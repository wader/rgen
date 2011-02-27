//
//  ClassProperty.h
//  rgen
//
//  Created by Mattias Wadman on 2011-02-27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Property.h"

@interface ClassProperty : Property
@property(nonatomic, retain) NSString *className;
@property(nonatomic, retain) NSMutableDictionary *properties;

- (id)initWithName:(NSString *)aName
	      path:(NSString *)aPath
	 className:(NSString *)aClassName;
- (void)rescursePostOrder:(BOOL)postOrder
	     propertyPath:(NSArray *)propertyPath
		    block:(void (^)(NSArray *propertyPath,
				    ClassProperty *classProperty))block;
- (void)rescursePostOrder:(void (^)(NSArray *propertyPath,
				    ClassProperty *classProperty))block;
- (void)rescursePreOrder:(void (^)(NSArray *propertyPath,
				   ClassProperty *classProperty))block;
- (void)pruneEmptyClasses;

@end
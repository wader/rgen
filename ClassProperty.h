//
//  ClassProperty.h
//  rgen
//
//  Created by Mattias Wadman on 2011-02-27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Property.h"

@class ClassProperty;

@interface ClassProperty : Property
@property(nonatomic, retain) NSString *className;
@property(nonatomic, assign) ClassProperty *parent;
@property(nonatomic, retain) NSMutableDictionary *properties;

- (NSString *)headerProlog:(ResourcesGenerator *)generator;
- (NSString *)implementationProlog:(ResourcesGenerator *)generator;
- (NSString *)inheritClassName;

- (id)initWithName:(NSString *)aName
	    parent:(ClassProperty *)aParent
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
- (ClassProperty *)lookupPropertyPathFromDir:(NSArray *)dirComponents;

@end
//
//  Property.h
//  rgen
//
//  Created by Mattias Wadman on 2011-02-27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClassGenerator.h"

NSComparator propertySortBlock;

@interface Property : NSObject
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *path;

- (id)initWithName:(NSString *)aName
	      path:(NSString *)aPath;
- (void)generate:(ClassGenerator *)classGenerator;
@end
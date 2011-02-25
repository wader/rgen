//
//  ClassGenerator.h
//  rgen
//
//  Created by Mattias Wadman on 2011-02-25.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClassGenerator : NSObject

@property(nonatomic, retain) NSString *className;
@property(nonatomic, retain) NSString *inheritClassName;
@property(nonatomic, retain) NSMutableArray *variables;
@property(nonatomic, retain) NSMutableArray *properties;
@property(nonatomic, retain) NSMutableArray *declarations;
@property(nonatomic, retain) NSMutableArray *synthesizes;
@property(nonatomic, retain) NSMutableArray *implementations;

- (id)initWithClassName:(NSString *)aClassName
	    inheritName:(NSString *)aInheritClassName;
- (NSString *)generateHeader;
- (NSString *)generateImplementation;

@end


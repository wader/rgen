//
//  ResourcesGenerator.h
//  rgen
//
//  Created by Mattias Wadman on 2011-02-17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PBXProj.h"


@interface ResourcesGenerator : NSObject

+ (NSString *)propertyName:(NSString *)name;

- (id)initWithProjectFile:(NSString *)aPath;
- (void)loadResources:(PBXProj *)pbxProj;
- (void)writeResoucesTo:(NSString *)outputDir
	      className:(NSString *)className;

@end
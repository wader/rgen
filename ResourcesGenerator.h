//
//  ResourcesGenerator.h
//  rgen
//
//  Created by Mattias Wadman on 2011-02-17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PBXProj.h"

@interface File : NSObject
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *path;
@end

@interface Dir : NSObject
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSMutableDictionary *files;
@end

@interface ResourcesGenerator : NSObject

@property(nonatomic, retain) NSString *pbxProjPath;
@property(nonatomic, retain) Dir *rootDir;

- (id)initWithProjectFile:(NSString *)aPath;
- (void)loadResources:(PBXProj *)pbxProj;
- (void)writeResoucesTo:(NSString *)outputDir
	      className:(NSString *)className;

@end
//
//  XCodeProj.h
//  rgen
//
//  Created by Mattias Wadman on 2011-03-06.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBXFile.h"

@interface XCodeProjException : NSException
@end

@interface XCodeProj : NSObject
@property(nonatomic, retain) PBXFile *pbxFile;
@property(nonatomic, retain) NSString *sourceRoot;
@property(nonatomic, retain) NSString *buildProductDir;
@property(nonatomic, retain) NSString *developerDir;
@property(nonatomic, retain) NSString *sdkRoot;
@property(nonatomic, retain) NSDictionary *sourceTrees;

- (id)initWithPath:(NSString *)aPath
       environment:(NSDictionary *)anEnvironment;
- (NSString *)projectName;
- (NSString *)absolutePath:(NSString *)path
		sourceTree:(NSString *)sourceTree;
- (void)forEachBuildResource:(void (^)(NSString *buildTargetName,
				       PBXDictionary *fileRef))block;
- (void)forEachBuildSetting:(void (^)(NSString *buildConfigurationName,
				      NSDictionary *buildSettings))block;

@end

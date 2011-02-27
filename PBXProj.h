//
//  PBXProj.h
//  rgen
//
//  Created by Mattias Wadman on 2011-02-17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PBXProj;

@interface PBXProjDictionary : NSObject
@property(nonatomic, retain) PBXProj *pbxProj;
@property(nonatomic, retain) NSDictionary *rootObject;

- (id)initWithRoot:(NSDictionary *)aRootObject
	   PBXProj:(PBXProj *)aPBXProj;
- (PBXProjDictionary *)dictForKey:(NSString *)key;
- (NSArray *)arrayForKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;
@end

@interface PBXProj : NSObject
@property(nonatomic, retain) NSString *pbxFilePath;
@property(nonatomic, retain) NSDictionary *objects;
@property(nonatomic, retain) PBXProjDictionary *rootDictionary;
@property(nonatomic, retain) NSDictionary *environment;

- (id)initWithProjectFile:(NSString *)path
	      environment:(NSDictionary *)aEnvironment;
- (NSString *)absolutePath:(NSString *)path
		sourceTree:(NSString *)sourceTree;
- (NSString *)projectName;
@end
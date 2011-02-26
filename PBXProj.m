//
//  PBXProj.m
//  rgen
//
//  Created by Mattias Wadman on 2011-02-17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PBXProj.h"

@implementation PBXProjDictionary

@synthesize pbxProj;
@synthesize rootObject;

- (id)initWithRoot:(NSDictionary *)aRootObject
	   PBXProj:(PBXProj *)aPBXProj {
  self = [super init];
  self.rootObject = aRootObject;
  self.pbxProj = aPBXProj;
  return self;
}

- (PBXProjDictionary *)dictForKey:(NSString *)key {
  NSString *objectId = [self.rootObject objectForKey:key];
  if (objectId == nil) {
    return nil;
  }
  NSDictionary *newRootObject = [self.pbxProj.objects objectForKey:objectId];
  if (newRootObject == nil ||
      ![newRootObject isKindOfClass:[NSDictionary class]]) {
    return nil;
  }
  
  return [[[PBXProjDictionary alloc]
	   initWithRoot:newRootObject
	   PBXProj:self.pbxProj]
	  autorelease];
}

- (NSArray *)arrayForKey:(NSString *)key {
  NSArray *objectIdArray = [self.rootObject objectForKey:key];
  if (objectIdArray == nil ||
      ![objectIdArray isKindOfClass:[NSArray class]]) {
    return nil;
  }
  
  NSMutableArray *pbxProjObjects = [NSMutableArray array];
  for (NSString *objectId in objectIdArray) {
    NSDictionary *newRootObject = [self.pbxProj.objects objectForKey:objectId];
    if (newRootObject == nil ||
	![newRootObject isKindOfClass:[NSDictionary class]]) {
      return nil;
    }
    
    [pbxProjObjects addObject:
     [[[PBXProjDictionary alloc]
       initWithRoot:newRootObject
       PBXProj:self.pbxProj]
      autorelease]];
  }
  
  return pbxProjObjects;
}

- (id)objectForKey:(NSString *)key {
  return [self.rootObject objectForKey:key];
}

- (void)dealloc {
  self.pbxProj = nil;
  self.rootObject = nil;
  
  [super dealloc];
}

@end

@implementation PBXProj

@synthesize pbxFilePath;
@synthesize objects;
@synthesize rootDictionary;
@synthesize environment;

- (id)initWithProjectFile:(NSString *)path
	      environment:(NSDictionary *)aEnvironment {
  self = [super init];
  
  NSDictionary *project = [NSDictionary dictionaryWithContentsOfFile:path];
  if (project == nil) {
    return nil;
  }
  
  self.pbxFilePath = path;
  self.objects = [project objectForKey:@"objects"];
  self.rootDictionary = [[[PBXProjDictionary alloc]
			  initWithRoot:[self.objects objectForKey:
					[project objectForKey:@"rootObject"]]
			  PBXProj:self]
			 autorelease];
  self.environment = aEnvironment;
  
  return self;
}

- (NSString *)absolutePath:(NSString *)path
		sourceTree:(NSString *)sourceTree {
  NSString *sourceRoot = [self.environment objectForKey:@"SOURCE_ROOT"];
  if (sourceRoot == nil) {
    sourceRoot = [[self.pbxFilePath stringByDeletingLastPathComponent]
		  stringByDeletingLastPathComponent];
  }
  NSString *buildProductDir = [self.environment
			       objectForKey:@"BUILT_PRODUCTS_DIR"];
  if (buildProductDir == nil) {
    buildProductDir = [NSString pathWithComponents:
		       [NSArray arrayWithObjects:
			sourceRoot, @"build", @"dummy", nil]];
  }
  NSString *developerDir = [self.environment objectForKey:@"DEVELOPER_DIR"];
  if (developerDir == nil) {
    developerDir = [NSString pathWithComponents:
		    [NSArray arrayWithObjects:@"/", @"Developer", nil]];
  }
  NSString *sdkRoot = [self.environment objectForKey:@"DEVELOPER_DIR"];
  if (sdkRoot == nil) {
    // TODO: fallback to what?
    sdkRoot = @"/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk";
  }
  
  NSString *tree = [[NSDictionary dictionaryWithObjectsAndKeys:
		     sourceRoot, @"<group>",
		     sourceRoot, @"SOURCE_ROOT",
		     @"/", @"<absolute>",			 
		     buildProductDir, @"BUILT_PRODUCTS_DIR",
		     developerDir, @"DEVELOPER_DIR" ,
		     sdkRoot, @"SDKROOT",
		     nil]
		    objectForKey:sourceTree];
  
  if (tree == nil) {
    return nil;
  }
  
  return [[NSString pathWithComponents:[NSArray arrayWithObjects:tree, path, nil]]
	  stringByStandardizingPath];
}

- (void)dealloc {
  self.pbxFilePath = nil;
  self.objects = nil;
  self.rootDictionary = nil;
  self.environment = nil;
  
  [super dealloc];
}

@end

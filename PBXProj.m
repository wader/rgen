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
  return [[[PBXProjDictionary alloc]
	   initWithRoot:[self.pbxProj.objects objectForKey:
			 [self.rootObject objectForKey:key]]
	   PBXProj:self.pbxProj]
	  autorelease];
}

- (NSArray *)arrayForKey:(NSString *)key {
  NSMutableArray *pbxProjObjects = [NSMutableArray array];
  
  for (NSString *objectId in [self.rootObject objectForKey:key]) {
    [pbxProjObjects addObject:
     [[[PBXProjDictionary alloc]
       initWithRoot:[self.pbxProj.objects objectForKey:objectId]
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
    [[self.pbxFilePath stringByDeletingLastPathComponent]
     stringByDeletingLastPathComponent];
  }
  
  NSDictionary *trees = [NSDictionary dictionaryWithObjectsAndKeys:
			 sourceRoot, @"<group>",
			 sourceRoot, @"SOURCE_ROOT",
			 @"/", @"<absolute>",			 
			 [self.environment objectForKey:@"BUILT_PRODUCTS_DIR"],
			 @"BUILT_PRODUCTS_DIR",
			 [self.environment objectForKey:@"DEVELOPER_DIR"],
			 @"DEVELOPER_DIR" ,
			 [self.environment objectForKey:@"SDKROOT"],
			 @"SDKROOT",
			 nil];
  
  return [[NSString pathWithComponents:
	   [NSArray arrayWithObjects:[trees objectForKey:sourceTree], path, nil]]
	  stringByStandardizingPath];
}

- (void)dealloc {
  self.pbxFilePath = nil;
  self.objects = nil;
  self.rootDictionary = nil;
  
  [super dealloc];
}

@end

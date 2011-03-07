//
//  PBXProj.m
//  rgen
//
//  Created by Mattias Wadman on 2011-02-17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

// TODO: error exceptions

#import "PBXFile.h"

@implementation PBXFile
@synthesize pbxFilePath;
@synthesize objects;
@synthesize rootDictionary;

- (id)initWithProjectFile:(NSString *)aPath {
  self = [super init];
  self.pbxFilePath = aPath;
  
  NSDictionary *project = [NSDictionary dictionaryWithContentsOfFile:aPath];
  if (project == nil ||
      ![project isKindOfClass:[NSDictionary class]]) {
    return nil;
  }
  
  self.objects = [project objectForKey:@"objects"];
  if (self.objects == nil ||
      ![self.objects isKindOfClass:[NSDictionary class]]) {
    return nil;
  }
  
  NSString *rootObjectId = [project objectForKey:@"rootObject"];
  if (rootObjectId == nil ||
      ![rootObjectId isKindOfClass:[NSString class]]) {
    return nil;
  }
  
  NSDictionary *rootObject = [self.objects objectForKey:rootObjectId];
  if (rootObject == nil ||
      ![rootObject isKindOfClass:[NSDictionary class]]) {
    return nil;
  }
  
  self.rootDictionary = [[[PBXDictionary alloc]
			  initWithRoot:rootObject
			  pbxFile:self]
			 autorelease];
  
  return self;
}

- (void)dealloc {
  self.pbxFilePath = nil;
  self.objects = nil;
  self.rootDictionary = nil;
  
  [super dealloc];
}

@end

@implementation PBXDictionary
@synthesize pbxFile;
@synthesize rootObject;

- (id)initWithRoot:(NSDictionary *)aRootObject
	   pbxFile:(PBXFile *)aPBXFile {
  self = [super init];
  self.rootObject = aRootObject;
  self.pbxFile = aPBXFile;
  return self;
}

- (PBXDictionary *)refDictForObjectId:(NSString *)objectId {
  if (objectId == nil || ![objectId isKindOfClass:[NSString class]]) {
    return nil;
  }
  
  NSDictionary *newRootObject = [self.pbxFile.objects objectForKey:objectId];
  if (newRootObject == nil ||
      ![newRootObject isKindOfClass:[NSDictionary class]]) {
    return nil;
  }
  
  return [[[PBXDictionary alloc]
	   initWithRoot:newRootObject
	   pbxFile:self.pbxFile]
	  autorelease];
}

- (PBXDictionary *)refDictForKey:(NSString *)key {
  return [self refDictForObjectId:[self objectForKey:key]];
}

- (NSArray *)refDictArrayForKey:(NSString *)key {
  NSArray *objectIdArray = [self objectForKey:key];
  if (objectIdArray == nil ||
      ![objectIdArray isKindOfClass:[NSArray class]]) {
    return nil;
  }
  
  NSMutableArray *pbxDictObjects = [NSMutableArray array];
  for (NSString *objectId in objectIdArray) {
    PBXDictionary *dict = [self refDictForObjectId:objectId];
    if (dict == nil) {
      return nil;
    }

    [pbxDictObjects addObject:dict];
  }
  
  return pbxDictObjects;
}

- (id)objectForKey:(NSString *)key {
  return [self.rootObject objectForKey:key];
}

- (void)dealloc {
  self.pbxFile = nil;
  self.rootObject = nil;
  
  [super dealloc];
}

@end

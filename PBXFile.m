/*
 * PBXFile.m, methods to help reading the Xcode project file format
 *
 * Copyright (c) 2011 <mattias.wadman@gmail.com>
 *
 * MIT License:
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

// TODO: error exceptions

#import "PBXFile.h"

@implementation PBXFile
@synthesize pbxFilePath;
@synthesize objects;
@synthesize rootDictionary;

- (id)initWithProjectFile:(NSString *)aPath {
  self = [super init];
  if (self == nil) {
    return nil;
  }
  
  NSDictionary *project = [NSDictionary dictionaryWithContentsOfFile:aPath];
  if (project == nil ||
      ![project isKindOfClass:[NSDictionary class]]) {
    [self release];
    return nil;
  }
  
  self.objects = [project objectForKey:@"objects"];
  if (self.objects == nil ||
      ![self.objects isKindOfClass:[NSDictionary class]]) {
    [self release];
    return nil;
  }
  
  NSString *rootObjectId = [project objectForKey:@"rootObject"];
  if (rootObjectId == nil ||
      ![rootObjectId isKindOfClass:[NSString class]]) {
    [self release];
    return nil;
  }
  
  NSDictionary *rootObject = [self.objects objectForKey:rootObjectId];
  if (rootObject == nil ||
      ![rootObject isKindOfClass:[NSDictionary class]]) {
    [self release];
    return nil;
  }
  
  self.pbxFilePath = aPath;
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

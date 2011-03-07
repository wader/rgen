//
//  PBXProj.h
//  rgen
//
//  Created by Mattias Wadman on 2011-02-17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PBXDictionary;

@interface PBXFile : NSObject
@property(nonatomic, retain) NSString *pbxFilePath;
@property(nonatomic, retain) NSDictionary *objects;
@property(nonatomic, retain) PBXDictionary *rootDictionary;

- (id)initWithProjectFile:(NSString *)aPath;

@end

@interface PBXDictionary : NSObject
@property(nonatomic, retain) PBXFile *pbxFile;
@property(nonatomic, retain) NSDictionary *rootObject;

- (id)initWithRoot:(NSDictionary *)aRootObject
	   pbxFile:(PBXFile *)aPBXFile;
// PBXDictionary from key with object id, returns nil if wrong types
- (PBXDictionary *)refDictForKey:(NSString *)key;
// Get array of PBXDictionary from key with array of object ids,
// returns nil if wrong types
- (NSArray *)refDictArrayForKey:(NSString *)key;
// Raw object for key, no type checks
- (id)objectForKey:(NSString *)key;

@end


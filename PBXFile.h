/*
 * PBXFile.h, methods to help reading the Xcode project file format
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


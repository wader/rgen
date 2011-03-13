/*
 * XCodeProj.h, Xcode project specific PBX structures
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
#import "PBXFile.h"

@class XCodeNode;
@class XCodeGroup;
@class XCodeFile;

@interface XCodeProjException : NSException
@end

@interface XCodeProj : NSObject {
@private
  PBXFile *pbxFile;
  NSMutableDictionary *nodeRefs;
  XCodeGroup *mainGroup;
  NSString *sourceRoot;
  NSString *buildProductDir;
  NSString *developerDir;
  NSString *sdkRoot;
  NSDictionary *sourceTrees;
}

@property(nonatomic, retain) PBXFile *pbxFile;
@property(nonatomic, retain) NSMutableDictionary *nodeRefs;
@property(nonatomic, retain) XCodeGroup *mainGroup;
@property(nonatomic, retain) NSString *sourceRoot;
@property(nonatomic, retain) NSString *buildProductDir;
@property(nonatomic, retain) NSString *developerDir;
@property(nonatomic, retain) NSString *sdkRoot;
@property(nonatomic, retain) NSDictionary *sourceTrees;

- (id)initWithPath:(NSString *)aPath
       environment:(NSDictionary *)anEnvironment;
- (NSString *)projectName;
- (NSString *)absolutePath:(NSString *)path
		sourceTree:(NSString *)sourceTree
		 groupPath:(NSString *)groupPath;
- (void)forEachBuildResource:(void (^)(NSString *buildTargetName,
				       XCodeNode *xcodeNode))block;
- (void)forEachBuildSetting:(void (^)(NSString *buildConfigurationName,
				      NSDictionary *buildSettings))block;
- (XCodeGroup *)loadGroup:(PBXDictionary *)group;
- (XCodeGroup *)loadMainGroup;


@end

// abstract class with common properites for file and group
@interface XCodeNode : NSObject {
@private
  XCodeProj *xcodeProj;
  NSString *objectId;
  XCodeGroup *parent;
  NSString *name;
  NSString *sourceTree;
  NSString *path;
}

@property(nonatomic, retain) XCodeProj *xcodeProj;
@property(nonatomic, retain) NSString *objectId;
@property(nonatomic, assign) XCodeGroup *parent;
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *sourceTree;
@property(nonatomic, retain) NSString *path;

- (id)initFromPBXDictionary:(PBXDictionary *)pbxDict
                  xcodeProj:(XCodeProj *)anXCodeProj
                     parent:(XCodeGroup *)anParent;
- (NSString *)absolutePath;
- (void)dump;

@end

@interface XCodeGroup : XCodeNode {
  NSMutableArray *children;
}

@property(nonatomic, retain) NSMutableArray *children;

@end

@interface XCodeFile : XCodeNode {
}

@end


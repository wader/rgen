/*
 * XcodeProj.h, read Xcode project specific PBX structures
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

// TODO: better fake paths if no xcode build environment

#import "XCodeProj.h"

@implementation XCodeProjException
@end

@implementation XcodeProj
@synthesize pbxFile;
@synthesize nodeRefs;
@synthesize mainGroup;
@synthesize sourceRoot;
@synthesize buildProductDir;
@synthesize developerDir;
@synthesize sdkRoot;
@synthesize sourceTrees;

- (id)initWithPath:(NSString *)aPath
       environment:(NSDictionary *)anEnvironment {
  self = [super init];
  if (self == nil) {
    return nil;
  }
  
  BOOL isDir = NO;
  if ([[NSFileManager defaultManager]
       fileExistsAtPath:aPath isDirectory:&isDir] && isDir) {
    aPath = [aPath stringByAppendingPathComponent:@"project.pbxproj"];
  }
  
  if (![aPath isAbsolutePath]) {
    NSMutableArray *components = [NSMutableArray array];
    [components addObject:[[NSFileManager defaultManager]
                           currentDirectoryPath]];
    [components addObject:aPath];
    aPath = [[NSString pathWithComponents:components]
             stringByStandardizingPath];
  }
  
  self.pbxFile = [[[PBXFile alloc] initWithProjectFile:aPath] autorelease];
  if (self.pbxFile == nil) {
    [self release];
    return nil;
  }
  
  // setup source tree paths by first checking the environment then fallback
  // to guessing based on project path
  
  self.sourceRoot = [anEnvironment objectForKey:@"SOURCE_ROOT"];
  if (self.sourceRoot == nil) {
    self.sourceRoot = [[self.pbxFile.pbxFilePath
                        stringByDeletingLastPathComponent]
                       stringByDeletingLastPathComponent];
  }
  
  self.buildProductDir = [anEnvironment
			  objectForKey:@"BUILT_PRODUCTS_DIR"];
  if (self.buildProductDir == nil) {
    self.buildProductDir = [NSString pathWithComponents:
			    [NSArray arrayWithObjects:
			     self.sourceRoot, @"build", @"dummy", nil]];
  }
  
  self.developerDir = [anEnvironment objectForKey:@"DEVELOPER_DIR"];
  if (self.developerDir == nil) {
    self.developerDir = [NSString pathWithComponents:
			 [NSArray arrayWithObjects:@"/", @"Developer", nil]];
  }
  
  self.sdkRoot = [anEnvironment objectForKey:@"DEVELOPER_DIR"];
  if (self.sdkRoot == nil) {
    self.sdkRoot = @"/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk";
  }
  
  self.sourceTrees = [NSDictionary dictionaryWithObjectsAndKeys:
		      self.sourceRoot, @"SOURCE_ROOT",
		      @"/", @"<absolute>",			 
		      self.buildProductDir, @"BUILT_PRODUCTS_DIR",
		      self.developerDir, @"DEVELOPER_DIR" ,
		      self.sdkRoot, @"SDKROOT",
		      nil];
  
  self.nodeRefs = [NSMutableDictionary dictionary];
  
  return self;
}

- (void)raiseFormat:(NSString *)format, ... {
  va_list va;
  va_start(va, format);
  [XCodeProjException raise:@"error" format:format arguments:va];
  va_end(va);
}

- (NSString *)projectName {
  NSArray *components = [self.pbxFile.pbxFilePath pathComponents];
  if ([components count] > 1) {
    return [components objectAtIndex:[components count] - 2];    
  } else {
    return self.pbxFile.pbxFilePath;
  }
}

- (NSString *)absolutePath:(NSString *)path
		sourceTree:(NSString *)sourceTree
		 groupPath:(NSString *)groupPath {
  NSString *treePath;
  
  if ([sourceTree isEqualToString:@"<group>"]) {
    treePath = groupPath;
  } else {
    treePath = [self.sourceTrees objectForKey:sourceTree];
    if (treePath == nil) {
      // TODO: find source trees in global xcode config
      /*
       NSString *xcodePref = [NSString pathWithComponents:
       [NSArray arrayWithObjects:
       NSHomeDirectory(),
       @"Library", @"Preferences", @"com.apple.Xcode.plist",
       nil]];
       */
      return nil;
    }
  }
  
  return [[NSString pathWithComponents:
	   [NSArray arrayWithObjects:treePath, path, nil]]
	  stringByStandardizingPath];
}

- (XCodeGroup *)loadMainGroup {
  if (self.mainGroup == nil) {
    PBXDictionary *mainGroupDict = [self.pbxFile.rootDictionary
                                    refDictForKey:@"mainGroup"];
    if (mainGroupDict == nil) {
      [self raiseFormat:@"Failed to read mainGroup key"];
    }
    
    self.mainGroup = [self loadGroup:mainGroupDict];
    if (self.mainGroup == nil) {
      [self raiseFormat:@"Failed to load mainGroup"];
    }
  }
  
  return self.mainGroup;
}

- (void)forEachBuildResource:(void (^)(NSString *buildTargetName,
				       XCodeNode *xcodeNode))block {
  [self loadMainGroup];
  
  NSArray *targets = [self.pbxFile.rootDictionary refDictArrayForKey:@"targets"];
  if (targets == nil) {
    [self raiseFormat:@"Failed to read targets array"];
  }
  
  for (PBXDictionary *target in targets) {
    NSString *name = [target objectForKey:@"name"];
    if (name == nil || ![name isKindOfClass:[NSString class]]) {
      [self raiseFormat:@"Failed to read target name"];
    }
    
    NSArray *buildPhases = [target refDictArrayForKey:@"buildPhases"];
    if (buildPhases == nil) {
      [self raiseFormat:@"Failed to read buildPhases array for target \"%@\"",
       name];
    }
    
    for (PBXDictionary *buildPhase in buildPhases) {
      NSString *buildIsa = [buildPhase objectForKey:@"isa"];
      if (buildIsa == nil || ![buildIsa isKindOfClass:[NSString class]]) {
        [self raiseFormat:
         @"Failed to read buildIsa for buildPhase for target \"%@\"",name];
      }
      
      if (![buildIsa isEqualToString:@"PBXResourcesBuildPhase"]) {
        continue;
      }
      
      NSArray *files = [buildPhase refDictArrayForKey:@"files"];
      if (files == nil) {
        [self raiseFormat:
         @"Failed to read files array for resource build phase for target \"%@\"",
         name];
      }
      
      for (PBXDictionary *file in files) {
        PBXDictionary *fileRef = [file refDictForKey:@"fileRef"];
        if (fileRef == nil) {
          [self raiseFormat:
           @"Failed to read fileRef for file in resource build phase for target \"%@\"",
           name];
        }
        
        // in multilingual projects, "fileRef" can refer to a PBXVariantGroup
        // if the file has multiple variants per language
        // each child of the VariantGroup is a PBXFileReference
        NSString *fileRefIsa = [fileRef objectForKey:@"isa"];
        if ([fileRefIsa isEqualToString:@"PBXVariantGroup"]) {
          XCodeGroup *variantGroup = [self.nodeRefs objectForKey:fileRef.objectId];
          if (variantGroup == nil) {
            [self raiseFormat:
             @"Could not find variant group %@ for build file", fileRef.objectId];
            continue;
          }
          block(name, variantGroup);
        }
        else {
          XCodeFile *xcodeNode = [self.nodeRefs objectForKey:fileRef.objectId];
          if (xcodeNode == nil) {
            [self raiseFormat:
             @"Could not find file reference %@ for build file", fileRef.objectId];
            continue;
          }
          block(name, xcodeNode);
        }
      }
    }
  }
}

- (void)forEachBuildSetting:(void (^)(NSString *buildConfigurationName,
				      NSDictionary *buildSettings))block {
  PBXDictionary *buildConfigurationList = [self.pbxFile.rootDictionary
					   refDictForKey:@"buildConfigurationList"];
  if (buildConfigurationList == nil) {
    [self raiseFormat:@"Failed to read buildConfigurationList"];
  }
  
  NSArray *buildConfigurations = [buildConfigurationList
				  refDictArrayForKey:@"buildConfigurations"];
  if (buildConfigurations == nil) {
    [self raiseFormat:@"Failed to read buildConfigurations array"];
  }
  
  for (PBXDictionary *buildConfiguration in buildConfigurations) {
    NSString *name = [buildConfiguration objectForKey:@"name"];
    if (name == nil || ![name isKindOfClass:[NSString class]]) {
      [self raiseFormat:@"Failed to read target name"];
    }
    
    NSDictionary *buildSettings = [buildConfiguration objectForKey:@"buildSettings"];    
    if (buildSettings == nil ||
	![buildSettings isKindOfClass:[NSDictionary class]]) {
      [self raiseFormat:@"Failed to read buildSettings for buildConfiguration \"%@\"",
       name];
    }
    
    block(name, buildSettings);
  }
}

- (XCodeGroup *)loadGroup:(PBXDictionary *)group {
  XCodeGroup *xcodeGroup = [[[XCodeGroup alloc]
                             initFromPBXDictionary:group
                             xcodeProj:self
                             parent:nil]
                            autorelease];
  if (xcodeGroup == nil) {
    [self raiseFormat:@"Failed to create group for %@", group.rootObject];
  }
  
  NSArray *children = [group refDictArrayForKey:@"children"];
  if (children == nil) {
    [self raiseFormat:@"Failed to read children array"];
  }
  for (PBXDictionary *child in children) {
    NSString *childIsa = [child objectForKey:@"isa"];
    XCodeNode *childXcodeNode = nil;
    
    if (childIsa != nil && [childIsa isKindOfClass:[NSString class]]) {
      if ([childIsa isEqualToString:@"PBXGroup"] ||
          [childIsa isEqualToString:@"PBXVariantGroup"]) {
        
        childXcodeNode = (XCodeNode *)[self loadGroup:child];
        childXcodeNode.parent = xcodeGroup;
      } else if ([childIsa isEqualToString:@"PBXFileReference"]) {
        childXcodeNode = (XCodeNode *)[[[XCodeFile alloc]
                                        initFromPBXDictionary:child
                                        xcodeProj:self
                                        parent:xcodeGroup]
                                       autorelease];
        if (childXcodeNode == nil) {
          [self raiseFormat:@"Failed to create file reference for %@",
           child.rootObject];
        }
      }
      
      if (childXcodeNode != nil) {
        [xcodeGroup.children addObject:childXcodeNode];
        [self.nodeRefs setObject:childXcodeNode
                          forKey:childXcodeNode.objectId];
      }
    }    
  }
  
  return xcodeGroup;
}

- (void)dealloc {
  self.pbxFile = nil;
  self.nodeRefs = nil;
  self.mainGroup = nil;
  self.sourceRoot = nil;
  self.buildProductDir = nil;
  self.developerDir = nil;
  self.sdkRoot = nil;
  self.sourceTrees = nil;
  
  [super dealloc];
}

@end

@implementation XCodeNode
@synthesize objectId;
@synthesize xcodeProj;
@synthesize parent;
@synthesize name;
@synthesize path;
@synthesize sourceTree;

- (id)initFromPBXDictionary:(PBXDictionary *)pbxDict
                  xcodeProj:(XcodeProj *)anXCodeProj
                     parent:(XCodeGroup *)anParent {
  self = [super init];
  if (self == nil) {
    return nil;
  }
  
  self.objectId = pbxDict.objectId;
  self.xcodeProj = anXCodeProj;
  self.parent = anParent;
  self.name = [pbxDict objectForKey:@"name"];
  self.sourceTree = [pbxDict objectForKey:@"sourceTree"];
  self.path = [pbxDict objectForKey:@"path"];
  if (self.sourceTree == nil) {
    [self release];
    return nil;
  }
  
  return self;
}

- (NSString *)absolutePath {
  NSString *p;
  NSString *groupPath = nil;
  
  if ([self.sourceTree isEqualToString:@"<group>"]) {
    if (self.parent == nil) {
      groupPath = self.xcodeProj.sourceRoot; // projectDir?
    } else {
      groupPath = [self.parent absolutePath];
    }
  }
  
  p = [self.xcodeProj absolutePath:self.path
                        sourceTree:self.sourceTree
                         groupPath:groupPath];
  
  return p;
}

- (void)dump:(NSUInteger)indent {
  NSMutableString *s = [NSMutableString string];
  
  for (int i = 0; i < indent; i++) {
    [s appendString:@"  "];
  }
  
  NSLog(@"%@%@ parent=%@ sourceTree=%@ abspath=%@",
        s, self.name, self.parent, self.sourceTree, [self absolutePath]);
  
  if ([self isKindOfClass:[XCodeGroup class]]) {
    for (XCodeNode *child in ((XCodeGroup *)self).children) {
      [child dump:indent + 1];
    }
  }
}

- (void)dump {
  [self dump:0];
}

- (void)dealloc {
  self.objectId = nil;
  self.xcodeProj = nil;
  self.name = nil;
  self.sourceTree = nil;
  self.path = nil;
  
  [super dealloc];
}

@end

@implementation XCodeGroup
@synthesize children;

- (id)initFromPBXDictionary:(PBXDictionary *)pbxDict
                  xcodeProj:(XcodeProj *)anXCodeProj
                     parent:(XCodeGroup *)anParent {
  self = [super initFromPBXDictionary:pbxDict
                            xcodeProj:anXCodeProj
                               parent:anParent];
  if (self == nil) {
    return nil;
  }
  
  self.children = [NSMutableArray array];
  
  return self;
}

- (void)dealloc {
  self.children = nil;
  
  [super dealloc];
}

@end

@implementation XCodeFile
@end

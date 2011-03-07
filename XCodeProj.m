//
//  XCodeProj.m
//  rgen
//
//  Created by Mattias Wadman on 2011-03-06.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

// TODO: better fake paths if no xcode build environment

#import "XCodeProj.h"

@implementation XCodeProjException
@end

@implementation XCodeProj
@synthesize pbxFile;
@synthesize sourceRoot;
@synthesize buildProductDir;
@synthesize developerDir;
@synthesize sdkRoot;
@synthesize sourceTrees;

- (id)initWithPath:(NSString *)aPath
       environment:(NSDictionary *)anEnvironment {
  BOOL isDir = NO;
  if ([[NSFileManager defaultManager]
       fileExistsAtPath:aPath isDirectory:&isDir] && isDir) {
    aPath = [aPath stringByAppendingPathComponent:@"project.pbxproj"];
  }
  
  self = [super init];
  self.pbxFile = [[[PBXFile alloc] initWithProjectFile:aPath] autorelease];
  if (self.pbxFile == nil) {
    return nil;
  }
  
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
		      self.sourceRoot, @"<group>",
		      self.sourceRoot, @"SOURCE_ROOT",
		      @"/", @"<absolute>",			 
		      self.buildProductDir, @"BUILT_PRODUCTS_DIR",
		      self.developerDir, @"DEVELOPER_DIR" ,
		      self.sdkRoot, @"SDKROOT",
		      nil];
  
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
  return [components objectAtIndex:[components count] - 2];
}

- (NSString *)absolutePath:(NSString *)path
		sourceTree:(NSString *)sourceTree {
  NSString *treePath = [self.sourceTrees objectForKey:sourceTree];
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
  
  return [[NSString pathWithComponents:
	   [NSArray arrayWithObjects:treePath, path, nil]]
	  stringByStandardizingPath];
}

- (void)forEachBuildResource:(void (^)(NSString *buildTargetName,
				       PBXDictionary *fileRef))block {  
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
	
	block(name, fileRef);
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

- (void)dealloc {
  self.pbxFile = nil;
  self.sourceRoot = nil;
  self.buildProductDir = nil;
  self.developerDir = nil;
  self.sdkRoot = nil;
  self.sourceTrees = nil;
  
  [super dealloc];
}

@end

//
//  ResourcesGenerator.m
//  rgen
//
//  Created by Mattias Wadman on 2011-02-17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ResourcesGenerator.h"
#import "PBXProj.h"
#import "NSString+stripSuffix.h"
#import "NSString+toCamelCase.h"

@implementation File

@synthesize name;
@synthesize path;

- (id)initWithName:(NSString *)aName
	      path:(NSString *)aPath {
  self = [super init];
  self.name = aName;
  self.path = aPath;
  return self;
}

- (void)dealloc {
  self.name = nil;
  self.path = nil;
  [super dealloc];
}

@end

@implementation Dir

@synthesize name;
@synthesize files;

- (id)initWithName:(NSString *)aName {
  self = [super init];
  self.name = aName;
  self.files = [NSMutableDictionary dictionary];
  return self;
}

- (void)dealloc {
  self.name = nil;
  self.files = nil;
  [super dealloc];
}

@end

@implementation ResourcesGenerator

@synthesize pbxProjPath;
@synthesize rootDir;

- (id)initWithProjectFile:(NSString *)aPath {
  self = [super init];
  self.pbxProjPath = aPath;
  self.rootDir = [[[Dir alloc] initWithName:@""] autorelease];
  
  [self loadResources:[[[PBXProj alloc]
			initWithProjectFile:aPath
			environment:[[NSProcessInfo processInfo] environment]]
		       autorelease]];
  
  return self;
}

- (Dir *)lookupDir:(NSArray *)dirComponents {
  Dir *current = self.rootDir;
  
  for (NSString *name in dirComponents) {
    Dir *next = [current.files objectForKey:name];
    if (next == nil) {
      next = [[[Dir alloc] initWithName:name] autorelease];
      [current.files setObject:next forKey:name];
    }
    
    current = next;
  }
  
  return current;
}

- (void)loadResources:(PBXProj *)pbxProj {
  for (PBXProjDictionary *p in [pbxProj.rootDictionary arrayForKey:@"targets"]) {
    for (PBXProjDictionary *buildPhase in [p arrayForKey:@"buildPhases"]) {
      NSString *isa = [buildPhase objectForKey:@"isa"];
      
      if (![isa isEqualToString:@"PBXResourcesBuildPhase"]) {
	continue;
      }
      
      for (PBXProjDictionary *file in [buildPhase arrayForKey:@"files"]) {
	PBXProjDictionary *fileRef = [file dictForKey:@"fileRef"];
	
	NSString *lastKnownFileType = [fileRef objectForKey:@"lastKnownFileType"];
	NSString *sourceTree = [fileRef objectForKey:@"sourceTree"];
	NSString *path = [fileRef objectForKey:@"path"];
	NSString *name = [fileRef objectForKey:@"name"];
	if (name == nil) {
	  name = [path lastPathComponent];
	}
	
	NSString *absPath = [pbxProj absolutePath:path sourceTree:sourceTree];
	if ([lastKnownFileType isEqualToString:@"folder"]) {
	  for (NSString *subpath in [[NSFileManager defaultManager]
				     subpathsOfDirectoryAtPath:absPath
				     error:NULL]) {
	    
	    BOOL isDir = NO;
	    if ([[NSFileManager defaultManager]
		 fileExistsAtPath:[absPath stringByAppendingPathComponent:subpath]
		 isDirectory:&isDir] &&
		isDir) {
	      continue;
	    }
	    
	    NSString *filename = [subpath lastPathComponent];
	    NSArray *subpathComponents = [subpath pathComponents];
	    subpathComponents = [subpathComponents subarrayWithRange:
				 NSMakeRange(0, [subpathComponents count]-1)];
	    NSArray *dirComponents = [[NSArray arrayWithObject:name]
				      arrayByAddingObjectsFromArray:subpathComponents];
	    
	    [[self lookupDir:dirComponents].files
	     setObject:[[[File alloc] initWithName:filename path:path] autorelease]
	     forKey:filename];
	  }
	} else {
	  [self.rootDir.files
	   setObject:[[[File alloc] initWithName:name path:path] autorelease]
	   forKey:name];
	}
      }      
    }
  }
}

- (void)rescurseResoucesWithBlock:(void (^)(NSArray *dirComponents, id file))block
			      dir:(Dir *)dir
		    dirComponents:(NSArray *)dirComponents {
  
  block(dirComponents, dir);
  
  for (id file in [dir.files allValues]) {
    NSString *subdir = @"";
    if ([dirComponents count] > 0) {
      subdir = [[NSString pathWithComponents:dirComponents]
		stringByAppendingString:@"/"];
    }
    
    
    if ([file isKindOfClass:[Dir class]]) {
      Dir *subDir = file;
      [self rescurseResoucesWithBlock:block
				  dir:subDir
			dirComponents:[dirComponents arrayByAddingObject:subDir.name]];
    } else {
      block(dirComponents, file);
    }
  }
}

- (void)rescurseResoucesWithBlock:(void (^)(NSArray *dirComponents, id file))block {
  [self rescurseResoucesWithBlock:block
			      dir:self.rootDir
		    dirComponents:[NSArray array]];
}

- (void)writeResoucesTo:(NSString *)outputDir
	      className:(NSString *)className {
  NSMutableString *header = [NSMutableString string];
  
  [header appendFormat:@"// Generated from %@\n", self.pbxProjPath];
  [header appendFormat:@"#import <Foundation/Foundation.h>\n\n"];
  
  [self rescurseResoucesWithBlock:^(NSArray *dirComponents, id file) {
    if (![file isKindOfClass:[Dir class]]) {
      return;
    }
    [header appendFormat:@"@class %@%@;\n",
     className,
     [dirComponents componentsJoinedByString:@""]];
  }];
  
  [header appendFormat:@"\n"];
  
  [self rescurseResoucesWithBlock:^(NSArray *dirComponents, id file) {
    if (![file isKindOfClass:[Dir class]]) {
      return;
    }
    Dir *dir = file;
    [header appendFormat:@"@interface %@%@ : NSObject\n",
     className,
     [dirComponents componentsJoinedByString:@""]];
    
    
    for (File *dirFile in [dir.files allValues]) {
      if (![dirFile isKindOfClass:[Dir class]]) {
	continue;
      }
      
      [header appendFormat:@"@property(nonatomic, readonly) %@%@ *%@;\n",
       className,
       [dirComponents componentsJoinedByString:@""], dirFile.name, dirFile.name];
    }
    
    
    NSMutableSet *uniqImages = [NSMutableSet set];
    
    for (File *dirFile in [dir.files allValues]) {
      if (![dirFile.name hasSuffix:@".png"]) {
	continue;
      }
      
      [uniqImages addObject:
       [[[dirFile.name stringByDeletingPathExtension]
	 stripSuffix:[NSArray arrayWithObjects:@"@2x", @"-ipad", nil]]
	toCamelCase:[NSCharacterSet characterSetWithCharactersInString:@"._-"]]];
    }
    
    for (NSString *imageName in uniqImages) {
      [header appendFormat:@"@property(nonatomic, readonly) %@%@;\n",
       @"id ", imageName];
    }
    
    [header appendFormat:@"@end\n",
     [dirComponents componentsJoinedByString:@""], dir.name];
    
  }];
  
  [header appendFormat:@"\n"];
  
  [header appendFormat:
   @"@interface %@ (loadResources)\n"
   @"- (void)loadResources;\n"
   @"@end\n",
   className];
  
  
  NSMutableString *definition = [NSMutableString string];
  
  [definition appendFormat:@"// Generated from %@\n", self.pbxProjPath];
  [definition appendFormat:@"#import \"%@.h\"\n\n", className];
  
  [self rescurseResoucesWithBlock:^(NSArray *dirComponents, id file) {
    if (![file isKindOfClass:[Dir class]]) {
      return;
    }
    Dir *dir = file;
    [definition appendFormat:@"@implementation %@%@\n",
     className,
     [dirComponents componentsJoinedByString:@""]];
    
    NSMutableSet *uniqImages = [NSMutableSet set];
    
    for (id dirObj in [dir.files allValues]) {
      if (![dirObj isKindOfClass:[Dir class]]) {
	continue;
      }
      
      Dir *dirDir = dirObj;
      
      [definition appendFormat:@"@synthesize %@;\n", dirDir.name];
    }
    
    for (id dirObj in [dir.files allValues]) {
      if (![dirObj isKindOfClass:[File class]]) {
	continue;
      }
      File *dirFile = dirObj;
      if (![dirFile.name hasSuffix:@".png"]) {
	continue;
      }
      
      [uniqImages addObject:
       [[[dirFile.name stringByDeletingPathExtension]
	 stripSuffix:[NSArray arrayWithObjects:@"@2x", @"-ipad", nil]]
	toCamelCase:[NSCharacterSet characterSetWithCharactersInString:@"._-"]]];
    }
    
    for (NSString *imageName in uniqImages) {
      [definition appendFormat:@"@synthesize %@;\n", imageName];
    }
    
    [definition appendFormat:@"@end\n",
     [dirComponents componentsJoinedByString:@""], dir.name];
    
  }];
  
  [definition appendFormat:@"%@ *R;\n", className];
  
  [definition appendFormat:
   @"@implementation %@ (loadResources)\n"
   @"- (void)loadResources {\n"
   @"}\n"
   @"@end\n",
   className];
  
  
  [header writeToFile:[NSString pathWithComponents:
		       [NSArray arrayWithObjects:
			outputDir,
			[className stringByAppendingPathExtension:@"h"],
			nil]]
	   atomically:YES
	     encoding:NSUTF8StringEncoding
		error:NULL];
  
  [definition writeToFile:[NSString pathWithComponents:
			   [NSArray arrayWithObjects:
			    outputDir,
			    [className stringByAppendingPathExtension:@"m"],
			    nil]]
	       atomically:YES
		 encoding:NSUTF8StringEncoding
		    error:NULL];
}

- (void)dealloc {
  self.pbxProjPath = nil;
  self.rootDir = nil;
  [super dealloc];
}

@end

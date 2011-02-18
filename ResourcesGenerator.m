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
#import "NSString+charSetNormalize.h"

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

NSComparator filesSortBlock = ^(id a, id b) {
  return [((NSString *)[a valueForKey:@"name"])
	  compare:[b valueForKey:@"name"]];
};


@end

@implementation ResourcesGenerator

@synthesize pbxProjPath;
@synthesize rootDir;

// avoid c keywords and some objc stuff
+ (BOOL)shouldAvoidName:(NSString *)name {
  static NSSet *names = nil;
  if (names == nil) {
    names = [[NSSet setWithObjects:
	      @"alloc",
	      @"autorelease",
	      @"bycopy",
	      @"byref",
	      @"char",
	      @"const",
	      @"copy",
	      @"dealloc",
	      @"default",
	      @"delete",
	      @"double",
	      @"float",
	      @"id",
	      @"in",
	      @"inout",
	      @"int",
	      @"long",
	      @"new",
	      @"nil",
	      @"oneway",
	      @"out",
	      @"release",
	      @"retain",
	      @"self",
	      @"short",
	      @"signed",
	      @"super",
	      @"unsigned",
	      @"void",
	      @"volatile",
	      nil]
	     retain];
  }
  
  return [names containsObject:name];  
}

+ (NSCharacterSet *)allowedCharacterSet {
  static NSCharacterSet *charSet = nil;
  if (charSet == nil) {
    charSet = [[NSCharacterSet characterSetWithCharactersInString:
		@"abcdefghijklmnopqrstuvwxyz"
		@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		@"_0123456789"]
	       retain];
  }
  
  return charSet;
}

+ (NSString *)classNameForDirComponents:(NSArray *)dirComponents
				   name:(NSString *)name {
  NSMutableArray *parts = [NSMutableArray array];
  
  for (NSString *component in dirComponents) {
    [parts addObject:[[component charSetNormalize:
		       [[self class] allowedCharacterSet]]
		      capitalizedString]];
  }
  
  if (name != nil) {
    [parts addObject:[[name charSetNormalize:
		       [[self class] allowedCharacterSet]]
		      capitalizedString]];
  }
  
  return [parts componentsJoinedByString:@""];
}

+ (NSString *)propertyName:(NSString *)name {
  name = [[name toCamelCase:
	   [NSCharacterSet characterSetWithCharactersInString:@"._-"]]
	  charSetNormalize:
	  [[self class] allowedCharacterSet]];
  
  if ([[self class] shouldAvoidName:name]) {
    name = [name stringByAppendingString:@"_"];
  }
  
  return name;
}

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
  // TODO: nil check
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
	
	// TODO: check for errors and nils
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
  
  for (id key in [dir.files keysSortedByValueUsingComparator:filesSortBlock]) {
    id file = [dir.files objectForKey:key];
    
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
  NSMutableString *definition = [NSMutableString string];
  
  [header appendFormat:@"// Generated from %@\n", self.pbxProjPath];
  [header appendFormat:@"#import <Foundation/Foundation.h>\n\n"];
  
  [definition appendFormat:@"// Generated from %@\n", self.pbxProjPath];
  [definition appendFormat:@"#import \"%@.h\"\n\n", className];
  
  [self rescurseResoucesWithBlock:^(NSArray *dirComponents, id file) {
    if (![file isKindOfClass:[Dir class]]) {
      return;
    }
    [header appendFormat:@"@class %@%@;\n",
     className,
     [[self class] classNameForDirComponents:dirComponents
					name:nil]];
  }];
  [header appendFormat:@"\n"];
  
  [self rescurseResoucesWithBlock:^(NSArray *dirComponents, id file) {
    Dir *dir = file;
    if (![dir isKindOfClass:[Dir class]]) {
      return;
    }
    
    [header appendFormat:@"@interface %@%@ : NSObject\n",
     className,
     [[self class] classNameForDirComponents:dirComponents
					name:nil]];
    
    [definition appendFormat:@"@implementation %@%@\n",
     className,
     [[self class] classNameForDirComponents:dirComponents
					name:nil]];
    
    for (id key in [dir.files keysSortedByValueUsingComparator:filesSortBlock]) {
      Dir *subDir = [dir.files objectForKey:key];
      if (![subDir isKindOfClass:[Dir class]]) {
	continue;
      }
      
      [header appendFormat:@"@property(nonatomic, readonly) %@%@ *%@;\n",
       className,
       [[self class] classNameForDirComponents:dirComponents
					  name:subDir.name],
       [[self class] propertyName:subDir.name]];
      
      [definition appendFormat:@"@synthesize %@;\n",
       [[self class] propertyName:subDir.name]];
    }

    NSMutableDictionary *uniqImages = [NSMutableDictionary dictionary];
    for (File *dirFile  in [dir.files allValues]) {
      if (![dirFile isKindOfClass:[File class]]) {
	continue;
      }
      if (![dirFile.name hasSuffix:@".png"]) {
	continue;
      }
      
      [uniqImages
       setObject:
       dirFile
       forKey:
       [[[dirFile.name stringByDeletingPathExtension]
	 stripSuffix:[NSArray arrayWithObjects:@"@2x", @"-ipad", nil]]
	stringByAppendingPathExtension:[dirFile.name pathExtension]]];
    }
    
    for (id key in [uniqImages keysSortedByValueUsingComparator:filesSortBlock]) {
      //File *imageFile = [uniqImages objectForKey:key];
      
      NSString *properyName = [[self class] propertyName:
			       [key stringByDeletingPathExtension]];
      NSString *path = key;
      if ([dirComponents count] > 0) {
	path = [[NSString pathWithComponents:dirComponents]
		stringByAppendingPathComponent:key];
      }
      
      [header appendFormat:@"@property(nonatomic, readonly) %@%@; // %@\n",
       @"UIImage *",
       properyName,
       path];
      [definition appendFormat:@"@synthesize %@;\n", properyName];
    }
    
    [definition appendFormat:@"\n"];
    
    if ([dirComponents count] == 0) {
      [definition appendFormat:@"+ (void)load {\n"];
      [definition appendFormat:@"  @synchronized(self) {\n"];
      [definition appendFormat:@"    if (R == nil) {\n"];
      [definition appendFormat:@"      R = [[%@ alloc] init];\n", className];
      [definition appendFormat:@"    }\n"];
      [definition appendFormat:@"  }\n"];
      [definition appendFormat:@"}\n"];
      [definition appendFormat:@"\n"];
    }
    
    [definition appendFormat:@"- (id)init {\n"];
    [definition appendFormat:@" self = [super init];\n"];
    
    for (id key in [dir.files keysSortedByValueUsingComparator:filesSortBlock]) {
      Dir *subDir = [dir.files objectForKey:key];
      if (![subDir isKindOfClass:[Dir class]]) {
	continue;
      }
      
      [definition appendFormat:@" self->%@ = [[%@%@ alloc] init];\n",
       [[self class] propertyName:subDir.name],
       className,
       [[self class] classNameForDirComponents:dirComponents
					  name:subDir.name]];
    }
    [definition appendFormat:@" return self;\n"];
    [definition appendFormat:@"}\n"];
    [definition appendFormat:@"\n"];
    
    for (id key in [uniqImages keysSortedByValueUsingComparator:filesSortBlock]) {
      //File *imageFile = [uniqImages objectForKey:key];
      
      NSString *properyName = [[self class] propertyName:
			       [key stringByDeletingPathExtension]];
      NSString *path = key;
      if ([dirComponents count] > 0) {
	path = [[NSString pathWithComponents:dirComponents]
		stringByAppendingPathComponent:key];
      }
      
      [definition appendFormat:@"- (UIImage *)%@ {\n", properyName];
      [definition appendFormat:@"  if (%@ == nil) {\n", properyName];
      [definition appendFormat:@"    return [UIImage imageNamed:@\"%@\"];\n",
       path];
      [definition appendFormat:@"  } else {\n"];
      [definition appendFormat:@"    return [[self->%@ retain] autorelease];\n",
       properyName];
      [definition appendFormat:@"  }\n"];
      [definition appendFormat:@"}\n\n"];
    }
    
    [header appendFormat:@"\n"];
    [header appendFormat:@"- (void)loadImages;\n"];
    [header appendFormat:@"- (void)releaseImages;\n"];
    [header appendFormat:@"@end\n\n"];
    
    [definition appendFormat:@"- (void)loadImages {\n"];
    for (id key in [dir.files keysSortedByValueUsingComparator:filesSortBlock]) {
      Dir *subDir = [dir.files objectForKey:key];
      if (![subDir isKindOfClass:[Dir class]]) {
	continue;
      }
      
      [definition appendFormat:@"  [self->%@ loadImages];\n",
       [[self class] propertyName:subDir.name]];
      
    }
    
    for (id key in [uniqImages keysSortedByValueUsingComparator:filesSortBlock]) {
      NSString *properyName = [[self class] propertyName:
			       [key stringByDeletingPathExtension]];
      NSString *path = key;
      if ([dirComponents count] > 0) {
	path = [[NSString pathWithComponents:dirComponents]
		stringByAppendingPathComponent:key];
      }
      
      [definition appendFormat:@"  self->%@ = [[UIImage imageNamed:@\"%@\"] retain];\n",
       properyName,
       path];
      
    }
    [definition appendFormat:@"}\n"];
    [definition appendFormat:@"\n"];
    [definition appendFormat:@"- (void)releaseImages {\n"];
    for (id key in [dir.files keysSortedByValueUsingComparator:filesSortBlock]) {
      Dir *subDir = [dir.files objectForKey:key];
      if (![subDir isKindOfClass:[Dir class]]) {
	continue;
      }
      
      [definition appendFormat:@"  [self->%@ releaseImages];\n",
       [[self class] propertyName:subDir.name]];
      
    }
    
    for (id key in [uniqImages keysSortedByValueUsingComparator:filesSortBlock]) {
      NSString *properyName = [[self class] propertyName:
			       [key stringByDeletingPathExtension]];
      NSString *path = key;
      if ([dirComponents count] > 0) {
	path = [[NSString pathWithComponents:dirComponents]
		stringByAppendingPathComponent:key];
      }
      
      [definition appendFormat:@"  [self->%@ release];\n", properyName];
      [definition appendFormat:@"  self->%@ = nil;\n", properyName];      
    }
    [definition appendFormat:@"}\n"];
    [definition appendFormat:@"@end\n\n"];
  }];
      
  [header appendFormat:@"%@ *R;\n", className];
  [definition appendFormat:@"%@ *R;\n", className];
  
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

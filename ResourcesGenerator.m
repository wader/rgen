//
//  ResourcesGenerator.m
//  rgen
//
//  Created by Mattias Wadman on 2011-02-17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ResourcesGenerator.h"
#import "rgen.h"
#import "XCodeProj.h"
#import "ImagesProperty.h"
#import "ImageProperty.h"
#import "PathsProperty.h"
#import "PathProperty.h"
#import "ClassGenerator.h"
#import "NSString+rgen.h"
#import "NSCharacterSet+rgen.h"

@implementation ResourcesGeneratorException
@end

@interface ResourcesGenerator ()
@property(nonatomic, retain) XCodeProj *xcodeProj;
@property(nonatomic, retain) ImagesProperty *imagesRoot;
@property(nonatomic, retain) PathsProperty *pathsRoot;

- (void)addPath:(NSArray *)dirComponents 
	   name:(NSString *)name
	   path:(NSString *)path;
- (void)addImage:(NSArray *)dirComponents 
	    name:(NSString *)name
	    path:(NSString *)path;
- (void)loadVariantGroup:(PBXDictionary *)fileRef
	      targetName:(NSString *)targetName;
- (void)loadFileReference:(PBXDictionary *)fileRef
	       targetName:(NSString *)targetName;
- (void)loadResourcesForTarget:(NSString *)targetName;
- (void)raiseFormat:(NSString *)format, ...;

@end

@implementation ResourcesGenerator
@synthesize optionGenerateImages;
@synthesize optionGeneratePaths;
@synthesize optionLoadImages;
@synthesize optionIpadImageSuffx;
@synthesize optionIpad2xImageSuffx;

@synthesize xcodeProj;
@synthesize imagesRoot;
@synthesize pathsRoot;

- (id)initWithProjectFile:(NSString *)aPath {
  self = [super init];
  self.xcodeProj = [[[XCodeProj alloc]
		     initWithPath:aPath
		     environment:[[NSProcessInfo processInfo] environment]]
		    autorelease];
  self.imagesRoot = [[[ImagesProperty alloc]
		      initWithName:@""
		      parent:nil
		      path:@""
		      className:@"RGenImagesRoot"]
		     autorelease];
  self.pathsRoot = [[[PathsProperty alloc]
		     initWithName:@""
		     parent:nil
		     path:@""
		     className:@"RGenPathsRoot"]
		    autorelease];
  
  if (self.xcodeProj == nil) {
    [self raiseFormat:@"Failed to read xcode project file %@", aPath];
  }
  
  return self;
}

- (void)raiseFormat:(NSString *)format, ... {
  if (self.xcodeProj != nil) {
    format = [@": " stringByAppendingString:format];
    format = [[self.xcodeProj projectName] stringByAppendingString:format];
  }
  
  va_list va;
  va_start(va, format);
  [ResourcesGeneratorException raise:@"error" format:format arguments:va];
  va_end(va);
}

- (void)addPath:(NSArray *)dirComponents 
	   name:(NSString *)name
	   path:(NSString *)path {
  NSString *propertyName = [name propertyName];
  
  ClassProperty *classProperty = [self.pathsRoot
				  lookupPropertyPathFromDir:dirComponents];
  if (![classProperty isKindOfClass:[PathsProperty class]]) {
    [self raiseFormat:
     @"Path property path name collision between path %@ and %@",
     classProperty.path, path];
  }
  
  Property *property = [classProperty.properties objectForKey:propertyName];
  if (property != nil) {
    if([path isEqualToString:property.path]) {
      /*
       NSLog(@"Ignoring duplicate for path %@", path);
       */
    } else {
      [self raiseFormat:
       @"Path Property name collision for %@ between paths %@ and %@",
       propertyName, ((Property *)property).path, path];
    }
  } else {    
    [classProperty.properties
     setObject:[[[PathProperty alloc]
		 initWithName:propertyName
		 path:path]
		autorelease]
     forKey:propertyName];
    /*
     NSLog(@"Added image property name %@ for path %@",
     propertyName, path);
     */
  }
}

- (void)addLproj:(NSString *)path {
  NSLog(@"path=%@", path);
}

- (void)addImage:(NSArray *)dirComponents 
	    name:(NSString *)name
	    path:(NSString *)path {
  NSString *propertyName = [name imagePropertyName:self.optionIpadImageSuffx];
  // strip image scale suffix
  NSString *normalizedPath = [path normalizeIOSPath:self.optionIpadImageSuffx];
  
  ClassProperty *classProperty = [self.imagesRoot
				  lookupPropertyPathFromDir:dirComponents];
  if (![classProperty isKindOfClass:[ImagesProperty class]]) {
    [self raiseFormat:
     @"Image property path name collision between path %@ and %@ (real %@)",
     classProperty.path, normalizedPath, path];
  }
  
  Property *property = [classProperty.properties objectForKey:propertyName];
  if (property != nil) {
    if([normalizedPath isEqualToString:property.path]) {
      trace(@"Ignoring duplicate resource for path %@ (real %@)",
	    normalizedPath, path);
    } else {
      [self raiseFormat:
       @"Image property name collision for %@ between paths %@ and %@ (real %@)",
       propertyName, ((Property *)property).path, normalizedPath, path];
    }
  } else {
    NSString *ext = [[path pathExtension] lowercaseString];
    if ([ext isSupportedImageExtByIOS]) {
      [classProperty.properties
       setObject:[[[ImageProperty alloc]
		   initWithName:propertyName
		   path:normalizedPath]
		  autorelease]
       forKey:propertyName];
      
      trace(@"Added image property name %@ for path %@ (real %@)",
	    propertyName, normalizedPath, path);
    } else {
      trace(@"Ignoring unknown resource for path %@ (real %@)",
	    normalizedPath, path);
    }
  }
}

- (void)loadFileReference:(PBXDictionary *)fileRef
	       targetName:(NSString *)targetName {
  NSString *lastKnownFileType = [fileRef objectForKey:@"lastKnownFileType"];
  NSString *sourceTree = [fileRef objectForKey:@"sourceTree"];
  NSString *path = [fileRef objectForKey:@"path"];
  NSString *name = [fileRef objectForKey:@"name"];
  
  if (lastKnownFileType == nil || sourceTree == nil || path == nil) {
    [self raiseFormat:
     @"%@: Missing keys for fileRef in resource build phase "
     @"lastKnownFileType=%@ sourceTree=%@ path=%@ name=%@",
     targetName, pName, lastKnownFileType, sourceTree, path, name];
  }
  
  NSString *absPath = [self.xcodeProj absolutePath:path sourceTree:sourceTree];
  if (absPath == nil) {
    [self raiseFormat:
     @"%@: Could not resolve absolute path for path %@ source tree %@",
     targetName, path, sourceTree];
  }
  
  if (name == nil) {
    name = [path lastPathComponent];
  }
  
  if ([lastKnownFileType isEqualToString:@"folder"]) {
    trace(@"%@: Loading folder reference \"%@\" with absolute path %@",
	  targetName, name, absPath);
    
    NSArray *subpaths = [[NSFileManager defaultManager]
			 subpathsOfDirectoryAtPath:absPath
			 error:NULL];
    if (subpaths == nil) {
      [self raiseFormat: @"%@: Failed to read directory at path %@",
       targetName, absPath];
    }
    
    for (NSString *subpath in subpaths) {
      BOOL isDir = NO;
      if ([[NSFileManager defaultManager]
	   fileExistsAtPath:[absPath stringByAppendingPathComponent:subpath]
	   isDirectory:&isDir] &&
	  isDir) {
	continue;
      }
      
      NSString *filename = [subpath lastPathComponent];
      // prefix path with reference folder name
      NSArray *subpathComponents = [subpath pathComponents];
      subpathComponents = [subpathComponents subarrayWithRange:
			   NSMakeRange(0, [subpathComponents count]-1)];
      NSArray *dirComponents = [[NSArray arrayWithObject:name]
				arrayByAddingObjectsFromArray:subpathComponents];
      
      if ([filename isEqualToString:@"Localizable.strings"]) {
	[self addLproj:[NSString pathWithComponents:
			[NSArray arrayWithObjects:
			 absPath,
			 subpath,
			 nil
			 ]]];
      } else {
	[self addImage:dirComponents
		  name:filename
		  path:[NSString pathWithComponents:
			[dirComponents arrayByAddingObject:filename]]];
	[self addPath:dirComponents
		 name:filename
		 path:[NSString pathWithComponents:
		       [dirComponents arrayByAddingObject:filename]]];
      }
    }
  } else {
    trace(@"%@: Loading file reference \"%@\"", targetName, name); 
    
    [self addImage:[NSArray array]
	      name:name
	      path:name];
    [self addPath:[NSArray array]
	     name:name
	     path:name];
  }
  
}

- (void)loadVariantGroup:(PBXDictionary *)fileRef
	      targetName:(NSString *)targetName {
  
  NSLog(@"fileRef=%@", fileRef.rootObject);
  
  NSArray *children = [fileRef refDictArrayForKey:@"children"];
  if (children == nil) {
    [self raiseFormat:
     @"Failed to read children array for variant group", pName];
  }
  
  for (PBXDictionary *variant in children) {
    NSString *sourceTree = [variant objectForKey:@"sourceTree"];
    NSString *path = [variant objectForKey:@"path"];
    NSString *name = [variant objectForKey:@"name"];
    
    NSLog(@"%@", variant.rootObject);
    
    if (sourceTree == nil || path == nil) {
      [self raiseFormat:
       @"Missing keys for variable group fileRef sourceTree=%@ path=%@ name=%@",
       sourceTree, path, name];
    }
    
    NSString *prefixPath =  [self.xcodeProj absolutePath:name
					      sourceTree:sourceTree];
    if (prefixPath == nil) {
      [self raiseFormat:
       @"Could not resolve prefix path for name %@ source tree %@",
       name, sourceTree];
    }
    
    [self addLproj:[NSString pathWithComponents:
		    [NSArray arrayWithObjects:
		     [prefixPath stringByAppendingPathExtension:@"lproj"],
		     path,
		     nil]]];
  }
}

- (void)loadResourcesForTarget:(NSString *)targetName {
  __block BOOL targetFound = (targetName == nil);
  
  /*
  [self.xcodeProj forEachBuildSetting:^(NSString *buildConfigurationName,
					NSDictionary *buildSettings) {

    NSLog(@"name=%@ settings=%@", buildConfigurationName, buildSettings);
  }];
   */
    
  @try {
    [self.xcodeProj forEachBuildResource:^(NSString *buildTargetName,
					   PBXDictionary *fileRef) {
      if (targetName != nil && ![targetName isEqualToString:buildTargetName]) {
	return;
      }
      targetFound = YES;
      
      NSString *fileIsa = [fileRef objectForKey:@"isa"];
      if ([fileIsa isEqualToString:@"PBXFileReference"]) {
	[self loadFileReference:fileRef targetName:buildTargetName];
      } else if ([fileIsa isEqualToString:@"PBXVariantGroup"]) {
	[self loadVariantGroup:fileRef targetName:buildTargetName];
      } else {
	trace(@"%@: Ignoring fileRef with unknown isa %@", buildTargetName, fileIsa);
      }
    }];
  } @catch (XCodeProjException *e) {
    [self raiseFormat:@"%@", e.reason];
  }
  
  if (!targetFound) {
    [self raiseFormat:@"Could not find target \"%@\"", targetName];
  }
}

- (void)writeResoucesTo:(NSString *)outputDir
	      className:(NSString *)className
	      forTarget:(NSString *)targetName {
  NSString *headerFile = [className stringByAppendingPathExtension:@"h"];
  NSString *implementationFile = [className stringByAppendingPathExtension:@"m"];
  NSMutableString *header = [NSMutableString string];
  NSMutableString *implementation = [NSMutableString string];
  NSMutableArray *classes = [NSMutableArray array];
  
  if (self.optionGenerateImages) {
    [classes addObject:self.imagesRoot];
  }
  
  if (self.optionGeneratePaths) {
    [classes addObject:self.pathsRoot];
  }
  
  [self loadResourcesForTarget:targetName];
  
  // prune trees by removing empty classes
  for (ClassProperty *classProperty in classes) {
    [classProperty pruneEmptyClasses];
  }
  
  NSMutableString *generatedBy = [NSMutableString string];
  [generatedBy appendString:@"// This file was generated by rgen\n"];
  [generatedBy appendFormat:@"// Project: %@\n", [self.xcodeProj projectName]];
  if (targetName != nil) {
    [generatedBy appendFormat:@"// Target : %@\n", targetName];
  }
  [generatedBy appendString:@"\n"];
  [header appendString:generatedBy];
  [implementation appendString:generatedBy];
  [implementation appendFormat:@"#import \"%@\"\n\n", headerFile];
  
  for (ClassProperty *classProperty in classes) {
    [classProperty rescursePreOrder:^(NSArray *propertyPath,
				      ClassProperty *classProperty) {
      [header appendFormat:@"@class %@;\n", classProperty.className];
    }];
    [header appendString:@"\n"];
  }
  
  for (ClassProperty *classProperty in classes) {
    [header appendString:[classProperty headerProlog:self]];
    [header appendString:@"\n"];
  }
  
  for (ClassProperty *classProperty in classes) {
    [implementation appendString:[classProperty implementationProlog:self]];
    [implementation appendString:@"\n"];
  }
  
  for (ClassProperty *classProperty in classes) {
    [classProperty rescursePreOrder:^(NSArray *propertyPath,
				      ClassProperty *classProperty) {
      ClassGenerator *classGenerator = [[[ClassGenerator alloc]
					 initWithClassName:classProperty.className
					 inheritName:[classProperty inheritClassName]]
					autorelease];
      [classProperty generate:classGenerator generator:self];
      
      [header appendString:[classGenerator header]];
      [header appendString:@"\n"];
      [implementation appendString:[classGenerator implementation]];
      [implementation appendString:@"\n"];
    }];
  }
  
  NSString *headerPath = [NSString pathWithComponents:
			  [NSArray arrayWithObjects:
			   outputDir, headerFile, nil]];
  NSString *implementationPath = [NSString pathWithComponents:
				  [NSArray arrayWithObjects:
				   outputDir, implementationFile, nil]];
  
  NSString *oldHeader = [NSString stringWithContentsOfFile:headerPath
						  encoding:NSUTF8StringEncoding
						     error:NULL];
  NSString *oldImplementation = [NSString stringWithContentsOfFile:implementationPath
							  encoding:NSUTF8StringEncoding
							     error:NULL];
  if (oldHeader != nil && [header isEqualToString:oldHeader] &&
      oldImplementation != nil && [implementation isEqualToString:oldImplementation]) {
    trace(@"Both header (%@) and implementation (%@) is same as on file system. "
	  @"Skipping write.",
	  headerPath, implementationPath);
    return;
  }
  
  if ([header writeToFile:headerPath
	       atomically:YES
		 encoding:NSUTF8StringEncoding
		    error:NULL]) {
    trace(@"Wrote header to %@", headerPath);
  } else {
    [self raiseFormat:@"Failed to write header to %@", headerPath];
  }
  if ([implementation writeToFile:implementationPath
		       atomically:YES
			 encoding:NSUTF8StringEncoding
			    error:NULL]) {
    trace(@"Wrote implementation to %@", implementationPath);
  }  else {
    [self raiseFormat:@"Failed to write implementation to %@", implementationPath];
  }
}

- (void)dealloc {
  self.xcodeProj = nil;
  self.imagesRoot = nil;
  self.pathsRoot = nil;
  [super dealloc];
}

@end

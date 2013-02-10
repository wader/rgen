/*
 * ResourcesGenerator.m, the glue class
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

#import "ResourcesGenerator.h"
#import "rgen.h"
#import "ImageProperty.h"
#import "PathProperty.h"
#import "ClassGenerator.h"
#import "NSString+rgen.h"
#import "NSCharacterSet+rgen.h"

static NSString *const LocalizableStringName = @"Localizable.strings";

@implementation ResourcesGeneratorException
@end

@interface ResourcesGenerator ()
@property(nonatomic, retain) XcodeProj *xcodeProj;
@property(nonatomic, retain) ImagesProperty *imagesRoot;
@property(nonatomic, retain) PathsProperty *pathsRoot;
@property(nonatomic, retain) StringKeysProperty *stringKeysRoot;

- (void)addImage:(NSArray *)dirComponents 
	    name:(NSString *)name
	    path:(NSString *)path;
- (void)addPath:(NSArray *)dirComponents 
	   name:(NSString *)name
	   path:(NSString *)path;
- (void)addLocalizableStrings:(NSString *)path
                   targetName:(NSString *)targetName;
- (void)loadFileReference:(XCodeFile *)xcodeFile
	       targetName:(NSString *)targetName;
- (void)loadResourcesForTarget:(NSString *)targetName;
- (void)raiseFormat:(NSString *)format, ...;

@end

@implementation ResourcesGenerator
@synthesize optionGenerateImages;
@synthesize optionGeneratePaths;
@synthesize optionGenerateStringKeys;
@synthesize optionLoadImages;
@synthesize optionIpadImageSuffx;
@synthesize optionIpad2xImageSuffx;

@synthesize xcodeProj;
@synthesize imagesRoot;
@synthesize pathsRoot;
@synthesize stringKeysRoot;

- (id)initWithProjectFile:(NSString *)aPath {
  self = [super init];
  if (self == nil) {
    return nil;
  }
  
  self.xcodeProj = [[[XcodeProj alloc]
		     initWithPath:aPath
		     environment:[[NSProcessInfo processInfo] environment]]
		    autorelease];
  if (self.xcodeProj == nil) {
    [self release];
    return nil;
  }
  
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
  self.stringKeysRoot = [[[StringKeysProperty alloc]
			  initWithName:@""
			  parent:nil
			  path:@""
			  className:@"RGenStringKeysRoot"]
			 autorelease];
  
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

- (void)addImage:(NSArray *)dirComponents 
	    name:(NSString *)name
	    path:(NSString *)path {
  if (!self.optionGenerateImages) {
    return;
  }
  
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

- (void)addPath:(NSArray *)dirComponents 
	   name:(NSString *)name
	   path:(NSString *)path {
  if (!self.optionGeneratePaths) {
    return;
  }
  
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
      trace(@"Ignoring duplicate resource for path %@", path);
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
    
    trace(@"Added path property name %@ for path %@",
	  propertyName, path);
  }
}

- (void)addLocalizableStrings:(NSString *)path
                   targetName:(NSString *)targetName {
  if (!self.optionGenerateStringKeys) {
    return;
  }
  
  trace(@"Reading localizable strings file with path %@", path);
  
  NSString *stringsData = [NSString stringWithContentsOfFile:path
                                                    encoding:NSUTF8StringEncoding
                                                       error:NULL];
  if (stringsData == nil) {
    [self raiseFormat:@"%@: Failed to read localizable strings file %@",
     targetName, path];
  }
  
  NSDictionary *strings = [stringsData propertyListFromStringsFileFormat];
  if (strings == nil) {
    [self raiseFormat:@"%@: Failed to deserialize file %@",
     targetName, path];
  }
  
  for (NSString *key in [strings allKeys]) {
    NSString *propertyName = [key propertyName];
    
    [self.stringKeysRoot.properties
     setObject:[[[Property alloc] initWithName:propertyName
					  path:key]
		autorelease]
     forKey:propertyName];
    
    trace(@"Added string key property name %@ for key \"%@\"",
	  propertyName, key);
  }
}

- (void)loadFileReference:(XCodeFile *)xcodeFile
	       targetName:(NSString *)targetName {
  NSString *name = xcodeFile.name;
  BOOL isDir = NO;
  NSString *absPath = [xcodeFile absolutePath];
  
  if (absPath == nil) {
    [self raiseFormat:
     @"%@: Could not resolve absolute path for path %@ source tree %@",
     targetName, xcodeFile.path, xcodeFile.sourceTree];
  }
  
  if (xcodeFile.name == nil) {
    name = [xcodeFile.path lastPathComponent];
  }
  
  if ([[NSFileManager defaultManager] fileExistsAtPath:absPath
                                           isDirectory:&isDir] && isDir) {
    trace(@"%@: Loading folder reference \"%@\" with path %@",
	  targetName, name, absPath);
    
    NSArray *subpaths = [[NSFileManager defaultManager]
			 subpathsOfDirectoryAtPath:absPath
			 error:NULL];
    if (subpaths == nil) {
      [self raiseFormat: @"%@: Failed to read directory at path %@",
       targetName, absPath];
    }
    
    for (NSString *subpath in subpaths) {
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
      
      if ([filename isEqualToString:LocalizableStringName]) {
	[self addLocalizableStrings:[NSString pathWithComponents:
				     [NSArray arrayWithObjects:
				      absPath,
				      subpath,
				      nil]]
                         targetName:targetName];
      } else {
	[self addImage:dirComponents
		  name:filename
		  path:[NSString pathWithComponents:
			[dirComponents arrayByAddingObject:filename]]];
      }
      
      [self addPath:dirComponents
               name:filename
               path:[NSString pathWithComponents:
                     [dirComponents arrayByAddingObject:filename]]];
    }
  } else {
    trace(@"%@: Loading group file \"%@\"", targetName, name); 
    
    [self addImage:[NSArray array]
	      name:name
	      path:name];
    [self addPath:[NSArray array]
	     name:name
	     path:name];
  }
  
}

- (void)loadResourcesForTarget:(NSString *)targetName {
  __block BOOL targetFound = (targetName == nil);
  
  /*
   // TODO: autodetect sdk
   [self.xcodeProj forEachBuildSetting:^(NSString *buildConfigurationName,
   NSDictionary *buildSettings) {
   NSLog(@"name=%@ settings=%@", buildConfigurationName, buildSettings);
   }];
   */
  
  @try {
    [self.xcodeProj forEachBuildResource:^(NSString *buildTargetName,
					   XCodeNode *xcodeNode) {
      if (targetName != nil && ![targetName isEqualToString:buildTargetName]) {
	return;
      }
      targetFound = YES;
      
      if ([xcodeNode isKindOfClass:[XCodeGroup class]]) {
        for (XCodeNode *groupXCodeNode in ((XCodeGroup *)xcodeNode).children) {
          if ([groupXCodeNode isKindOfClass:[XCodeFile class]])
            if(groupXCodeNode.path.length >= LocalizableStringName.length &&
               [[groupXCodeNode.path substringFromIndex:groupXCodeNode.path.length-LocalizableStringName.length] isEqualToString:LocalizableStringName]) {
              NSString *path = [groupXCodeNode absolutePath];
              if (path == nil) {
                [self raiseFormat:
                 @"%@: Could resolve path to localizable string path=@% sourceTree=%@",
                 buildTargetName, groupXCodeNode.path, groupXCodeNode.sourceTree];
              }
              
              [self addLocalizableStrings:[groupXCodeNode absolutePath]
															 targetName:buildTargetName];
						}
        }
      } else {
        [self loadFileReference:(XCodeFile *)xcodeNode targetName:buildTargetName];
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
  if (self.optionGenerateStringKeys) {
    [classes addObject:self.stringKeysRoot];
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
  self.stringKeysRoot = nil;
  
  [super dealloc];
}

@end

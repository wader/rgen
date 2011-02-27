//
//  ResourcesGenerator.m
//  rgen
//
//  Created by Mattias Wadman on 2011-02-17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ResourcesGenerator.h"
#import "PBXProj.h"
#import "NSString+rgen.h"
#import "ClassGenerator.h"


@implementation ResourcesGeneratorException
@end

NSComparator propertySortBlock = ^(id a, id b) {
  return [((NSString *)[a valueForKey:@"name"])
	  compare:[b valueForKey:@"name"]];
};

@interface Property : NSObject
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *path;
- (id)initWithName:(NSString *)aName
	      path:(NSString *)aPath;
- (void)generate:(ClassGenerator *)classGenerator;
@end

@interface ImageProperty : Property
@end

@interface ResourcesProperty : Property
@property(nonatomic, retain) NSString *className;
@property(nonatomic, retain) NSMutableDictionary *properties;
- (id)initWithName:(NSString *)aName
	      path:(NSString *)aPath
	 className:(NSString *)aClassName;
- (void)rescursePostOrder:(BOOL)postOrder
	     propertyPath:(NSArray *)propertyPath
		    block:(void (^)(NSArray *propertyPath, Property *property))block;
- (void)rescursePostOrder:(void (^)(NSArray *propertyPath, Property *property))block;
- (void)rescursePreOrder:(void (^)(NSArray *propertyPath, Property *property))block;
@end


@implementation Property
@synthesize name;
@synthesize path;

- (id)initWithName:(NSString *)aName
	      path:(NSString *)aPath {
  self = [super init];
  self.name = aName;
  self.path = aPath;
  return self;
}

- (void)generate:(ClassGenerator *)classGenerator {
}

- (void)dealloc {
  self.name = nil;
  self.path = nil;
  [super dealloc];
}

@end


@implementation ImageProperty : Property

- (void)generate:(ClassGenerator *)classGenerator {
  [classGenerator.variables addObject:
   [NSString stringWithFormat:
    @"  UIImage *%@; // %@",
    self.name,
    self.path
    ]];
  
  [classGenerator.properties addObject:
   [NSString stringWithFormat:
    @"@property(nonatomic, readonly) UIImage *%@; // %@",
    self.name,
    self.path
    ]];
  
  [classGenerator.synthesizes addObject:
   [NSString stringWithFormat:@"@synthesize %@;", self.name]];
  
  [classGenerator.implementations addObject:
   [NSString stringWithFormat:
    @"- (UIImage *)%@ {\n"
    @"  if (%@ == nil)\n"
    @"    return [UIImage imageNamed:@\"%@\"];\n"
    @"  else\n"
    @"    return [[self->%@ retain] autorelease];\n"
    @"}",
    self.name,
    self.name,
    [self.path escapeCString],
    self.name
    ]];
}

@end

// also used for root Resources class
@implementation ResourcesProperty : Property

@synthesize className;
@synthesize properties;

- (id)initWithName:(NSString *)aName
	      path:(NSString *)aPath
	 className:(NSString *)aClassName {
  self = [super initWithName:aName path:aPath];
  self.className = aClassName;
  self.properties = [NSMutableDictionary dictionary];
  return self;
}

- (void)generate:(ClassGenerator *)classGenerator {
  [classGenerator.declarations addObject:
   [NSString stringWithString:
    @"- (void)loadImages;\n"
    @"- (void)releaseImages;"
    ]];
  
  [classGenerator.implementations addObject:
   [NSString stringWithString:
    @"- (id)init {\n"
    @"  self = [super init];"
    ]];
  for(id key in [self.properties keysSortedByValueUsingComparator:
		 propertySortBlock]) {
    ResourcesProperty *resourcesProperty = [self.properties objectForKey:key];
    if (![resourcesProperty isKindOfClass:[ResourcesProperty class]]) {
      continue;
    }
    
    [classGenerator.variables addObject:
     [NSString stringWithFormat:
      @"  %@ *%@; // %@",
      resourcesProperty.className,
      resourcesProperty.name,
      resourcesProperty.path
      ]];
    
    [classGenerator.properties addObject:
     [NSString stringWithFormat:
      @"@property(nonatomic, readonly) %@ *%@; // %@",
      resourcesProperty.className,
      resourcesProperty.name,
      resourcesProperty.path
      ]];
    
    [classGenerator.synthesizes addObject:
     [NSString stringWithFormat:@"@synthesize %@;", resourcesProperty.name]];
    
    [classGenerator.implementations addObject:
     [NSString stringWithFormat:
      @"  self->%@ = [[%@ alloc] init];",
      resourcesProperty.name,
      resourcesProperty.className
      ]];
  }
  [classGenerator.implementations addObject:
   [NSString stringWithString:
    @"  return self;\n"
    @"}"
    ]];
  
  [classGenerator.implementations addObject:
   [NSString stringWithString:@"- (void)loadImages {"]];
  for(id key in [self.properties keysSortedByValueUsingComparator:
		 propertySortBlock]) {
    Property *property = [self.properties objectForKey:key];
    if ([property isKindOfClass:[ImageProperty class]]) {
      ImageProperty *imageProperty = (ImageProperty *)property;
      [classGenerator.implementations addObject:
       [NSString stringWithFormat:
	@"  self->%@ = [[UIImage imageNamed:@\"%@\"] retain];",
	imageProperty.name,
	[imageProperty.path escapeCString]
	]];
    } else if ([property isKindOfClass:[ResourcesProperty class]]) {
      ResourcesProperty *resourcesProperty = (ResourcesProperty *)property;
      [classGenerator.implementations addObject:
       [NSString stringWithFormat:
	@"  [self->%@ loadImages];",
	resourcesProperty.name
	]];
    }
  }
  [classGenerator.implementations addObject:
   [NSString stringWithString:@"}"]];
  
  [classGenerator.implementations addObject:
   [NSString stringWithString:@"- (void)releaseImages {"]];
  for(id key in [self.properties keysSortedByValueUsingComparator:
		 propertySortBlock]) {
    Property *property = [self.properties objectForKey:key];
    if ([property isKindOfClass:[ImageProperty class]]) {
      ImageProperty *imageProperty = (ImageProperty *)property;
      // TODO: escape path
      [classGenerator.implementations addObject:
       [NSString stringWithFormat:
	@"  [self->%@ release];\n"
	@"  self->%@ = nil;",
	imageProperty.name,
	imageProperty.name
	]];
    } else if ([property isKindOfClass:[ResourcesProperty class]]) {
      ResourcesProperty *resourcesProperty = (ResourcesProperty *)property;
      [classGenerator.implementations addObject:
       [NSString stringWithFormat:
	@"  [self->%@ releaseImages];",
	resourcesProperty.name
	]];
    }
  }
  [classGenerator.implementations addObject:
   [NSString stringWithString:@"}"]];
  
  for(id key in [self.properties keysSortedByValueUsingComparator:
		 propertySortBlock]) {
    ImageProperty *imageProperty = [self.properties objectForKey:key];
    if (![imageProperty isKindOfClass:[ImageProperty class]]) {
      continue;
    }
    
    [imageProperty generate:classGenerator];
  }
}

- (void)rescursePostOrder:(BOOL)postOrder
	     propertyPath:(NSArray *)propertyPath
		    block:(void (^)(NSArray *propertyPath, Property *property))block {
  if (!postOrder) {
    block(propertyPath, self);
  }
  
  for (id key in [self.properties keysSortedByValueUsingComparator:
		  propertySortBlock]) {
    Property *property = [self.properties objectForKey:key];    
    
    if ([property isKindOfClass:[ResourcesProperty class]]) {
      ResourcesProperty *resourcesProperty = (ResourcesProperty *)property;
      [resourcesProperty rescursePostOrder:postOrder
			      propertyPath:[propertyPath arrayByAddingObject:self.name]
				     block:block];
    } else {
      block(propertyPath, property);
    }
  }
  
  if (postOrder) {
    block(propertyPath, self);
  }
}

- (void)rescursePostOrder:(void (^)(NSArray *propertyPath, Property *property))block {
  [self rescursePostOrder:YES
	     propertyPath:[NSArray array]
		    block:block];
}

- (void)rescursePreOrder:(void (^)(NSArray *propertyPath, Property *property))block {
  [self rescursePostOrder:NO
	     propertyPath:[NSArray array]
		    block:block];
}

- (void)dealloc {
  self.className = nil;
  self.properties = nil;
  [super dealloc];
}

@end


@interface ResourcesGenerator ()
@property(nonatomic, retain) NSString *pbxProjPath;
@property(nonatomic, retain) PBXProj *pbxProj;

+ (BOOL)shouldAvoidName:(NSString *)name;
+ (NSCharacterSet *)allowedCharacterSet;
+ (NSCharacterSet *)allowedStartCharacterSet;
+ (NSSet *)supportedImageExtByIOSSet;
+ (NSString *)normalizPath:(NSString *)path;
+ (NSString *)propertyName:(NSString *)name
		     isDir:(BOOL)isDir;

- (void)loadResources:(ResourcesProperty *)rootResources
	    forTarget:(NSString *)targetName;

- (void)raiseFormat:(NSString *)format, ...;

@end

@implementation ResourcesGenerator

@synthesize pbxProjPath;
@synthesize pbxProj;

// avoid C keywords and some Objective-C stuff
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
	      // rgen reserved
	      @"loadImages",
	      @"releaseImages",
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

+ (NSCharacterSet *)allowedStartCharacterSet {
  static NSCharacterSet *charSet = nil;
  if (charSet == nil) {
    charSet = [[NSCharacterSet characterSetWithCharactersInString:
		@"abcdefghijklmnopqrstuvwxyz"
		@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		@"_"]
	       retain];
  }
  
  return charSet;
}

+ (NSSet *)supportedImageExtByIOSSet {
  static NSSet *exts = nil;
  if (exts == nil) {
    // from UIImage class reference "Supported Image Formats"
    exts = [[NSSet setWithObjects:
	     @"tiff", @"tif",
	     @"jpg", @"jpeg",
	     @"gif",
	     @"png",
	     @"bmp", @"bmpf",
	     @"ico",
	     @"cur",
	     @"xbm",
	     nil]
	    retain];
  }
  
  return exts;
}

+ (NSArray *)imageScaleSuffixArray {
  static NSArray *suffixes = nil;
  if (suffixes == nil) {
    suffixes = [[NSArray arrayWithObjects:
		 @"@2x",
		 nil]
		retain];
  }
  
  return suffixes;
}

+ (NSString *)classNameForDirComponents:(NSArray *)dirComponents {
  NSMutableArray *parts = [NSMutableArray array];
  
  for (NSString *component in dirComponents) {
    [parts addObject:[[component charSetNormalize:
		       [[self class] allowedCharacterSet]]
		      capitalizedString]];
  }
  
  return [parts componentsJoinedByString:@""];
}

+ (NSString *)normalizPath:(NSString *)path {
  if ([[[self class] supportedImageExtByIOSSet] containsObject:
       [[path pathExtension] lowercaseString]]) {
    return [[[path stringByDeletingPathExtension]
	     stripSuffix:[[self class] imageScaleSuffixArray]]
	    stringByAppendingPathExtension:[path pathExtension]];
  }
  
  return path;
}

+ (NSString *)propertyName:(NSString *)name
		     isDir:(BOOL)isDir {
  if (!isDir) {
    NSString *ext = [[name pathExtension] lowercaseString];
    name = [name stringByDeletingPathExtension];
    
    if ([[[self class] supportedImageExtByIOSSet] containsObject:ext]) {
      name = [name stripSuffix:[[self class] imageScaleSuffixArray]];
    }
  }
  
  name = [[name toCamelCase:
	   [NSCharacterSet characterSetWithCharactersInString:@"._-"]]
	  charSetNormalize:
	  [[self class] allowedCharacterSet]];
  
  if ([[self class] shouldAvoidName:name]) {
    name = [name stringByAppendingString:@"_"];
  }
  
  if (![[[self class] allowedStartCharacterSet]
	characterIsMember:[name characterAtIndex:0]]) {
    name = [@"_" stringByAppendingString:name];
  }
  
  return name;
}

- (id)initWithProjectFile:(NSString *)aPath {
  self = [super init];
  self.pbxProjPath = aPath;
  self.pbxProj = [[[PBXProj alloc]
		   initWithProjectFile:aPath
		   environment:[[NSProcessInfo processInfo] environment]]
		  autorelease];
  
  if (self.pbxProj == nil) {
    [self raiseFormat:@"Failed to read pbxproj file"];
  }
  
  return self;
}

- (void)raiseFormat:(NSString *)format, ... {
  format = [@": " stringByAppendingString:format];
  if (self.pbxProj == nil) {
    format = [self.pbxProjPath stringByAppendingString:format];
  } else {
    format = [[self.pbxProj projectName] stringByAppendingString:format];
  }
  
  va_list va;
  va_start(va, format);
  [ResourcesGeneratorException raise:@"error" format:format arguments:va];
  va_end(va);
}

- (void)addResource:(ResourcesProperty *)rootResources
		dir:(NSArray *)dirComponents 
	       name:(NSString *)name
	       path:(NSString *)path {
  NSString *propertyName = [[self class] propertyName:name isDir:NO];
  
  // strip image scale suffix
  path = [[self class] normalizPath:path];
  
  NSUInteger i = 1;
  ResourcesProperty *current = rootResources;
  for (NSString *dirName in dirComponents) {
    NSString *nextPropertyName = [[self class] propertyName:dirName isDir:YES];
    NSArray *nextDirComponents = [dirComponents
				  subarrayWithRange:NSMakeRange(0, i)];
    ResourcesProperty *next = [current.properties
			       objectForKey:nextPropertyName];
    
    if (next == nil) {
      next = [[[ResourcesProperty alloc]
	       initWithName:nextPropertyName
	       path:[NSString pathWithComponents:nextDirComponents]
	       className:
	       [rootResources.className stringByAppendingString:
		[[self class] classNameForDirComponents:nextDirComponents]]]
	      autorelease];
      
      [current.properties setObject:next forKey:nextPropertyName];
    } else if (![next isKindOfClass:[ResourcesProperty class]]) {
      [self raiseFormat:
       @"Property name collision for %@ between paths %@ and %@",
       nextPropertyName, ((Property *)next).path, path];
    }
    
    current = next;
    i++;
  }
  
  Property *property = [current.properties objectForKey:propertyName];
  if (property != nil) {
    if([path isEqualToString:property.path]) {
      /*
       NSLog(@"Ignoring duplicate for path %@", path);
       */
    } else {
      [self raiseFormat:
       @"Property name collision for %@ between paths %@ and %@",
       propertyName, ((Property *)property).path, path];
    }
  } else {
    
    NSString *ext = [[path pathExtension] lowercaseString];
    
    if ([[[self class] supportedImageExtByIOSSet] containsObject:ext]) {
      [current.properties
       setObject:[[[ImageProperty alloc]
		   initWithName:propertyName
		   path:path]
		  autorelease]
       forKey:propertyName];
      /*
       NSLog(@"Added image property name %@ for path %@",
       propertyName, path);
       */
    } else {
      /*
       NSLog(@"Ignoring unknown type for path %@", path);
       */
    }
  }	
}

- (void)loadResources:(ResourcesProperty *)rootResources
	    forTarget:(NSString *)targetName {
  BOOL targetFound = targetName == nil;
  
  NSArray *targets = [self.pbxProj.rootDictionary arrayForKey:@"targets"];
  if (targets == nil) {
    [self raiseFormat:@"Failed to read targets array"];
  }
  
  for (PBXProjDictionary *target in targets) {    
    NSString *pName = [target objectForKey:@"name"];
    if (pName == nil || ![pName isKindOfClass:[NSString class]]) {
      continue;
    }
    
    if (targetName != nil && ![targetName isEqualToString:pName]) {
      continue;
    }
    targetFound = YES;
    
    NSArray *buildPhases = [target arrayForKey:@"buildPhases"];
    if (buildPhases == nil) {
      [self raiseFormat:@"Failed to read buildPhases array for target \"%@\"",
       pName];
    }
    
    for (PBXProjDictionary *buildPhase in buildPhases) {
      NSString *isa = [buildPhase objectForKey:@"isa"];
      
      if (isa == nil || ![isa isEqualToString:@"PBXResourcesBuildPhase"]) {
	continue;
      }
      
      NSArray *files = [buildPhase arrayForKey:@"files"];
      if (files == nil) {
	[self raiseFormat:
	 @"Failed to read files array for resource build phase for target \"%@\"",
	 pName];
      }
      
      for (PBXProjDictionary *file in files) {
	PBXProjDictionary *fileRef = [file dictForKey:@"fileRef"];
	if (fileRef == nil) {
	  [self raiseFormat:
	   @"Failed to read fileRef for file in resource build phase for target \"%@\"",
	   pName];
	}
	
	NSString *lastKnownFileType = [fileRef objectForKey:@"lastKnownFileType"];
	NSString *sourceTree = [fileRef objectForKey:@"sourceTree"];
	NSString *path = [fileRef objectForKey:@"path"];
	NSString *name = [fileRef objectForKey:@"name"];
	
	if (lastKnownFileType == nil || sourceTree == nil || path == nil) {
	  [self raiseFormat:
	   @"Missing keys for fileRef in resource build phase for target \"%@\" "
	   @"lastKnownFileType=%@ sourceTree=%@ path=%@ name=%@",
	   pName, lastKnownFileType, sourceTree, path, name];
	}
	
	if (name == nil) {
	  name = [path lastPathComponent];
	}
	
	// TODO: check for errors and nils
	NSString *absPath = [self.pbxProj absolutePath:path sourceTree:sourceTree];
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
	    // prefix path with reference folder name
	    NSArray *subpathComponents = [subpath pathComponents];
	    subpathComponents = [subpathComponents subarrayWithRange:
				 NSMakeRange(0, [subpathComponents count]-1)];
	    NSArray *dirComponents = [[NSArray arrayWithObject:name]
				      arrayByAddingObjectsFromArray:subpathComponents];
	    
	    [self addResource:rootResources
			  dir:dirComponents
			 name:filename
			 path:[NSString pathWithComponents:
			       [dirComponents arrayByAddingObject:filename]]];
	  }
	} else {
	  [self addResource:rootResources
			dir:[NSArray array]
		       name:name
		       path:name];
	}
      }      
    }
  }
  
  if (!targetFound) {
    [self raiseFormat:@"Could not find target \"%@\"", targetName];
  }
}

- (void)writeResoucesTo:(NSString *)outputDir
	      className:(NSString *)className
	      forTarget:(NSString *)targetName {
  ResourcesProperty *rootResources = [[[ResourcesProperty alloc]
				       initWithName:@""
				       path:@""
				       className:className]
				      autorelease];
  NSMutableString *header = [NSMutableString string];
  NSMutableString *implementation = [NSMutableString string];
  
  [self loadResources:rootResources
	    forTarget:targetName];
  
  // prune classes with no properties
  [rootResources rescursePostOrder:^(NSArray *propertyPath, Property *property) {
    ResourcesProperty *resourcesProperty = (ResourcesProperty *)property;
    if (![resourcesProperty isKindOfClass:[ResourcesProperty class]]) {
      return;
    }
    
    NSMutableArray *remove = [NSMutableArray array];
    for(id key in [resourcesProperty.properties allKeys]) {
      ResourcesProperty *subResourcesProperty = [resourcesProperty.properties
						 objectForKey:key];
      if (![subResourcesProperty isKindOfClass:[ResourcesProperty class]] ||
	  [subResourcesProperty.properties count] > 0) {
	continue;
      }
      
      [remove addObject:key];
    }
    
    [resourcesProperty.properties removeObjectsForKeys:remove];
  }];
  
  NSMutableString *generatedBy = [NSMutableString string];
  [generatedBy appendString:@"// This file was generated by rgen\n"];
  [generatedBy appendFormat:@"// Project: %@\n", [self.pbxProj projectName]];
  if (targetName != nil) {
    [generatedBy appendFormat:@"// Target : %@\n", targetName];
  }
  [generatedBy appendString:@"\n"];
  
  [header appendString:generatedBy];
  [implementation appendString:generatedBy];
  
  [implementation appendFormat:@"#import \"%@.h\"\n\n", className];
  
  [rootResources rescursePreOrder:^(NSArray *propertyPath, Property *property) {
    ResourcesProperty *resourcesProperty = (ResourcesProperty *)property;
    if (![resourcesProperty isKindOfClass:[ResourcesProperty class]]) {
      return;
    }
    
    [header appendFormat:@"@class %@;\n", resourcesProperty.className];
  }];
  [header appendString:@"\n"];
  
  [header appendFormat:@"%@ *R;\n\n", className];
  [implementation appendFormat:@"%@ *R;\n\n", className];
  
  [rootResources rescursePreOrder:^(NSArray *propertyPath, Property *property) {
    ResourcesProperty *resourcesProperty = (ResourcesProperty *)property;
    if (![resourcesProperty isKindOfClass:[ResourcesProperty class]]) {
      return;
    }
    
    ClassGenerator *classGenerator = [[[ClassGenerator alloc]
				       initWithClassName:resourcesProperty.className
				       inheritName:@"NSObject"]
				      autorelease];
    
    if (resourcesProperty == rootResources) {
      [classGenerator.implementations addObject:
       [NSString stringWithFormat:
	@"+ (void)load {\n"
	@"  R = [[%@ alloc] init];\n"
	@"}\n",
	className]
       ];
    }
    
    [resourcesProperty generate:classGenerator];
    
    [header appendString:[classGenerator generateHeader]];
    [header appendString:@"\n"];
    [implementation appendString:[classGenerator generateImplementation]];
    [implementation appendString:@"\n"];
  }];
  
  NSString *headerPath = [NSString pathWithComponents:
			  [NSArray arrayWithObjects:
			   outputDir,
			   [className stringByAppendingPathExtension:@"h"],
			   nil]];
  NSString *implementationPath = [NSString pathWithComponents:
				  [NSArray arrayWithObjects:
				   outputDir,
				   [className stringByAppendingPathExtension:@"m"],
				   nil]];
  
  NSString *oldHeader = [NSString stringWithContentsOfFile:headerPath
						  encoding:NSUTF8StringEncoding
						     error:NULL];
  NSString *oldImplementation = [NSString stringWithContentsOfFile:implementationPath
							  encoding:NSUTF8StringEncoding
							     error:NULL];
  if (oldHeader != nil && [header isEqualToString:oldHeader] &&
      oldImplementation != nil && [implementation isEqualToString:oldImplementation]) {
    // source on disk is same as generated
    return;
  }
  
  [header writeToFile:headerPath
	   atomically:YES
	     encoding:NSUTF8StringEncoding
		error:NULL];
  [implementation writeToFile:implementationPath
		   atomically:YES
		     encoding:NSUTF8StringEncoding
			error:NULL];
}

- (void)dealloc {
  self.pbxProjPath = nil;
  self.pbxProj = nil;
  [super dealloc];
}

@end

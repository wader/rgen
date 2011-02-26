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
@property(nonatomic, retain) NSMutableDictionary *properties;
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
   [NSString stringWithFormat:@"@synthesize %@", self.name]];
  
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
    self.path,
    self.name
    ]];
}

@end

// also used for root Resources class
@implementation ResourcesProperty : Property

@synthesize properties;

- (id)initWithName:(NSString *)aName
	      path:(NSString *)aPath {
  self = [super initWithName:aName path:aPath];
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
    
    [classGenerator.synthesizes addObject:
     [NSString stringWithFormat:@"@synthesize %@", resourcesProperty.name]];
    
    [classGenerator.implementations addObject:
     [NSString stringWithFormat:
      @"  self->%@ = [[%@ alloc] init];",
      resourcesProperty.name,
      @"Bla"
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
      // TODO: escape path
      [classGenerator.implementations addObject:
       [NSString stringWithFormat:
	@"  self->%@ = [[UImage imageNamed:@\"%@\"] retain];",
	imageProperty.name,
	imageProperty.path
	]];
    } else if ([property isKindOfClass:[ResourcesProperty class]]) {
      ResourcesProperty *resourcesProperty = (ResourcesProperty *)property;
      [classGenerator.implementations addObject:
       [NSString stringWithFormat:
	@"  [self->%@ loadImages]",
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
	imageProperty.path
	]];
    } else if ([property isKindOfClass:[ResourcesProperty class]]) {
      ResourcesProperty *resourcesProperty = (ResourcesProperty *)property;
      [classGenerator.implementations addObject:
       [NSString stringWithFormat:
	@"  [self->%@ releaseImages]",
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

- (void)rescurseWithBlock:(void (^)(NSArray *dirComponents, Property *property))block
	     propertyPath:(NSArray *)propertyPath {
  
  block(propertyPath, self);
  
  for (id key in [self.properties keysSortedByValueUsingComparator:
		  propertySortBlock]) {
    Property *property = [self.properties objectForKey:key];    
    
    if ([property isKindOfClass:[ResourcesProperty class]]) {
      ResourcesProperty *resourcesProperty = (ResourcesProperty *)property;
      [resourcesProperty rescurseWithBlock:block
			      propertyPath:[propertyPath arrayByAddingObject:self.name]];
    } else {
      block(propertyPath, property);
    }
  }  
}

- (void)rescurseWithBlock:(void (^)(NSArray *dirComponents, Property *property))block {
  [self rescurseWithBlock:block
	     propertyPath:[NSArray array]];
}

}


- (void)dealloc {
  self.properties = nil;
  [super dealloc];
}

@end


@interface ResourcesGenerator ()
@property(nonatomic, retain) NSString *pbxProjPath;
@property(nonatomic, retain) PBXProj *pbxProj;
@property(nonatomic, retain) ResourcesProperty *root;

+ (BOOL)shouldAvoidName:(NSString *)name;
+ (NSCharacterSet *)allowedCharacterSet;
+ (NSSet *)supportedImageExtByIOSSet;
+ (NSString *)normalizPath:(NSString *)path;
+ (NSString *)propertyName:(NSString *)name
		     isDir:(BOOL)isDir;

- (void)loadResourcesForTarget:(NSString *)targetName;

@end

@implementation ResourcesGenerator

@synthesize pbxProjPath;
@synthesize pbxProj;
@synthesize root;

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
  
  return name;
}

- (id)initWithProjectFile:(NSString *)aPath {
  self = [super init];
  self.pbxProjPath = aPath;
  self.pbxProj = [[[PBXProj alloc]
		   initWithProjectFile:aPath
		   environment:[[NSProcessInfo processInfo] environment]]
		  autorelease];
  self.root = [[[ResourcesProperty alloc]
		initWithName:@""
		path:@""]
	       autorelease];
  return self;
}


- (void)addResourceToDir:(NSArray *)dirComponents 
		    name:(NSString *)name
		    path:(NSString *)path {
  NSString *propertyName = [[self class] propertyName:name isDir:NO];
  
  // strip image scale suffix
  path = [[self class] normalizPath:path];
  
  ResourcesProperty *current = self.root;
  for (NSString *dirName in dirComponents) {
    NSString *nextPropertyName = [[self class] propertyName:dirName isDir:YES];
    ResourcesProperty *next = [current.properties
			       objectForKey:nextPropertyName];
    
    if (next == nil) {
      next = [[[ResourcesProperty alloc]
	       initWithName:nextPropertyName
	       path:path]
	      autorelease];
      [current.properties setObject:next forKey:nextPropertyName];
    } else if (![next isKindOfClass:[ResourcesProperty class]]) {
      NSLog(@"Property name collision for %@ between paths %@ and %@",
	    nextPropertyName, ((Property *)next).path, path);
    }
    
    current = next;
  }
  
  Property *property = [current.properties objectForKey:propertyName];
  if (property != nil) {
    if([path isEqualToString:property.path]) {
      //NSLog(@"Ignoring duplicate for path %@", path);
    } else {
      NSLog(@"Property name collision for %@ between paths %@ and %@",
	    propertyName, ((Property *)property).path, path);
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

- (void)loadResourcesForTarget:(NSString *)targetName {
  // TODO: nil check
  for (PBXProjDictionary *p in [self.pbxProj.rootDictionary arrayForKey:@"targets"]) {    
    NSString *pName = [p objectForKey:@"name"];
    if (pName == nil || ![pName isKindOfClass:[NSString class]]) {
      continue;
    }
    
    if (targetName != nil && ![targetName isEqualToString:pName]) {
      continue;
    }
    
    NSLog(@"BLA %@ %@", targetName, p.rootObject);
    
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
	    
	    [self addResourceToDir:dirComponents
			      name:filename
			      path:[NSString pathWithComponents:
				    [dirComponents arrayByAddingObject:filename]]];
	  }
	} else {
	  [self addResourceToDir:[NSArray array]
			    name:name
			    path:name];
	}
      }      
    }
  }
}

- (void)writeResoucesTo:(NSString *)outputDir
	      className:(NSString *)className
	      forTarget:(NSString *)targetName {
  NSMutableString *header = [NSMutableString string];
  NSMutableString *implementation = [NSMutableString string];
  
  [self loadResourcesForTarget:targetName];
  
  NSString *generatedWith = @"// This file was generated with rgen\n\n";
  [header appendString:generatedWith];
  [implementation appendString:generatedWith];
  
  [self.root rescurseWithBlock:^(NSArray *dirComponents, Property *property) {
    ResourcesProperty *resourcesProperty = (ResourcesProperty *)property;
    if (![resourcesProperty isKindOfClass:[ResourcesProperty class]]) {
      return;
    }
    
    ClassGenerator *classGenerator = [[[ClassGenerator alloc]
				       initWithClassName:resourcesProperty.name
				       inheritName:@"NSObject"]
				      autorelease];
    
    if (resourcesProperty == self.root) {
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
  self.root = nil;
  [super dealloc];
}

@end

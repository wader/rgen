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
#import "ClassGenerator.h"


NSComparator propertySortBlock = ^(id a, id b) {
  return [((NSString *)[a valueForKey:@"name"])
	  compare:[b valueForKey:@"name"]];
};

@interface Property : NSObject
@property(nonatomic, retain) NSString *name;

- (void)generate:(ClassGenerator *)classGenerator;

@end

@interface ImageProperty : Property
@property(nonatomic, retain) NSString *path;
@end

@interface ResourcesProperty : Property
@property(nonatomic, retain) NSMutableDictionary *properties;
@end

@implementation Property

@synthesize name;

- (id)initWithName:(NSString *)aName {
  self = [super init];
  self.name = aName;
  return self;
}

- (void)generate:(ClassGenerator *)classGenerator {
}

- (void)dealloc {
  self.name = nil;
  [super dealloc];
}

@end

@implementation ImageProperty : Property

@synthesize path;

- (id)initWithName:(NSString *)aName
	      path:(NSString *)aPath {
  self = [super initWithName:aName];
  self.path = aPath;
  return self;
}

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

- (void)dealloc {
  self.path = nil;
  [super dealloc];
}

@end

// also used for root Resources class
@implementation ResourcesProperty : Property

@synthesize properties;

- (id)initWithName:(NSString *)aName {
  self = [super initWithName:aName];
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


- (void)dealloc {
  self.properties = nil;
  [super dealloc];
}

@end


@interface ResourcesGenerator ()
@property(nonatomic, retain) ResourcesProperty *root;
@property(nonatomic, retain) NSString *pbxProjPath;
@end

@implementation ResourcesGenerator

@synthesize root;
@synthesize pbxProjPath;

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
  self.root = [[[ResourcesProperty alloc] initWithName:@""] autorelease];
  
  [self loadResources:[[[PBXProj alloc]
			initWithProjectFile:aPath
			environment:[[NSProcessInfo processInfo] environment]]
		       autorelease]];
  
  return self;
}

- (ResourcesProperty *)lookupResourcesProperty:(NSArray *)dirComponents {
  ResourcesProperty *current = self.root;
  
  for (NSString *name in dirComponents) {
    NSString *propertyName = [ResourcesGenerator propertyName:name];
    
    ResourcesProperty *next = [current.properties objectForKey:propertyName];
    if (next == nil) {
      next = [[[ResourcesProperty alloc]
	       initWithName:propertyName]
	      autorelease];
      [current.properties setObject:next
			     forKey:propertyName];
    }
    
    current = next;
  }
  
  return current;
}

- (BOOL)addResourceToDir:(NSArray *)dirComponents 
		    name:(NSString *)name
		    path:(NSString *)path {
  ResourcesProperty *resourcesProperty = [self lookupResourcesProperty:dirComponents];
  
  NSString *propertyName = [ResourcesGenerator propertyName:name];
  Property *property = [resourcesProperty.properties objectForKey:propertyName];
  
  if (property != nil) {
    NSLog(@"property name collision for %@ %@",
	  propertyName,
	  path
	  );
    //return NO;
  }
  
  [resourcesProperty.properties
   setObject:[[[ImageProperty alloc] initWithName:propertyName path:path] autorelease]
   forKey:propertyName];
  
  return YES;
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
	
	NSLog(@"%@", fileRef.rootObject);
	
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
	    
	    [self addResourceToDir:dirComponents
			      name:filename
			      path:[NSString pathWithComponents:
				    [dirComponents arrayByAddingObject:filename]]];
	  }
	} else {
	  [self addResourceToDir:[NSArray array]
			    name:name
			    path:path];
	}
      }      
    }
  }
}

/*
 - (void)rescurseResoucesWithBlock:(void (^)(NSArray *dirComponents, id file))block
 dir:(ResourcesProperty *)dir
 dirComponents:(NSArray *)dirComponents {
 
 block(dirComponents, dir);
 
 for (id key in [dir.files keysSortedByValueUsingComparator:filesSortBlock]) {
 id file = [dir.files objectForKey:key];
 
 NSString *subdir = @"";
 if ([dirComponents count] > 0) {
 subdir = [[NSString pathWithComponents:dirComponents]
 stringByAppendingString:@"/"];
 }
 
 
 if ([file isKindOfClass:[ResourcesProperty class]]) {
 ResourcesProperty *subDir = file;
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
 dir:self.root
 dirComponents:[NSArray array]];
 }
 */
- (void)writeResoucesTo:(NSString *)outputDir
	      className:(NSString *)className {
  NSMutableString *header = [NSMutableString string];
  NSMutableString *implementation = [NSMutableString string];
  
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
  
  //NSLog(@"%@", header);
  NSLog(@"%@", implementation);
  
  /*
   NSMutableString *header = [NSMutableString string];
   NSMutableString *definition = [NSMutableString string];
   
   [header appendFormat:@"// Generated from %@\n", self.pbxProjPath];
   [header appendFormat:@"#import <Foundation/Foundation.h>\n\n"];
   
   [definition appendFormat:@"// Generated from %@\n", self.pbxProjPath];
   [definition appendFormat:@"#import \"%@.h\"\n\n", className];
   
   [self rescurseResoucesWithBlock:^(NSArray *dirComponents, id file) {
   if (![file isKindOfClass:[ResourcesProperty class]]) {
   return;
   }
   [header appendFormat:@"@class %@%@;\n",
   className,
   [[self class] classNameForDirComponents:dirComponents
   name:nil]];
   }];
   [header appendFormat:@"\n"];
   
   [self rescurseResoucesWithBlock:^(NSArray *dirComponents, id file) {
   ResourcesProperty *dir = file;
   if (![dir isKindOfClass:[ResourcesProperty class]]) {
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
   ResourcesProperty *subDir = [dir.files objectForKey:key];
   if (![subDir isKindOfClass:[ResourcesProperty class]]) {
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
   for (Property *dirFile  in [dir.files allValues]) {
   if (![dirFile isKindOfClass:[ImageProperty class]]) {
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
   [definition appendFormat:@"  R = [[%@ alloc] init];\n", className];
   [definition appendFormat:@"}\n"];
   [definition appendFormat:@"\n"];
   }
   
   [definition appendFormat:@"- (id)init {\n"];
   [definition appendFormat:@" self = [super init];\n"];
   
   for (id key in [dir.files keysSortedByValueUsingComparator:filesSortBlock]) {
   ResourcesProperty *subDir = [dir.files objectForKey:key];
   if (![subDir isKindOfClass:[ImageProperty class]]) {
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
   ResourcesProperty *subDir = [dir.files objectForKey:key];
   if (![subDir isKindOfClass:[ResourcesProperty class]]) {
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
   ResourcesProperty *subDir = [dir.files objectForKey:key];
   if (![subDir isKindOfClass:[ResourcesProperty class]]) {
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
   */
  
}

- (void)dealloc {
  self.pbxProjPath = nil;
  self.root = nil;
  [super dealloc];
}

@end

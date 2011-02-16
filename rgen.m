#import <Foundation/Foundation.h>



@interface ResourcesImages : NSObject
@property(nonatomic, readonly) id bla;
@end
@implementation ResourcesImages
@synthesize bla;
@end

@interface ResourcesRoot : NSObject
@property(nonatomic, readonly) ResourcesImages *images;
@end
@implementation ResourcesRoot
@synthesize images;
- (id)init {
  self = [super init];
  self->images = [[ResourcesImages alloc] init];
  return self;
}
@end

ResourcesRoot *R;


@interface Paths : NSObject {
@private
  NSString *name;
}
- (id)initWithName:(NSString *)aName;
@end

@implementation Paths

- (id)initWithName:(NSString *)aName {
  self = [super init];
  self->name = [aName copy];
  return self;
}

- (void)dealloc {
  [self->name release];
  [super dealloc];
}

- (NSString *)description {
  return [[self->name retain] autorelease];
}

@end



// adapted from http://stackoverflow.com/questions/1918972
@interface NSString (toCamelCase)
- (NSString *)toCamelCase:(NSCharacterSet *)charSet;
@end
@implementation NSString (toCamelCase)
- (NSString *)toCamelCase:(NSCharacterSet *)charSet {
  NSMutableString *output = [NSMutableString string];
  BOOL makeNextCharacterUpperCase = NO;
  for (NSInteger idx = 0; idx < [self length]; idx += 1) {
    unichar c = [self characterAtIndex:idx];
    if ([charSet characterIsMember:c]) {
      makeNextCharacterUpperCase = YES;
    } else if (makeNextCharacterUpperCase) {
      [output appendString:[[NSString stringWithCharacters:&c length:1]
			    uppercaseString]];
      makeNextCharacterUpperCase = NO;
    } else {
      [output appendString:[[NSString stringWithCharacters:&c length:1]
			    lowercaseString]];
    }
  }
  return output;
}
@end


@interface NSString (stripSuffix)
- (NSString *)stripSuffix:(NSArray *)suffixes;
@end
@implementation NSString (stripSuffix)
- (NSString *)stripSuffix:(NSArray *)suffixes {
  for (NSString *suffix in suffixes) {
    if ([self hasSuffix:suffix]) {
      return [self substringToIndex:[self length] - [suffix length]];
    }
  }
  
  return self;
}
@end


@class PBXProj;

@interface PBXProjDictionary : NSObject
@property(nonatomic, retain) PBXProj *pbxProj;
@property(nonatomic, retain) NSDictionary *rootObject;

- (id)initWithRoot:(NSDictionary *)aRootObject
	   PBXProj:(PBXProj *)aPBXProj;
- (PBXProjDictionary *)dictForKey:(NSString *)key;
- (NSArray *)arrayForKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;
@end

@interface PBXProj : NSObject
@property(nonatomic, retain) NSString *pbxFilePath;
@property(nonatomic, retain) NSDictionary *objects;
@property(nonatomic, retain) PBXProjDictionary *rootDictionary;

- (id)initWithProjectFile:(NSString *)path;
- (NSString *)absolutePath:(NSString *)path
		sourceTree:(NSString *)sourceTree;
@end

@implementation PBXProjDictionary

@synthesize pbxProj;
@synthesize rootObject;

- (id)initWithRoot:(NSDictionary *)aRootObject
	   PBXProj:(PBXProj *)aPBXProj {
  self = [super init];
  self.rootObject = aRootObject;
  self.pbxProj = aPBXProj;
  return self;
}

- (PBXProjDictionary *)dictForKey:(NSString *)key {
  return [[[PBXProjDictionary alloc]
	   initWithRoot:[self.pbxProj.objects objectForKey:
			 [self.rootObject objectForKey:key]]
	   PBXProj:self.pbxProj]
	  autorelease];
}

- (NSArray *)arrayForKey:(NSString *)key {
  NSMutableArray *pbxProjObjects = [NSMutableArray array];
  
  for (NSString *objectId in [self.rootObject objectForKey:key]) {
    [pbxProjObjects addObject:
     [[[PBXProjDictionary alloc]
       initWithRoot:[self.pbxProj.objects objectForKey:objectId]
       PBXProj:self.pbxProj]
      autorelease]];
  }
  
  return pbxProjObjects;
}

- (id)objectForKey:(NSString *)key {
  return [self.rootObject objectForKey:key];
}

- (void)dealloc {
  self.pbxProj = nil;
  self.rootObject = nil;
  
  [super dealloc];
}

@end

@implementation PBXProj

@synthesize pbxFilePath;
@synthesize objects;
@synthesize rootDictionary;

- (NSString *)absolutePath:(NSString *)path
		sourceTree:(NSString *)sourceTree {
  NSString *sourceRoot = [[self.pbxFilePath stringByDeletingLastPathComponent]
			  stringByDeletingLastPathComponent];
  
  // TODO: fix saner values for DEVELOPER_DIR, BUILT_PRODUCTS_DIR and SDKROOT
  // not sure if SOURCE_ROOT is always parent to .xcode dir
  NSDictionary *trees = [NSDictionary dictionaryWithObjectsAndKeys:
			 sourceRoot, @"<group>",
			 sourceRoot, @"SOURCE_ROOT",
			 @"/", @"<absolute>",			 
			 [sourceRoot stringByAppendingString:@"build/dummy"], @"BUILT_PRODUCTS_DIR",
			 @"/Developer", @"DEVELOPER_DIR" ,
			 @"/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/dummy", @"SDKROOT",
			 nil];
  
  return [[NSString pathWithComponents:
	   [NSArray arrayWithObjects:[trees objectForKey:sourceTree], path, nil]]
	  stringByStandardizingPath];
}

- (id)initWithProjectFile:(NSString *)path {
  self = [super init];
  
  NSDictionary *project = [NSDictionary dictionaryWithContentsOfFile:path];
  
  self.pbxFilePath = path;
  self.objects = [project objectForKey:@"objects"];
  self.rootDictionary = [[[PBXProjDictionary alloc]
			  initWithRoot:[self.objects objectForKey:
					[project objectForKey:@"rootObject"]]
			  PBXProj:self]
			 autorelease];
  return self;
}

- (void)dealloc {
  self.pbxFilePath = nil;
  self.objects = nil;
  self.rootDictionary = nil;
  
  [super dealloc];
}

@end


@interface File : NSObject
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *path;
@end

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


@interface Dir : NSObject
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSMutableDictionary *files;
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



@interface ResourcesGenerator : NSObject
@property(nonatomic, retain) Dir *rootDir;

- (void)loadResources:(PBXProj *)pbxProj;
- (void)writeResouces:(NSString *)path;

@end

@implementation ResourcesGenerator

@synthesize rootDir;

- (id)initWithProjectFile:(NSString *)aPath {
  self = [super init];
  self.rootDir = [[[Dir alloc] initWithName:@""] autorelease];
  
  [self loadResources:[[[PBXProj alloc] initWithProjectFile:aPath]
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



//  stripSuffix:[NSArray arrayWithObjects:@"@2x", @"-ipad", nil]];
//  toCamelCase:[NSCharacterSet characterSetWithCharactersInString:@"._-"]

- (void)writeResouces:(NSString *)path
		  dir:(Dir *)dir
	dirComponents:(NSArray *)dirComponents {
  
  for (id obj in [dir.files allValues]) {
    NSString *subdir = @"";
    if ([dirComponents count] > 0) {
      subdir = [[NSString pathWithComponents:dirComponents]
		stringByAppendingString:@"/"];
    }
    
    if ([obj isKindOfClass:[Dir class]]) {
      Dir *subDir = obj;
      NSLog(@"dir %@%@", subdir, subDir.name);
      [self writeResouces:path dir:subDir dirComponents:[dirComponents arrayByAddingObject:subDir.name]];
    } else {
      File *file = obj;
      NSLog(@"file %@%@", subdir, file.name);
    }
  }
}

- (void)writeResouces:(NSString *)path {
  NSMutableString *header = [NSMutableString string];
  
  [header appendFormat:@"#import <Foundation/Foundation.h>\n\n"];
  
  
  [self rescurseResoucesWithBlock:^(NSArray *dirComponents, id file) {
    if (![file isKindOfClass:[Dir class]]) {
      return;
    }
    [header appendFormat:@"@class Resources%@;\n",
     [dirComponents componentsJoinedByString:@""]];
  }];
  
  [self rescurseResoucesWithBlock:^(NSArray *dirComponents, id file) {
    if (![file isKindOfClass:[Dir class]]) {
      return;
    }
    Dir *dir = file;
    [header appendFormat:@"@interface Resources%@ : NSObject\n",
     [dirComponents componentsJoinedByString:@""]];
    
    
    for (File *dirFile in [dir.files allValues]) {
      if (![dirFile isKindOfClass:[Dir class]]) {
	continue;
      }
      
      [header appendFormat:@"@property(nonatomic, readonly) Resources%@%@ *%@;\n",
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
  
  [header appendFormat:
   @"@interface Resources (loadResources)\n"
   @"- (void)loadResources;\n"
   @"@end\n"];
  
  
  NSMutableString *definition = [NSMutableString string];
  
  [definition appendFormat:@"#import \"test.h\"\n\n"];
  
  [self rescurseResoucesWithBlock:^(NSArray *dirComponents, id file) {
    if (![file isKindOfClass:[Dir class]]) {
      return;
    }
    Dir *dir = file;
    [definition appendFormat:@"@implementation Resources%@\n",
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
  
  [definition appendFormat:@"Resources *R;\n"];
  
  [definition appendFormat:
   @"@implementation Resources (loadResources)\n"
   @"- (void)loadResources {\n"
   @"  \n"
   @"}\n"
   @"@end\n"
   ];
  
  [header writeToFile:@"test.h"
	   atomically:YES
	     encoding:NSUTF8StringEncoding
		error:NULL];
  
  [definition writeToFile:@"test.m"
	       atomically:YES
		 encoding:NSUTF8StringEncoding
		    error:NULL];
}

- (void)dealloc {
  self.rootDir = nil;
  [super dealloc];
}

@end


int main (int argc, const char * argv[]) {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  
  //NSString *path = @"/Users/mattias/src/rgen/testproj/Testproj/Testproj.xcodeproj/project.pbxproj";
  NSString *path = @"/Users/mattias/src/slippy/Slippy.xcodeproj/project.pbxproj";
  
  ResourcesGenerator *gen = [[[ResourcesGenerator alloc] initWithProjectFile:path] autorelease];
  [gen writeResouces:@""];
  
  
  [pool drain];
  return 0;
}

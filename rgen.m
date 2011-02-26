// TODO:
// Paths P
// image types (from project file?)
// comment outputcode (path refrences etc)
// sanetize/normalize variable names
// run script varaibles.. target?
// exit with error on conflicts?
// paths, add smart ones?
// generate h/m per target (argument?)
// var starts with char
// double loadImages?
// generated from, relative path (so its not changed against scm)
// 
// RGEN=/Users/mattias/src/rgen/build/Debug/rgen
// if which $RGEN > /dev/null; then
//   $RGEN $PROJECT_FILE_PATH $SRCROOT/Classes/Resources
// fi
//
// DONE rgen .. ... || true
// DONE recursive loadImages
// DONE output filename
// DONE sorted output, makes diffs nicer
// NOPE preLoadImages (via path?)
// NOPE $(SRCROOT)/Classes/Resources.h/m $(PROJECT_FILE_PATH) (does not work with updated folders)
// NOPE depend on projectfile mtime?

#import <Foundation/Foundation.h>
#import "ResourcesGenerator.h"

int main (int argc, const char * argv[]) {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  
  if (argc < 2) {
    printf("Usage: %s xcodeproject [Resources] [Target name]\n", argv[0]);
    return EXIT_FAILURE;
  }
  
  NSString *path = [NSString stringWithCString:argv[1]
				      encoding:NSUTF8StringEncoding];
  BOOL isDir = NO;
  if ([[NSFileManager defaultManager]
       fileExistsAtPath:path isDirectory:&isDir] && isDir) {
    path = [path stringByAppendingPathComponent:@"project.pbxproj"];
  }
  
  NSString *outputDir = @".";
  NSString *className = @"Resources";
  if (argc > 2) {
    NSString *outputBase = [NSString stringWithCString:argv[2]
					      encoding:NSUTF8StringEncoding];
    className = [outputBase lastPathComponent];
    outputDir = [outputBase stringByDeletingLastPathComponent];
  }
  
  NSString *targetName = nil;
  if (argc > 3) {
    targetName = [NSString stringWithCString:argv[3]
				    encoding:NSUTF8StringEncoding];
  }
  
  ResourcesGenerator *gen = [[[ResourcesGenerator alloc]
			      initWithProjectFile:path]
			     autorelease];
  [gen writeResoucesTo:outputDir
	     className:className
	     forTarget:targetName];
  
  [pool drain];
  
  return EXIT_SUCCESS;
}

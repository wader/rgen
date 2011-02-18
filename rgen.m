// TODO:
// sorted output, makes diffs nicer
// Paths P
// image types (from project file?)
// comment outputcode (path refrences etc)
// sanetize/normalize variable names
// run script varaibles.. target?
// preLoadImages (via path?)
// /Users/mattias/src/rgen/build/Debug/rgen $PROJECT_FILE_PATH $SRCROOT/Classes/Resources
// exit with error on conflicts?
// paths, add smart ones?
// generate h/m per target
// var starts with char
//
// DONE output filename
// NOPE $(SRCROOT)/Classes/Resources.h/m $(PROJECT_FILE_PATH) (does not work with updated folders)
// NOPE depend on projectfile mtime?

#import <Foundation/Foundation.h>
#import "ResourcesGenerator.h"

int main (int argc, const char * argv[]) {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  
  if (argc < 2) {
    printf("Usage: %s xcodeproject [Resources]\n", argv[0]);
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
  
  ResourcesGenerator *gen = [[[ResourcesGenerator alloc]
			      initWithProjectFile:path]
			     autorelease];
  [gen writeResoucesTo:outputDir className:className];
  
  [pool drain];
  
  return EXIT_SUCCESS;
}

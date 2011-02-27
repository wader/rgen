// TODO:
// Paths P (stinrg or url?)
// image types (from project file?)
// run script varaibles.. target?
// exit with error on conflicts?
// paths, add smart ones?
// -ipad, own loader?
// double loadImages?
// class name collisions
// verbose log
// move recurse etc to own class
// move prune to own class too
// error checks
// try rebase history
// NSImage, OSXify
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
// DONE generate h/m per target (argument?)
// DONE var starts with char
// DONE generated from, relative path (so its not changed against scm)
// DONE comment outputcode (path refrences etc)
// DONE sanetize/normalize variable names


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
  
  @try {
    ResourcesGenerator *gen = [[[ResourcesGenerator alloc]
				initWithProjectFile:path]
			       autorelease];
    [gen writeResoucesTo:outputDir
	       className:className
	       forTarget:targetName];
  }
  @catch (ResourcesGeneratorException * e) {
    fprintf(stderr, "%s: %s\n",
	    argv[0],
	    [[e reason] cStringUsingEncoding:NSUTF8StringEncoding]);
    return EXIT_FAILURE;
  }
  
  [pool drain];
  
  return EXIT_SUCCESS;
}

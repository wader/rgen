// TODO:
// Paths P (stinrg or url?)
// image types (from project file?)
// paths, add smart ones?
// double loadImages?
// class name collisions
// verbose log, vert verbose log?
// try rebase history
// NSImage, OSXify
// DONE P optional?
// refactor Paths code, smart generated code
// lproj, keys? PBXVariantGroup and via file refs
// user xcode settgin RGEN variable? shared project file
// xcode error/warning file:line: warning|error: blabla
// skip init for leaf classes
// fake suffix stripped path for paths
// @ipad image load method
// custome source tress (~/Library/Preferences/com.apple.Xcode.plist)
// target nil, error?
// 
// RGEN=/Users/mattias/src/rgen/build/Debug/rgen
// if which $RGEN > /dev/null; then
//   $RGEN $PROJECT_FILE_PATH $SRCROOT/Classes/Resources
// fi
//
// DONE generate less code : ? and stuff?
// DONE exit with error on conflicts?
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
// DONE move recurse etc to own class
// DONE move prune to own class too
// DONE error checks
// NOPE run script varaibles.. target? one run script per target anyway

#import <Foundation/Foundation.h>
#import "ResourcesGenerator.h"

#include <getopt.h>

BOOL verbose = NO;

void trace(NSString *format, ...) {
  if (!verbose) {
    return;
  }
  
  va_list va;
  va_start(va, format);
  fprintf(stdout, "%s\n",
	  [[[[NSString alloc] initWithFormat:format arguments:va]
	    autorelease]
	   cStringUsingEncoding:NSUTF8StringEncoding]);
  va_end(va);
}

int main(int argc,  char *const argv[]) {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  char *argv0 = argv[0];
  BOOL generateImages = NO;
  BOOL generatePaths = NO;
  BOOL generateLoadImages = NO;
  BOOL ipadImageSuffx = NO;
  BOOL ipad2xImageSuffx = NO;
  
  static struct option longopts[] = {
    {"images", no_argument, NULL, 'I'},
    {"paths", no_argument, NULL, 'P'},
    {"loadimages", no_argument, NULL, 1},
    {"ipad", no_argument, NULL, 2},
    {"ipad2x", no_argument, NULL, 3},
    {"verbose", no_argument, NULL, 'v'},
    {NULL, 0, NULL, 0}
  };
  
  int c;
  while ((c = getopt_long(argc, argv, "vIP", longopts, NULL)) != -1) {
    switch (c) {
      case 'v':
	verbose = YES;
	break;
      case 'I':
	generateImages = YES;
	break;
      case 'P':
	generatePaths = YES;
	break;
      case 1:
	generateLoadImages = YES;
	break;
      case 2:
	ipadImageSuffx = YES;
	break;
      case 3:
	ipad2xImageSuffx = YES;
	break;
      case '?':
      default:
	break;
    }
  }
  argc -= optind;
  argv += optind;
  
  if (argc < 1) {
    printf("Usage: %s [-vIP] xcodeproject [Output path] [Target name]\n"
	   "  -I, --images     Generate I images property tree\n"
	   "  -P, --paths      Generate P paths property tree\n"
	   "  --loadimages     Generate loadImages/releaseImages methods\n"
	   "  --ipad           Support @ipad image name scale suffix\n"
	   "  --ipad2x         Support @2x as 1.0 scale image on iPad\n"
	   "  -v, --verbose    Verbose output\n"
	   "",
	   argv0);
    return EXIT_FAILURE;
  }
  
  if (!(generateImages || generatePaths)) {
    fprintf(stderr, "error: Please specify at least -I or -P\n");
    return EXIT_FAILURE;
  }
  
  NSString *path = [NSString stringWithCString:argv[0]
				      encoding:NSUTF8StringEncoding];
  NSString *outputDir = @".";
  NSString *className = @"Resources";
  if (argc > 1) {
    NSString *outputBase = [NSString stringWithCString:argv[1]
					      encoding:NSUTF8StringEncoding];
    className = [outputBase lastPathComponent];
    outputDir = [outputBase stringByDeletingLastPathComponent];
  }
  
  NSString *targetName = nil;
  if (argc > 2) {
    targetName = [NSString stringWithCString:argv[2]
				    encoding:NSUTF8StringEncoding];
  }
  
  @try {
    ResourcesGenerator *gen = [[[ResourcesGenerator alloc]
				initWithProjectFile:path]
			       autorelease];
    gen.optionGenerateImages = generateImages;
    gen.optionGeneratePaths = generatePaths;
    gen.optionLoadImages = generateLoadImages;
    gen.optionIpadImageSuffx = ipadImageSuffx;
    gen.optionIpad2xImageSuffx = ipad2xImageSuffx;
    [gen writeResoucesTo:outputDir
	       className:className
	       forTarget:targetName];
  } @catch (ResourcesGeneratorException *e) {
    fprintf(stderr, "error: %s\n",
	    [[e reason] cStringUsingEncoding:NSUTF8StringEncoding]);
    return EXIT_FAILURE;
  }
  
  [pool drain];
  
  return EXIT_SUCCESS;
}

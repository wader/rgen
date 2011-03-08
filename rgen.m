/*
 * rgen - A resource code generator for iOS
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
  while ((c = getopt_long(argc, argv, "IPv", longopts, NULL)) != -1) {
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
    printf("Usage: %s [-IPv] xcodeproject [Output path] [Target name]\n"
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

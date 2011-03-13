# rgen

Resource code generator for iOS development inspired by the resource handling for Android.

<code>rgen</code> makes it possible to:

Load images like this

	imageView.image = I.images.cuteSeal;

instead of this

	imageView.image = [UIImage imageNamed:@"images/cute-seal.png"];

Specify resource paths to files and directories like this

	[NSDictionary dictionaryWithContentsOfFile:P.files.dogsPlist];

instead of this

	[NSDictionary dictionaryWithContentsOfFile:
	 [[[NSBundle mainBundle] resourcePath]
	  stringByAppendingPathComponent:@"files/dogs.plist"]];

And get localization string keys like this

	NSLocalizedString(S.cats, nil)

instead of this

	NSLocalizedString(@"cats", nil)

This is very nice for several reasons

*  Less error-prone as you get compile time errors for missing images,
   files and string keys.
*  Code completion
*  Less and nicer looking code

## Install

Compile from source:

	$ git clone git://github.com/wader/rgen.git
	$ cd rgen
	$ xcodebuild
	$ cp build/Release/rgen /to/somewhere

If don't want to compile there is a binary for download compiled for i386
and Mac OS X 10.6.

## Usage

	Usage: ./rgen [-IPSv] xcodeproject [Output path] [Target name]
	  -I, --images      Generate I images property tree
	  -P, --paths       Generate P paths property tree
	  -S, --stringkeys  Generate S localizable string keys class
	  --loadimages      Generate loadImages/releaseImages methods
	  --ipad            Support @ipad image name scale suffix
	  --ipad2x          Support @2x as 1.0 scale image on iPad
	  -v, --verbose     Verbose output

### Features

If no <code>Output path</code> is specified code will be generated to
<code>Resources.m</code> and <code>Resources.h</code> in the current dirctory.

If no <code>Target name</code> is specified <code>rgen</code> will merge
resources for all targets.

<code>-I</code>, <code>-P</code> and <code>-S</code> enables code generation for
the different resources. At least one must be enabled.

<code>--imageimages</code> generates two methods <code>loadImages</code> and
<code>releaseImages</code> for each image directory. <code>loadimages</code>
can be used to load and retin all images in a dirctory and below.
<code>releaseImages</code> does the opposite by releasing them.

<code>--ipad</code> generates image loading code that will extend the normal
<code>@2x</code> suffix to also load <code>@ipad</code> images if found on
iPad devices.

<code>--ipad2x</code> generates image loading code that loads <code>@2x</code>
images as scale 1.0 images on iPad devices. If <code>--ipad</code> is enabled
a <code>@ipad</code> image has priority.

<code>-v</code> enables verbose logging to see what rgen does.

### Xcode build run script

Add a "New run script build phase" to your target. The run script should look
something like the one below. <code>which</code> is used to make sure a user can
build without <code>rgen</code> is installed.
<code>$PROJECT_FILE_PATH</code> and <code>$SRCROOT</code> will be assigned
by Xcode.

	RGEN=/path/to/rgen
	which -s $RGEN && $RGEN -IPS $PROJECT_FILE_PATH $SRCROOT/Classes/Resources

Now build the target and two new files, in this case
<code>Classes/Resources.m</code> and <code>Classes/Resources.h</code> will be
created. Add these as source files to your project and then import
<code>Resources.h</code> where you want access to the resouces classes.
Then and your good to go!

To make thing even smoother you can add a <code>#import "Resources.h"</code> line
to your <code>*_Prefix.pch</code> file. <code>rgen</code> makes sure not to touch
the generated files if nothing has changed since last run to not trigger
unnecessary rebuilds.

### Run from terminal

Should work fine as long as your project does not have weird source trees paths.
rgen uses various exported environment variables when running in a build script
but can fallback to guessing paths based on project path.

Example:
<code>rgen -IPS path/to/app.xcodeproj path/to/Classes/ResourcesTargetA TargetA</code>

Will generate files <code>path/to/Classes/ResourcesTargetA.m</code> and
<code>path/to/Classes/ResourcesTargetA.h</code> with images, paths and string
keys found for target <code>TargetA</code>

## Known issues and TODOs

*  Support custome source tree paths
*  Support Mac OS X applications. Autodetect via SDK (iphoneos/macosx) and
   generate NSImage code etc
*  Read other .strings files then just Localizable.strings
*  Detect class name collisions
*  Support document paths somehow. Specify list of known paths etc
*  Rebuild dependencies seams to be calculated before starting build
   so you might need to build twice to use updated resources files
*  Xcode plugin?
*  RGEN path as user setting for shared project files. Make sure rgen is in path or
use .xcconfig files? 
*  Document multi target setup. Generate different resources files per target,
   use define and #ifdef import


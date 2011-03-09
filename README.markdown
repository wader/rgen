# rgen
Resource code generator for iOS inspired by Android resource handling.

<code>rgen</code> makes it possible to:

Load images like this

	imageView.image = I.images.cuteSeal;

instead of this

	imageView.image = [UIImage imageNamed:@"images/cute-seal.png"];

Specify resource paths (even directory paths!) like this

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
can be used to preload all images in a dirctory and below.
<code>releaseImages</code> does the opposite.

<code>--ipad</code> generates image loading code that will extend the normal
<code>@2x</code> suffix to also load <code>@ipad</code> images if found on
iPad devices.

<code>--ipad2x</code> generates image loading code that loads <code>@2x</code>
images as scale 1.0 images on iPad devices. If <code>--ipad</code> is enabled
a <code>@ipad</code> image has priority.

<code>-v</code> enables verbose logging to see what rgen does.

### Xcode build run script

Add a "New run script build phase" with a script like this. <code>which</code> is used
to make sure a user can build without rgen is installed.

	RGEN=/path/to/rgen
	which -s $RGEN && $RGEN -IPS $PROJECT_FILE_PATH $SRCROOT/Classes/Resources

Place the new "Run Script" phase dirctly after the "Copy Bundle Resources" phase
for best result.

Now build and two new files <code>Classes/Resources.m</code> and
<code>Classes/Resources.h</code> are created. Add these as existing files
to your project and your done. 

To make thing even smoother you can add <code>#import "Resources.h"</code> to
your <code>_Prefix.pch</code> file. rgen makes sure to not touch the generated
files is no changes has happend since last run to not trigger unnecessary
rebuilds.

### Manual run from terminal

Should work fine as long as your project does not have weird paths. rgen uses
various exported environment variables when running as a build script but
fallbacks to guessing paths based on project path if not found.

Example:
<code>rgen -IPS path/to/app.xcodeproj path/to/Classes/ResourcesTargetA TargetA</code>

Will generate files <code>path/to/Classes/ResourcesTargetA.m</code> and
<code>path/to/Classes/ResourcesTargetA.h</code> with images, paths and string
keys found for target <code>TargetA</code>

## Known issues and TODOs

*  Strings key collection does not filter on target name
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


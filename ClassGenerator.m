
#import "ClassGenerator.h"

@implementation ClassGenerator

@synthesize className;
@synthesize inheritClassName;
@synthesize variables;
@synthesize properties;
@synthesize declarations;
@synthesize synthesizes;
@synthesize implementations;

- (id)initWithClassName:(NSString *)aClassName
	    inheritName:(NSString *)aInheritClassName {
  self = [super init];
  self.className = aClassName;
  self.inheritClassName = aInheritClassName;
  self.variables = [NSMutableArray array];
  self.properties = [NSMutableArray array];
  self.declarations = [NSMutableArray array];
  self.synthesizes = [NSMutableArray array];
  self.implementations = [NSMutableArray array];
  return self;
}

- (NSString *)generateHeader {
  NSMutableString *source = [NSMutableString string];
  
  [source appendFormat:
   @"@interface %@ : %@ {\n",
   self.className,
   self.inheritClassName];
  [source appendString:[self.variables componentsJoinedByString:@"\n"]];
  [source appendString:@"\n"];
  [source appendString:@"}\n"];
  [source appendString:@"\n"];
  [source appendString:[self.properties componentsJoinedByString:@"\n"]];
  [source appendString:@"\n"];
  [source appendString:[self.declarations componentsJoinedByString:@"\n"]];
  [source appendString:@"\n"];
  [source appendString:@"@end\n"];
  
  return source;
}

- (NSString *)generateImplementation {
  NSMutableString *source = [NSMutableString string];
  
  [source appendFormat:@"@implementation %@\n", self.className];
  [source appendString:[self.synthesizes componentsJoinedByString:@"\n"]];
  [source appendString:@"\n"];
  [source appendString:@"\n"];
  [source appendString:[self.implementations componentsJoinedByString:@"\n"]];
  [source appendString:@"\n"];
  [source appendString:@"@end\n"];
  
  return source;
}

- (void)dealloc {
  self.className = nil;
  self.inheritClassName = nil;
  self.variables = nil;
  self.properties = nil;
  self.declarations = nil;
  self.synthesizes = nil;
  self.implementations = nil;
  [super dealloc];
}

@end
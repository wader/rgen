
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

- (void)appendString:(NSMutableString *)string
	       lines:(NSArray *)lines {
  if ([lines count] == 0) {
    return;
  }
  
  [string appendString:[lines componentsJoinedByString:@"\n"]];
  [string appendString:@"\n"];
}

- (NSString *)generateHeader {
  NSMutableString *source = [NSMutableString string];
  
  [source appendFormat:
   @"@interface %@ : %@ {\n",
   self.className,
   self.inheritClassName];
  [self appendString:source lines:self.variables];
  [source appendString:@"}\n"];
  [source appendString:@"\n"];
  [self appendString:source lines:self.properties];
  [source appendString:@"\n"];
  [self appendString:source lines:self.declarations];
  [source appendString:@"@end\n"];
  
  return source;
}

- (NSString *)generateImplementation {
  NSMutableString *source = [NSMutableString string];
  
  [source appendFormat:@"@implementation %@\n", self.className];
  [self appendString:source lines:self.synthesizes];
  [source appendString:@"\n"];
  [self appendString:source lines:self.implementations];
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
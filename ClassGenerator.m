/*
 * ClassGenerator.m, helper class for collecting stuff and generating code
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

#import "ClassGenerator.h"

static NSString *const oneIndent = @"  ";

@implementation IndentLine
@synthesize indent;
@synthesize text;

- (void)dealloc {
  self.text = nil;
  [super dealloc];
}

@end

@implementation IndentedLines
@synthesize indentedLines;

- (id)init {
  self = [super init];
  if (self == nil) {
    return nil;
  }
  
  self.indentedLines = [NSMutableArray array];
  
  return self;
}

- (NSString *)description {
  NSMutableString *s = [NSMutableString string];
  
  for (IndentLine *line in self.indentedLines) {
    for (int i = 0; i < line.indent ; i++) {
      [s appendString:oneIndent];
    }
    [s appendString:line.text];
    [s appendString:@"\n"];
  }
  
  return s;
}

- (void)dealloc {
  self.indentedLines = nil;
  
  [super dealloc];
}

@end

@implementation ClassMethod
@synthesize signature;
@synthesize lines;

- (id)initWithSignature:(NSString *)aSignature {
  self = [super init];
  if (self == nil) {
    return nil;
  }
  
  self.signature = aSignature;
  self.lines = [[[IndentedLines alloc] init] autorelease];
  
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:
	  @"%@ {\n"
	  @"%@"
	  @"}\n",
	  self.signature,
	  self.lines];
}

- (void)addLineIndent:(NSUInteger)aIndent format:(NSString *)format, ... {
  IndentLine *line = [[[IndentLine alloc] init] autorelease];
  line.indent = aIndent;
  va_list va;
  va_start(va, format);
  line.text = [[[NSString alloc] initWithFormat:format arguments:va]
	       autorelease];
  va_end(va);
  [self.lines.indentedLines addObject:line];
}

- (void)dealloc {
  self.signature = nil;
  self.lines = nil;
  
  [super dealloc];
}

@end


@implementation ClassGenerator

@synthesize className;
@synthesize inheritClassName;
@synthesize variables;
@synthesize properties;
@synthesize declarations;
@synthesize synthesizes;
@synthesize methods;

- (id)initWithClassName:(NSString *)aClassName
	    inheritName:(NSString *)aInheritClassName {
  self = [super init];
  if (self == nil) {
    return nil;
  }
  
  self.className = aClassName;
  self.inheritClassName = aInheritClassName;
  self.variables = [NSMutableDictionary dictionary];
  self.properties = [NSMutableDictionary dictionary];
  self.declarations = [NSMutableDictionary dictionary];
  self.synthesizes = [NSMutableDictionary dictionary];
  self.methods = [NSMutableDictionary dictionary];
  
  return self;
}

- (void)addVariableName:(NSString *)aName
		   line:(NSString *)aFormatLine, ... {
  va_list va;
  va_start(va, aFormatLine);
  [self.variables setObject:[[[NSString alloc]
			      initWithFormat:aFormatLine
			      arguments:va]
			     autorelease]
		     forKey:aName];
  va_end(va);
}

- (void)addPropertyName:(NSString *)aName
		   line:(NSString *)aFormatLine, ... {
  va_list va;
  va_start(va, aFormatLine);
  [self.properties setObject:[[[NSString alloc]
			       initWithFormat:aFormatLine
			       arguments:va]
			      autorelease]
		      forKey:aName];
  va_end(va);
}

- (void)addDeclarationName:(NSString *)aName
		      line:(NSString *)aFormatLine, ... {
  va_list va;
  va_start(va, aFormatLine);
  [self.declarations setObject:[[[NSString alloc]
				 initWithFormat:aFormatLine
				 arguments:va]
				autorelease]
			forKey:aName];
  va_end(va);
}

- (void)addSynthesizerName:(NSString *)aName
		      line:(NSString *)aFormatLine, ... {
  va_list va;
  va_start(va, aFormatLine);
  [self.synthesizes setObject:[[[NSString alloc]
				initWithFormat:aFormatLine
				arguments:va]
			       autorelease]
		       forKey:aName];
  va_end(va);
}

- (ClassMethod *)addMethodName:(NSString *)aName
		   declaration:(BOOL)declaration
		     signature:(NSString *)aFormatSignature, ... {
  va_list va;
  va_start(va, aFormatSignature);
  NSString *signature = [[[NSString alloc]
			  initWithFormat:aFormatSignature
			  arguments:va]
			 autorelease];
  va_end(va);
  
  ClassMethod *method = [[[ClassMethod alloc] initWithSignature:signature]
			 autorelease];
  [self.methods setObject:method forKey:aName];
  
  if (declaration) {
    [self.declarations setObject:signature forKey:aName];
  }
  
  return method;
}

- (NSString *)header {
  NSMutableString *s = [NSMutableString string];
  
  [s appendFormat:@"@interface %@ : %@",
   self.className, self.inheritClassName];
  
  if ([self.variables count] > 0) {
    [s appendString:@" {\n"];
    for(id key in [[self.variables allKeys]
		   sortedArrayUsingSelector:@selector(compare:)]) {
      NSString *line = [self.variables objectForKey:key];
      [s appendFormat:@"%@%@\n", oneIndent, line];
    }
    [s appendString:@"}\n"];
  }
  [s appendString:@"\n"];
  
  if ([self.properties count] > 0) {
    for(id key in [[self.properties allKeys]
		   sortedArrayUsingSelector:@selector(compare:)]) {
      NSString *line = [self.properties objectForKey:key];
      [s appendFormat:@"%@\n", line];
    }
    [s appendString:@"\n"];
  }
  
  if ([self.declarations count] > 0) {
    for(id key in [[self.declarations allKeys]
		   sortedArrayUsingSelector:@selector(compare:)]) {
      NSString *line = [self.declarations objectForKey:key];
      [s appendFormat:@"%@;\n", line];
    }
    [s appendString:@"\n"];
  }
  
  [s appendString:@"@end\n"];
  
  return s;
}

- (NSString *)implementation {
  NSMutableString *s = [NSMutableString string];
  
  [s appendFormat:@"@implementation %@\n", self.className];
  
  if ([self.synthesizes count] > 0) {
    for(id key in [[self.synthesizes allKeys]
		   sortedArrayUsingSelector:@selector(compare:)]) {
      NSString *line = [self.synthesizes objectForKey:key];
      [s appendFormat:@"%@\n", line];
    }
    [s appendString:@"\n"];
  }
  
  if ([self.methods count] > 0) {
    for(id key in [[self.methods allKeys]
		   sortedArrayUsingSelector:@selector(compare:)]) {
      ClassMethod *method = [self.methods objectForKey:key];
      [s appendFormat:@"%@\n", method];
    }
  }
  
  [s appendString:@"@end\n"];
  
  return s;
}

- (void)dealloc {
  self.className = nil;
  self.inheritClassName = nil;
  self.variables = nil;
  self.properties = nil;
  self.declarations = nil;
  self.synthesizes = nil;
  self.methods = nil;
  
  [super dealloc];
}

@end
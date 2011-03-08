/*
 * ClassGenerator.h, helper class for collecting stuff and generating code
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

@interface IndentLine : NSObject
@property(nonatomic, assign) NSUInteger indent;
@property(nonatomic, retain) NSString *text;
@end

@interface IndentedLines : NSObject
@property(nonatomic, retain) NSMutableArray *indentedLines;
@end

@interface ClassMethod : NSObject
@property(nonatomic, retain) NSString *signature;
@property(nonatomic, retain) IndentedLines *lines;

- (id)initWithSignature:(NSString *)aSignature;
- (void)addLineIndent:(NSUInteger)aIndent format:(NSString *)format, ...;
@end

@interface ClassGenerator : NSObject
@property(nonatomic, retain) NSString *className;
@property(nonatomic, retain) NSString *inheritClassName;
@property(nonatomic, retain) NSMutableDictionary *variables;
@property(nonatomic, retain) NSMutableDictionary *properties;
@property(nonatomic, retain) NSMutableDictionary *declarations;
@property(nonatomic, retain) NSMutableDictionary *synthesizes;
@property(nonatomic, retain) NSMutableDictionary *methods;

- (id)initWithClassName:(NSString *)aClassName
	    inheritName:(NSString *)aInheritClassName;

- (void)addVariableName:(NSString *)aName
		   line:(NSString *)aFormatLine, ...;
- (void)addPropertyName:(NSString *)aName
		   line:(NSString *)aFormatLine, ...;
- (void)addDeclarationName:(NSString *)aName
		      line:(NSString *)aFormatLine, ...;
- (void)addSynthesizerName:(NSString *)aName
		      line:(NSString *)aFormatLine, ...;
- (ClassMethod *)addMethodName:(NSString *)aName
		   declaration:(BOOL)declaration
		     signature:(NSString *)aFormatSignature, ...;

- (NSString *)header;
- (NSString *)implementation;

@end


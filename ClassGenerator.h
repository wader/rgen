//
//  ClassGenerator.h
//  rgen
//
//  Created by Mattias Wadman on 2011-02-25.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

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


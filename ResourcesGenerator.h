//
//  ResourcesGenerator.h
//  rgen
//
//  Created by Mattias Wadman on 2011-02-17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ResourcesGeneratorException : NSException
@end

@interface ResourcesGenerator : NSObject
@property(nonatomic, assign) BOOL optionGenerateImages;
@property(nonatomic, assign) BOOL optionGeneratePaths;
@property(nonatomic, assign) BOOL optionLoadImages;
@property(nonatomic, assign) BOOL optionIpadImageSuffx;
@property(nonatomic, assign) BOOL optionIpad2xImageSuffx;

- (id)initWithProjectFile:(NSString *)aPath;
- (void)writeResoucesTo:(NSString *)outputDir
	      className:(NSString *)className
	      forTarget:(NSString *)targetName;

@end
//
//  MoveFileCommand_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 25.06.14.
//
//

#import <XCTest/XCTest.h>
#import "FileSystemTestCase.h"
#import "MoveFileCommand.h"

@interface MoveFileCommand_Tests : FileSystemTestCase

@end


@implementation MoveFileCommand_Tests

- (void)testMoveFileCommand
{
    [self createFolders:@[
            @"oneplace",
            @"anotherplace"]];

    [self createEmptyFiles:@[@"oneplace/important.txt"]];

    MoveFileCommand *moveFileCommand = [[MoveFileCommand alloc] initWithFromPath:[self fullPathForFile:@"oneplace/important.txt"]
                                                                          toPath:[self fullPathForFile:@"anotherplace/important.txt"]];

    NSError *error;
    XCTAssertTrue([moveFileCommand execute:&error], @"Move file command failed with error: %@", error);
    XCTAssertNil(error);
    XCTAssertTrue(moveFileCommand.successful);

    [self assertFileExists:@"anotherplace/important.txt"];
    [self assertFileDoesNotExists:@"oneplace/important.txt"];
}

- (void)testMoveFileAndUndo
{
    [self createFolders:@[
            @"oneplace",
            @"anotherplace"]];

    [self createEmptyFiles:@[@"oneplace/important.txt"]];

    MoveFileCommand *moveFileCommand = [[MoveFileCommand alloc] initWithFromPath:[self fullPathForFile:@"oneplace/important.txt"]
                                                                          toPath:[self fullPathForFile:@"anotherplace/important.txt"]];

    NSError *error;
    XCTAssertTrue([moveFileCommand execute:&error], @"Move file command failed with error: %@", error);
    XCTAssertTrue([moveFileCommand undo:&error], @"Move file command  UNDO failed with error: %@", error);
    XCTAssertNil(error);
    XCTAssertTrue(moveFileCommand.successful);

    [self assertFileExists:@"oneplace/important.txt"];
    [self assertFileDoesNotExists:@"anotherplace/important.txt"];
}

- (void)testMoveFileFailsNoFile
{
    MoveFileCommand *moveFileCommand = [[MoveFileCommand alloc] initWithFromPath:[self fullPathForFile:@"oneplace/important.txt"]
                                                                           toPath:[self fullPathForFile:@"anotherplace/important.txt"]];

    NSError *error;
    XCTAssertFalse([moveFileCommand execute:&error], @"Move file command succeeded although it shouldn't have.");
    XCTAssertNotNil(error);
    XCTAssertFalse(moveFileCommand.successful);
}

@end
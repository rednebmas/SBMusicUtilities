//
//  SBRandomNoteGeneratorTests.m
//  SBMusicUtilities
//
//  Created by Sam Bender on 12/21/16.
//  Copyright © 2016 Sam Bender. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SBRandomNoteGenerator.h"

@interface SBRandomNoteGeneratorTests : XCTestCase

@end

@implementation SBRandomNoteGeneratorTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. 
}

- (void)tearDown
{
    // Put teardown code here. 
    [super tearDown];
}

- (void)testZeroNoteRange_returnsNote
{
    SBRandomNoteGenerator *ng = [[SBRandomNoteGenerator alloc] init];
    SBNote *c4 = [SBNote noteWithName:@"C4"];
    [ng setRangeFrom:c4 to:c4];
    
    for (int i = 0; i < 15; i++) {
        SBNote *note = [ng nextNote];
        XCTAssert(note != nil && [note.nameWithOctave isEqualToString:@"C4"]);
    }
}

@end

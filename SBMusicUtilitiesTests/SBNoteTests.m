//
//  SBNoteTests.m
//  SBMusicUtilities
//
//  Created by Sam Bender on 11/22/16.
//  Copyright © 2016 Sam Bender. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SBNote.h"

@interface SBNoteTests : XCTestCase

@end

@implementation SBNoteTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testNameToFrequency {
    SBNote *a4 = [SBNote noteWithName:@"A4"];
    XCTAssert(a4.frequency == 440.00);
    
    SBNote *c6 = [SBNote noteWithName:@"C6"];
    XCTAssertEqualWithAccuracy(c6.frequency, 1046.502261, 0.001);
    
    SBNote *c2 = [SBNote noteWithName:@"C2"];
    XCTAssertEqualWithAccuracy(c2.frequency, 65.406391, 0.001);
}

- (void)testDifferenceInCents_adjustNameNo {
    SBNote *a4 = [SBNote noteWithName:@"A4"];
    SBNote *a4_plus100Cents = [a4 noteWithDifferenceInCents:100.00 adjustName:NO];
    XCTAssertEqualWithAccuracy(a4_plus100Cents.frequency, 466.164, .001);
    XCTAssert([a4_plus100Cents.nameWithOctave isEqualToString:@"A4"],
              @"name = %@", a4_plus100Cents.nameWithOctave);
}

- (void)testDifferenceInCents_adjustNameYes {
    SBNote *a4 = [SBNote noteWithName:@"A4"];
    SBNote *a4_plus100Cents = [a4 noteWithDifferenceInCents:100.00 adjustName:YES];
    XCTAssertEqualWithAccuracy(a4_plus100Cents.frequency, 466.164, .001);
    XCTAssert([a4_plus100Cents.nameWithOctave isEqualToString:@"A#4"],
              @"name = %@", a4_plus100Cents.nameWithOctave);
}

- (void)testDifferenceInCents_defaultsToAdjustName {
    SBNote *a4 = [SBNote noteWithName:@"A4"];
    SBNote *a4_plus100Cents = [a4 noteWithDifferenceInCents:100.00 adjustName:YES];
    XCTAssertEqualWithAccuracy(a4_plus100Cents.frequency, 466.164, .001);
    XCTAssert([a4_plus100Cents.nameWithOctave isEqualToString:@"A#4"],
              @"name = %@", a4_plus100Cents.nameWithOctave);
}

@end

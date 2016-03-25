//
//  SBPlayableNote.h
//  Pitch
//
//  Created by Sam Bender on 1/17/16.
//  Copyright © 2016 Sam Bender. All rights reserved.
//

#import "SBNote.h"

@class EZAudioFile;

@interface SBPlayableNote : SBNote

@property (nonatomic) BOOL isPlaying;
@property (nonatomic) int waitFrames;
@property (nonatomic) double positionInSineWave;
@property (nonatomic) NSInteger durationInFramesLeft;
@property (nonatomic, readonly) NSInteger durationInFrames;
@property (nonatomic) double thetaIncrement;
@property (nonatomic, retain) NSDate *toneStart;
@property (nonatomic, retain) EZAudioFile *audioFile;

- (void) loadAudioFile;

@end

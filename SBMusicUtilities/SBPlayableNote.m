//
//  SBPlayableNote.m
//  Pitch
//
//  Created by Sam Bender on 1/17/16.
//  Copyright © 2016 Sam Bender. All rights reserved.
//

#import <EZAudio/EZAudio.h>
#import "SBPlayableNote.h"

#define SAMPLE_RATE 44100.00

@implementation SBPlayableNote

- (id) initWithFrequency:(double)frequency
{
    self = [super initWithFrequency:frequency];
    if (self)
    {
        self.thetaIncrement = 2.0 * M_PI * self.frequency / SAMPLE_RATE;
        [self setDuration:self.duration];
    }
    return self;
}

- (void) loadAudioFile
{
    NSString *filename = [NSString stringWithFormat:@"Piano.ff.%@", self.nameWithOctave];
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"mp3"];
    self.audioFile = [EZAudioFile audioFileWithURL:[NSURL fileURLWithPath:path]];
}

- (void) setDuration:(double)duration
{
    [super setDuration:duration];
    
    _durationInFrames = (NSInteger)(SAMPLE_RATE * self.duration);
    _durationInFramesLeft = _durationInFrames;
}

@end

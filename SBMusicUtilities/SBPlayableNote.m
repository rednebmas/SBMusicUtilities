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

@interface SBPlayableNote()

@property (nonatomic, readwrite) BOOL bufferInitialized;
@property (nonatomic) UInt32 audioBufferListLength;
@property (nonatomic) AudioBufferList *audioBufferList;

@end

@implementation SBPlayableNote

#pragma mark - Init/dealloc

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

- (void) dealloc
{
    if (self.bufferInitialized)
    {
        free(self.audioBufferList);
    }
}

#pragma mark - Misc...

- (void) loadAudioFile
{
    NSString *filename = [NSString stringWithFormat:@"Piano.ff.%@", self.nameWithOctave];
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"mp3"];
    NSLog(@"%@", filename);
    self.audioFile = [EZAudioFile audioFileWithURL:[NSURL fileURLWithPath:path]];
}

- (void) setDuration:(double)duration
{
    [super setDuration:duration];
    
    _durationInFrames = (NSInteger)(SAMPLE_RATE * self.duration);
    _durationInFramesLeft = _durationInFrames;
}

#pragma mark - Audio buffer loading

- (void) initializeAudioBufferListWithChannelsPerFrame:(UInt32)channelsPerFrame
                                           interleaved:(BOOL)interleaved
                                         bytesPerFrame:(UInt32)bytesPerFrame
                                        capacityFrames:(UInt32)capacityFrames
{
    if (self.bufferInitialized) return;
   
    // We need to modify the size of the audio buffer list if we are modifying the pitch of the
    // sample
    self.audioBufferListLength = capacityFrames;
    if (self.centsOff != 0.0 && self.instrumentType != InstrumentTypeSineWave)
    {
        if (self.centsOff != 0.0) NSLog(@"is zero? %.10f", self.centsOff);
        SBNote *inTuneNote = [SBNote noteWithName:self.nameWithOctave];
        double percentCompression = [self percentCompressionFromFreq:self.frequency
                                                              toFreq:inTuneNote.frequency];
        self.audioBufferListLength = [self frameCountForPercentCompression:percentCompression
                                                        andRequestedFrames:capacityFrames];
    }
    
    self.bufferInitialized = YES;
    self.audioBufferList = [SBPlayableNote createAudioBufferListWithChannelsPerFrame:channelsPerFrame
                                                                         interleaved:interleaved
                                                                       bytesPerFrame:bytesPerFrame
                                                                      capacityFrames:self.audioBufferListLength];
}

/* 
 * http://stackoverflow.com/a/3796721/337934
 */
+ (AudioBufferList*) createAudioBufferListWithChannelsPerFrame:(UInt32)channelsPerFrame
                                                   interleaved:(BOOL)interleaved
                                                 bytesPerFrame:(UInt32)bytesPerFrame
                                                capacityFrames:(UInt32)capacityFrames
{
    AudioBufferList *bufferList = NULL;
    
    UInt32 numBuffers = interleaved ? 1 : channelsPerFrame;
    UInt32 channelsPerBuffer = interleaved ? channelsPerFrame : 1;
    
    bufferList = calloc(1, offsetof(AudioBufferList, mBuffers) + (sizeof(AudioBuffer) * numBuffers));
    
    bufferList->mNumberBuffers = numBuffers;
    
    for(UInt32 bufferIndex = 0; bufferIndex < bufferList->mNumberBuffers; ++bufferIndex)
    {
        bufferList->mBuffers[bufferIndex].mData = calloc(capacityFrames, bytesPerFrame);
        bufferList->mBuffers[bufferIndex].mDataByteSize = capacityFrames * bytesPerFrame;
        bufferList->mBuffers[bufferIndex].mNumberChannels = channelsPerBuffer;
    }
    
    return bufferList;
}

#pragma mark - Stuff for pitch modulation

/**
 * ISSUE: we allocate an audio buffer list for sine waves even though we don't use it
 */
- (BOOL) readIntoAudioBufferList:(AudioBufferList*)intoAudioBufferList
               forNumberOfFrames:(UInt32)numberOfFrames
{
    UInt32 bufferSize; // amount of frames actually read
    BOOL eof = NO; // end of file
    
    // if we are modifying pitch
    if (self.centsOff != 0.0 && self.instrumentType != InstrumentTypeSineWave)
    {
        // read into our bufferlist
        [self.audioFile readFrames:self.audioBufferListLength
                   audioBufferList:self.audioBufferList
                        bufferSize:&bufferSize
                               eof:&eof];
        
        // then interpolate into the passed in audio buffer list
        Float32 *myBufferLeft = self.audioBufferList->mBuffers[0].mData;
        Float32 *myBufferRight = self.audioBufferList->mBuffers[1].mData;
        Float32 *intoBufferLeft = intoAudioBufferList->mBuffers[0].mData;
        Float32 *intoBufferRight = intoAudioBufferList->mBuffers[1].mData;
        
        for (NSInteger i = 0; i < numberOfFrames; i++)
        {
            float leftChannel = [self valueForFrame:i
                                            withData:myBufferLeft
                                          dataLength:self.audioBufferListLength
                                     requestedFrames:numberOfFrames];
            float rightChannel = [self valueForFrame:i
                                            withData:myBufferRight
                                          dataLength:self.audioBufferListLength
                                     requestedFrames:numberOfFrames];
            
            intoBufferLeft[i] = leftChannel;
            intoBufferRight[i] = rightChannel;
        }
    }
    else
    {
        [self.audioFile readFrames:numberOfFrames
                   audioBufferList:intoAudioBufferList
                        bufferSize:&bufferSize
                               eof:&eof];
    }
    
    return eof;
}

- (double) percentCompressionFromFreq:(double)fromFreq toFreq:(double)toFreq
{
    return fromFreq / toFreq;
}

- (UInt32) frameCountForPercentCompression:(double)compression
                           andRequestedFrames:(UInt32)requestedFrames
{
    return (UInt32)(compression * (double)requestedFrames);
}

- (float) valueForFrame:(NSInteger)frameIndex
                withData:(Float32*)data
              dataLength:(NSInteger)dataLength
         requestedFrames:(NSInteger)requestedFrames
{
    double exactPos = ((double)frameIndex / (double)requestedFrames) * (double)dataLength;
    int left = floor(exactPos);
    int right = ceil(exactPos);
    float leftVal = data[left];
    float rightVal = data[right];
    float offset = exactPos - (float)left;
    float value = leftVal + offset * (rightVal - leftVal);
    return value;
}


@end

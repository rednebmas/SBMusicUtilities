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

static NSString *samplesBaseFilePath;
static NSString *const sampleFileType = @"mp3";

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
        _thetaIncrement = 2.0 * M_PI * self.frequency / SAMPLE_RATE;
    }
    return self;
}

- (id) initWithName:(NSString *)name
{
    self = [super initWithName:name];
    if (self)
    {
        _thetaIncrement = 2.0 * M_PI * self.frequency / SAMPLE_RATE;
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

#pragma mark - Properties

- (void)setFrequency:(double)frequency
{
    _frequency = frequency;
    self.thetaIncrement = 2.0 * M_PI * self.frequency / SAMPLE_RATE;
}

#pragma mark - Misc...

- (void) loadAudioFile
{
    NSString *sampleName = [NSString stringWithFormat:@"Piano.ff.%@", self.nameWithOctave];
    NSString *path;
    if (samplesBaseFilePath == nil)
    {
        path = [[NSBundle mainBundle] pathForResource:sampleName ofType:sampleFileType];
    }
    else
    {
        NSString *filename = [NSString stringWithFormat:@"%@.%@", sampleName, sampleFileType];
        path = [samplesBaseFilePath stringByAppendingPathComponent:filename];
    }
    
    NSLog(@"%@", path);
    self.audioFile = [EZAudioFile audioFileWithURL:[NSURL fileURLWithPath:path]];
}

+ (void) setSamplesBaseFilePath:(NSString*)baseFilePath;
{
    samplesBaseFilePath = baseFilePath;
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
    if ([self isZero:self.centsOff threshold:.001] == NO && self.instrumentType != InstrumentTypeSineWave)
    {
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

- (BOOL) isZero:(double)value threshold:(double)threshold
{
    return value >= -threshold && value <= threshold;
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
    if (fabs(floor(self.centsOff)) != 0.0f && self.instrumentType != InstrumentTypeSineWave)
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
    // float value = leftVal + offset * (rightVal - leftVal); LINEAR
    float value = [self cosineInterpValueForLeftPoint:leftVal withRightPoint:rightVal andMu:offset];
    return value;
}

- (float) CUBICvalueForFrame:(NSInteger)frameIndex
                withData:(Float32*)data
              dataLength:(NSInteger)dataLength
         requestedFrames:(NSInteger)requestedFrames
{
    double exactPosInOurData = ((double)frameIndex / (double)requestedFrames) * (double)dataLength;
    if (exactPosInOurData < 1 || exactPosInOurData < (float)(dataLength - 1)) {
        return [self valueForFrame:frameIndex withData:data dataLength:dataLength requestedFrames:requestedFrames];
    }
    
    int left = floor(exactPosInOurData);
    int right = ceil(exactPosInOurData);
    float offset = exactPosInOurData - (float)left;
    
    float interpValue = CubicInterpolate(data[left-1], data[left], data[right], data[right+1], offset);
    return interpValue;
}

float CubicInterpolate(
                        float y0,float y1,
                        float y2,float y3,
                        float mu)
{
    float a0,a1,a2,a3,mu2;
    
    mu2 = mu*mu;
    a0 = y3 - y2 - y0 + y1;
    a1 = y0 - y1 - a0;
    a2 = y2 - y0;
    a3 = y1;
    
    return(a0*mu*mu2+a1*mu2+a2*mu+a3);
}

/*
 * http://paulbourke.net/miscellaneous/interpolation/
 */
- (float) cosineInterpValueForLeftPoint:(float)left withRightPoint:(float)right andMu:(float)mu
{
    float mu2;
    
    mu2 = (1-cosf(mu*M_PI))/2;
    return left*(1-mu2)+right*mu2;
}


@end

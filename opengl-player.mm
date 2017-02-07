#import "VideoSurface.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <CoreGraphics/CoreGraphics.h>

#include <string>

namespace kettle { 
    namespace video {
        explicit VideoSurface::VideoSurface(const std::string& path, GLuint w, GLuint h)
        {
            this->video_buffer = [[VideoBuffer alloc] initWithFile:[NSString stringWithUTF8String:path.c_str()] 
                                                      Width:w 
                                                      Height:h];
        }

        void VideoSurface::play()
        {
            [this->video_buffer start];
        }

        void VideoSurface::stop()
        {
            [this->video_buffer stop];
        }

        void VideoSurface::update(float t)
        {
            [this->video_buffer updateTexture: t];
        }

        GLuint VideoSurface::getTexture()
        {
            return this->video_buffer->CameraTexture;
        }
} }

@implementation VideoBuffer

@synthesize Session;
@synthesize PreviousTimestamp;
@synthesize VideoFrameRate;
@synthesize VideoDimensions;
@synthesize VideoType;
@synthesize CameraTexture;

-(GLuint)createVideoTextuerUsingWidth:(GLuint)w Height:(GLuint)h {
    int data_size = w * h * 4; // 4 bytes per pixel
    uint8_t *texture_data = (uint8_t *)malloc(data_size);
    GLuint handle;

    if(texture_data == NULL)
        return 0;

    memset(texture_data, 128, data_size);

    GL(glGenTextures(1, &handle));
    GL(glBindTexture(GL_TEXTURE_2D, handle));
    GL(glTexParameterf(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE));
    GL(glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_BGRA_EXT,
                    GL_UNSIGNED_BYTE, texture_data);
    GL(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR));
    GL(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR));
    GL(glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE));
    GL(glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE));
    GL(glBindTexture(GL_TEXTURE_2D, 0));
    free(texture_data);

    return handle;
}

-(id)initWithFile:(NSString *)file Width:(GLuint)w Height:(GLuint)h {
    if((self = [super init])) {
        self.File = [file retain];
        self.TextureHandle = [self createVideoTextuerUsingWidth:w Height:h];
       
        [self initReader];
    }

    return self;
}

-(void)initReader
{
    [self.Output release];
    [self.Reader release];
    [self.Track release];
    [self.Asset release];
    
    NSURL *url = [NSURL fileURLWithPath:self.File];
    self.Asset = [[AVURLAsset alloc] initWithURL:url options:NULL];
    
    NSArray *tracks = [self.Asset tracksWithMediaType:AVMediaTypeVideo];
    NSArray *soundTracks = [self.Asset tracksWithMediaType:AVMediaTypeAudio];

    self.Track = [tracks objectAtIndex:0];
    //self.SoundTrack = [soundTracks objectAtIndex:0];

    NSString *key = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:value, key, nil];
    
    self.Output = [[AVAssetReaderTrackOutput alloc]
                    initWithTrack:self.Track outputSettings:settings];
    
    self.SoundOutput = [[AVAssetReaderTrackOutput alloc]
                         initWithTrack:self.SoundTrack outputSettings:settings];
    
    self.Reader = [[AVAssetReader alloc] initWithAsset:self.Asset error:nil];
    [self.Reader addOutput:self.Output];
    [self.Reader addOutput:self.SoundOutput];
}

-(void)start {
    if(!self.Started) {
        if(self.Reader.status != AVAssetReaderStatusReading) {
            [self.Reader startReading];
        }
        self.Started = YES;
    }
}

-(void)stop {
	[self.Reader cancelReading];
	self.Started = NO;
}

-(void)updateTexture:(float)t {
    if(!self.Started) 
        return;

    //CMSampleBufferRef sound_buffer = [self.SoundOutput copyNextSampleBuffer];
    CMSampleBufferRef sample_buffer = [self.Output copyNextSampleBuffer];
    if(sample_buffer != 0){
        CMTime timestamp = CMSampleBufferGetPresentationTimeStamp( sample_buffer );
        if (CMTIME_IS_VALID( self.PreviousTimestamp ))
            self.VideoFrameRate = 1.0 / CMTimeGetSeconds( CMTimeSubtract( timestamp, self.PreviousTimestamp ) );

        self.PreviousTimestamp = timestamp;

        CVImageBufferRef pixel_buffer = CMSampleBufferGetImageBuffer(sample_buffer);
        CVPixelBufferLockBaseAddress(pixel_buffer, 0);
        size_t width = CVPixelBufferGetBytesPerRow(pixel_buffer) / 4;
        size_t height = CVPixelBufferGetHeight(pixel_buffer);

        GL(glBindTexture(GL_TEXTURE_2D, m_textureHandle));
        unsigned char *line_base = (unsigned char *)CVPixelBufferGetBaseAddress(pixel_buffer);
        GL(glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA_EXT, GL_UNSIGNED_BYTE, line_base));
        CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
        
        CFRelease(sample_buffer);
    } else {
        [self stop];
        [self initReader];
    }
}

-(void)dealloc {
    [super dealloc];
}

@end

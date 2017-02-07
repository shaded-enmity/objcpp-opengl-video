#ifdef __OBJC__

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#include <OpenGLES/ES1/glext.h>

@interface VideoBuffer : NSObject {
    CMTime                      PreviousTimestamp;

    Float64                     VideoFrameRate;
    CMVideoDimensions           VideoDimensions;
    CMVideoCodecType            VideoType;
    
    NSString                    *File;
    AVAsset                     *Asset;
    AVAssetTrack                *Track;
    AVAssetTrack                *SoundTrack;
    AVAssetReaderTrackOutput    *Output;
    AVAssetReaderTrackOutput    *SoundOutput;
    AVAssetReader               *Reader;
    AVCaptureSession            *Session; // For Camera inputs

    GLuint                      CameraTexture;
    BOOL                        Started;
}

@property (nonatomic, retain)  AVCaptureSession   *Session;
@property (readwrite)          Float64            VideoFrameRate;
@property (readwrite)          CMVideoDimensions  VideoDimensions;
@property (readwrite)          CMVideoCodecType   VideoType;
@property (readwrite)          CMTime             PreviousTimestamp;
@property (readwrite)          GLuint             CameraTexture;

-(void)initReader;
-(GLuint)createVideoTextuerUsingWidth:(GLuint) w Height:(GLuint)h;
-(id)initWithFile:(NSString *)file Width:GLuint()w Height:(GLuint)h;
-(void)start;
-(void)stop;
-(void)updateTexture:(float)t;
@end

#else // ifdef __OBJC__

struct VideoBuffer;

#endif // ifdef __OBJC__

#include <string>

void CheckOpenGLError(const char *stmt, const char *fname, int line) {
  GLenum err = glGetError();
  if (err != GL_NO_ERROR) {
    printf("OpenGL error %08x, at %s:%i - for %s\n", err, fname, line, stmt);
    abort();
  }
}
#ifdef _DEBUG
#define GL(stmt)                                                               \
  do {                                                                         \
    stmt;                                                                      \
    CheckOpenGLError(#stmt, __FILE__, __LINE__);                               \
  } while (0)
#else
#define GL(stmt) stmt
#endif

namespace kettle { 
    namespace video {
        class VideoSurface/* : kettle::gui::ImageNode*/
        {
            explicit  VideoSurface(const std::string& path);
            void      play();
            void      stop();
            void      update(float t);
            GLuint    getTexture();

            private: 
                VideoBuffer *video_buffer; 
        };
} }

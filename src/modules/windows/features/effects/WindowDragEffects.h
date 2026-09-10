/**
 * WindowDragEffects.h - Window Drag Visual Effects
 *
 * Implements various physics-based window drag effects inspired by
 * JelloAmmonia:
 * - Wobbly Windows: Spring-particle mesh for jello-like deformation
 * - Inertia: Window continues moving with momentum after release
 * - Scale Bounce: Shrink on grab, expand on release
 * - Tilt: 3D perspective rotation during drag
 *
 * Uses CGSSetWindowWarp() private API for mesh distortion effects.
 *
 * @author Alex "aspauldingcode"
 * @version 1.0
 */

#import <AppKit/AppKit.h>

// Effect types
typedef NS_ENUM(NSInteger, WindowDragEffect) {
  WindowDragEffectNone = 0,
  WindowDragEffectWobbly,  // Jello-like spring physics
  WindowDragEffectInertia, // Momentum after release
  WindowDragEffectScale,   // Shrink/expand bounce
  WindowDragEffectTilt,    // 3D perspective rotation
};

// Configuration for effects
@interface WindowDragEffectConfig : NSObject
@property(nonatomic) WindowDragEffect effect;
@property(nonatomic) CGFloat springStiffness; // For wobbly (default: 7.0)
@property(nonatomic) CGFloat friction;     // For wobbly/inertia (default: 1.5)
@property(nonatomic) CGFloat mass;         // For physics (default: 15.0)
@property(nonatomic) CGFloat scaleFactor;  // For scale (default: 0.95)
@property(nonatomic) CGFloat tiltAngle;    // For tilt in degrees (default: 5.0)
@property(nonatomic) NSInteger gridWidth;  // Mesh grid width (default: 8)
@property(nonatomic) NSInteger gridHeight; // Mesh grid height (default: 6)
@property(nonatomic) BOOL enabled;

+ (instancetype)defaultConfig;
+ (instancetype)configFromDictionary:(NSDictionary *)dict;
@end

// Manager for window drag effects
@interface WindowDragEffectManager : NSObject

+ (instancetype)sharedManager;

// Apply effect to a specific window
- (void)startDragForWindow:(NSWindow *)window atPoint:(NSPoint)point;
- (void)updateDragForWindow:(NSWindow *)window atPoint:(NSPoint)point;
- (void)endDragForWindow:(NSWindow *)window;

// Reset warp for window
- (void)resetWarpForWindow:(NSWindow *)window;

// Global enable/disable
@property(nonatomic) BOOL enabled;
@property(nonatomic, strong) WindowDragEffectConfig *config;

@end

// C function declarations for private CGS APIs
typedef int CGSConnectionID;
typedef int CGSWindowID;

typedef struct {
  float x;
  float y;
} CGSMeshPoint;

typedef struct {
  CGSMeshPoint local;
  CGSMeshPoint global;
} CGSPointWarp;

extern CGSConnectionID _CGSDefaultConnection(void);
extern CGError CGSSetWindowWarp(CGSConnectionID cid, CGSWindowID wid, int width,
                                int height, CGSPointWarp *mesh);

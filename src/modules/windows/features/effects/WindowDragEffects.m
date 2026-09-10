/**
 * WindowDragEffects.m - Window Drag Visual Effects Implementation
 *
 * Physics-based window drag effects inspired by JelloAmmonia.
 * Uses spring-particle physics with Verlet integration.
 *
 * @author Alex "aspauldingcode"
 * @version 1.0
 */

#import "WindowDragEffects.h"
#import "../../../../shared/ZKSwizzle/ZKSwizzle.h"
#import "../../../../shared/headers/window_filter.h"
#import "../../../../shared/macwmfx_logging.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#pragma mark - Physics Structures

typedef struct {
  CGPoint position;
  CGVector velocity;
  CGVector force;
  CGFloat mass;
  BOOL immobile;
} Particle;

typedef struct {
  NSInteger a; // Particle index A
  NSInteger b; // Particle index B
  CGVector offset;
  CGFloat stiffness;
} Spring;

#pragma mark - Window Effect State

@interface WindowEffectState : NSObject
@property(nonatomic, weak) NSWindow *window;
@property(nonatomic) Particle *particles;
@property(nonatomic) Spring *springs;
@property(nonatomic) NSInteger particleCount;
@property(nonatomic) NSInteger springCount;
@property(nonatomic) NSInteger mouseParticleIndex;
@property(nonatomic) CGPoint dragStartPoint;
@property(nonatomic) CGPoint lastDragPoint;
@property(nonatomic) CGVector dragVelocity;
@property(nonatomic) NSRect originalFrame;
@property(nonatomic) CGFloat originalScale;
@property(nonatomic, strong) CADisplayLink *displayLink;
@property(nonatomic) BOOL isDragging;
@property(nonatomic) NSTimeInterval lastUpdateTime;

- (void)freeMemory;
@end

@implementation WindowEffectState

- (void)freeMemory {
  if (_particles) {
    free(_particles);
    _particles = NULL;
  }
  if (_springs) {
    free(_springs);
    _springs = NULL;
  }
  _particleCount = 0;
  _springCount = 0;
}

- (void)dealloc {
  [self freeMemory];
  if (_displayLink) {
    [_displayLink invalidate];
  }
}

@end

#pragma mark - WindowDragEffectConfig Implementation

@implementation WindowDragEffectConfig

+ (instancetype)defaultConfig {
  WindowDragEffectConfig *config = [[WindowDragEffectConfig alloc] init];
  config.effect = WindowDragEffectWobbly;
  config.springStiffness = 7.0;
  config.friction = 1.5;
  config.mass = 15.0;
  config.scaleFactor = 0.95;
  config.tiltAngle = 5.0;
  config.gridWidth = 8;
  config.gridHeight = 6;
  config.enabled = YES;
  return config;
}

+ (instancetype)configFromDictionary:(NSDictionary *)dict {
  WindowDragEffectConfig *config = [self defaultConfig];

  if (dict[@"effect"]) {
    NSString *effectName = dict[@"effect"];
    if ([effectName isEqualToString:@"wobbly"]) {
      config.effect = WindowDragEffectWobbly;
    } else if ([effectName isEqualToString:@"inertia"]) {
      config.effect = WindowDragEffectInertia;
    } else if ([effectName isEqualToString:@"scale"]) {
      config.effect = WindowDragEffectScale;
    } else if ([effectName isEqualToString:@"tilt"]) {
      config.effect = WindowDragEffectTilt;
    } else if ([effectName isEqualToString:@"none"]) {
      config.effect = WindowDragEffectNone;
    }
  }

  if (dict[@"springStiffness"])
    config.springStiffness = [dict[@"springStiffness"] doubleValue];
  if (dict[@"friction"])
    config.friction = [dict[@"friction"] doubleValue];
  if (dict[@"mass"])
    config.mass = fmax(0.1, [dict[@"mass"] doubleValue]);
  if (dict[@"scaleFactor"])
    config.scaleFactor = [dict[@"scaleFactor"] doubleValue];
  if (dict[@"tiltAngle"])
    config.tiltAngle = [dict[@"tiltAngle"] doubleValue];
  if (dict[@"gridWidth"])
    config.gridWidth = fmax(2, [dict[@"gridWidth"] integerValue]);
  if (dict[@"gridHeight"])
    config.gridHeight = fmax(2, [dict[@"gridHeight"] integerValue]);
  if (dict[@"enabled"] != nil)
    config.enabled = [dict[@"enabled"] boolValue];

  return config;
}

@end

#pragma mark - WindowDragEffectManager Implementation

@interface WindowDragEffectManager ()
@property(nonatomic, strong)
    NSMapTable<NSWindow *, WindowEffectState *> *windowStates;
@property(nonatomic) CGSConnectionID connection;
@end

@implementation WindowDragEffectManager

+ (instancetype)sharedManager {
  static WindowDragEffectManager *sharedManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedManager = [[WindowDragEffectManager alloc] init];
  });
  return sharedManager;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _windowStates = [NSMapTable weakToStrongObjectsMapTable];
    _config = [WindowDragEffectConfig defaultConfig];
    _enabled = YES;
    _connection = _CGSDefaultConnection();
  }
  return self;
}

#pragma mark - Public API

- (void)startDragForWindow:(NSWindow *)window atPoint:(NSPoint)point {
  if (!self.enabled || !self.config.enabled)
    return;
  if (!macwmfx_isStandardAppWindow(window))
    return;

  WindowEffectState *state = [self stateForWindow:window create:YES];
  if (state.isDragging) {
    // Already dragging, just update the point
    [self updateDragForWindow:window atPoint:point];
    return;
  }
  state.isDragging = YES;
  state.dragStartPoint = point;
  state.lastDragPoint = point;
  state.originalFrame = window.frame;
  state.originalScale = 1.0;
  state.lastUpdateTime = CACurrentMediaTime();

  switch (self.config.effect) {
  case WindowDragEffectWobbly:
    [self initializeWobblyPhysicsForState:state];
    break;
  case WindowDragEffectScale:
    [self applyScaleEffect:state scale:self.config.scaleFactor];
    break;
  case WindowDragEffectTilt:
    [self applyTiltEffect:state atPoint:point];
    break;
  case WindowDragEffectInertia:
    state.dragVelocity = CGVectorMake(0, 0);
    break;
  default:
    break;
  }

  // Apply initial warp immediately to prevent jumping
  [self applyWarpForState:state];

  // Start display link for drag updates (smoother than events)
  if (state.displayLink) {
    [state.displayLink invalidate];
  }
  state.displayLink =
      [NSScreen.mainScreen displayLinkWithTarget:self
                                        selector:@selector(dragUpdateStep:)];
  objc_setAssociatedObject(state.displayLink, "effectState", state,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  [state.displayLink addToRunLoop:[NSRunLoop currentRunLoop]
                          forMode:NSRunLoopCommonModes];

  MACWMFX_LOG_INFO(macwmfx_log_drag_effects,
                   "Started drag effect %ld for window %ld",
                   (long)self.config.effect, (long)window.windowNumber);
}

- (void)updateDragForWindow:(NSWindow *)window atPoint:(NSPoint)point {
  WindowEffectState *state = [self stateForWindow:window create:NO];
  if (!state || !state.isDragging)
    return;

  NSTimeInterval now = CACurrentMediaTime();
  NSTimeInterval delta = now - state.lastUpdateTime;
  state.lastUpdateTime = now;

  if (delta > 0.1)
    delta = 0.1;

  // Update mouse particle
  state.particles[state.mouseParticleIndex].position = point;

  // Run a few physics steps immediately for event-based updates
  for (int step = 0; step < 5; step++) {
    [self physicsStepForState:state stepSize:delta * 7];
  }

  state.lastDragPoint = point;

  // Apply warp immediately
  [self applyWarpForState:state];
}

- (void)dragUpdateStep:(CADisplayLink *)displayLink {
  WindowEffectState *state =
      objc_getAssociatedObject(displayLink, "effectState");
  if (!state || !state.isDragging || !state.window) {
    [displayLink invalidate];
    return;
  }

  NSWindow *window = state.window;
  NSPoint mousePos = [NSEvent mouseLocation];

  NSTimeInterval now = CACurrentMediaTime();
  NSTimeInterval delta = now - state.lastUpdateTime;
  state.lastUpdateTime = now;

  // Calculate drag velocity for inertia
  if (delta > 0) {
    state.dragVelocity =
        CGVectorMake((mousePos.x - state.lastDragPoint.x) / delta,
                     (mousePos.y - state.lastDragPoint.y) / delta);
  }
  state.lastDragPoint = mousePos;

  switch (self.config.effect) {
  case WindowDragEffectWobbly:
    [self updateWobblyPhysicsForState:state atPoint:mousePos delta:delta];
    break;
  case WindowDragEffectTilt:
    [self applyTiltEffect:state atPoint:mousePos];
    break;
  default:
    break;
  }
}

- (void)window:(NSWindow *)window didResizeToFrame:(NSRect)newFrame {
  WindowEffectState *state = [self stateForWindow:window create:NO];
  if (!state || !state.isDragging)
    return;

  NSRect oldFrame = state.originalFrame;
  if (oldFrame.size.width <= 0 || oldFrame.size.height <= 0) {
    state.originalFrame = newFrame;
    return;
  }

  CGFloat scaleX = newFrame.size.width / oldFrame.size.width;
  CGFloat scaleY = newFrame.size.height / oldFrame.size.height;

  // Scale relative particle positions to match new window size
  for (NSInteger i = 0; i < state.particleCount - 1; i++) {
    state.particles[i].position.x *= scaleX;
    state.particles[i].position.y *= scaleY;
  }

  // Update spring offsets
  NSInteger gridW = self.config.gridWidth;
  NSInteger gridH = self.config.gridHeight;
  NSInteger springIdx = 0;

  // Horizontal offsets
  for (NSInteger y = 0; y < gridH; y++) {
    for (NSInteger x = 0; x < gridW - 1; x++) {
      state.springs[springIdx++].offset =
          CGVectorMake(newFrame.size.width / (gridW - 1), 0);
    }
  }
  // Vertical offsets
  for (NSInteger y = 0; y < gridH - 1; y++) {
    for (NSInteger x = 0; x < gridW; x++) {
      state.springs[springIdx++].offset =
          CGVectorMake(0, newFrame.size.height / (gridH - 1));
    }
  }

  state.originalFrame = newFrame;

  // Apply warp immediately to reflect resize
  [self applyWarpForState:state];
}

- (void)endDragForWindow:(NSWindow *)window {
  if (!self.enabled || !self.config.enabled)
    return;

  WindowEffectState *state = [self stateForWindow:window create:NO];
  if (!state)
    return;

  state.isDragging = NO;

  switch (self.config.effect) {
  case WindowDragEffectWobbly:
    [self startWobblySettleAnimationForState:state];
    break;
  case WindowDragEffectScale:
    [self animateScaleResetForState:state];
    break;
  case WindowDragEffectTilt:
    [self resetWarpForWindow:window];
    break;
  case WindowDragEffectInertia:
    [self startInertiaAnimationForState:state];
    break;
  default:
    break;
  }

  MACWMFX_LOG_DEBUG(macwmfx_log_styler, "Ended drag effect for window %ld",
                    (long)window.windowNumber);
}

- (void)resetWarpForWindow:(NSWindow *)window {
  if (!window)
    return;

  CGSWindowID windowID = (CGSWindowID)[window windowNumber];
  CGSSetWindowWarp(self.connection, windowID, 0, 0, NULL);
}

#pragma mark - State Management

- (WindowEffectState *)stateForWindow:(NSWindow *)window create:(BOOL)create {
  WindowEffectState *state = [self.windowStates objectForKey:window];
  if (!state && create) {
    state = [[WindowEffectState alloc] init];
    state.window = window;
    [self.windowStates setObject:state forKey:window];
  }
  return state;
}

#pragma mark - Wobbly Windows Physics

- (void)initializeWobblyPhysicsForState:(WindowEffectState *)state {
  [state freeMemory];

  NSWindow *window = state.window;
  NSInteger gridW = self.config.gridWidth;
  NSInteger gridH = self.config.gridHeight;
  NSInteger particleCount = gridW * gridH + 1; // +1 for mouse particle

  // Allocate particles
  state.particles = calloc(particleCount, sizeof(Particle));
  state.particleCount = particleCount;

  NSRect frame = window.frame;

  // Initialize grid particles
  for (NSInteger y = 0; y < gridH; y++) {
    for (NSInteger x = 0; x < gridW; x++) {
      NSInteger idx = y * gridW + x;
      CGFloat px = (x / (CGFloat)(gridW - 1)) * frame.size.width;
      CGFloat py = (y / (CGFloat)(gridH - 1)) * frame.size.height;

      state.particles[idx].position = CGPointMake(px, py);
      state.particles[idx].velocity = CGVectorMake(0, 0);
      state.particles[idx].force = CGVectorMake(0, 0);
      state.particles[idx].mass = self.config.mass;
      state.particles[idx].immobile = NO;
    }
  }

  // Initialize mouse particle (last one) - convert to relative
  NSInteger mouseIdx = particleCount - 1;
  state.mouseParticleIndex = mouseIdx;
  CGPoint mousePos = [NSEvent mouseLocation];
  state.particles[mouseIdx].position =
      CGPointMake(mousePos.x - frame.origin.x, mousePos.y - frame.origin.y);
  state.particles[mouseIdx].mass = 1.0;
  state.particles[mouseIdx].immobile = YES;

  // Create springs
  NSInteger maxSprings =
      (gridW - 1) * gridH + gridW * (gridH - 1) + (gridW * 2 + gridH * 2);
  state.springs = calloc(maxSprings, sizeof(Spring));
  state.springCount = 0;

  // Horizontal springs
  for (NSInteger y = 0; y < gridH; y++) {
    for (NSInteger x = 0; x < gridW - 1; x++) {
      NSInteger idx = state.springCount++;
      state.springs[idx].a = y * gridW + x;
      state.springs[idx].b = y * gridW + x + 1;
      state.springs[idx].offset =
          CGVectorMake(frame.size.width / (gridW - 1), 0);
      state.springs[idx].stiffness = self.config.springStiffness;
    }
  }

  // Vertical springs
  for (NSInteger y = 0; y < gridH - 1; y++) {
    for (NSInteger x = 0; x < gridW; x++) {
      NSInteger idx = state.springCount++;
      state.springs[idx].a = y * gridW + x;
      state.springs[idx].b = (y + 1) * gridW + x;
      state.springs[idx].offset =
          CGVectorMake(0, frame.size.height / (gridH - 1));
      state.springs[idx].stiffness = self.config.springStiffness;
    }
  }

  // Connect boundary particles (Top, Bottom, Left, Right) to mouse particle
  CGPoint relativeMousePos =
      CGPointMake(mousePos.x - frame.origin.x, mousePos.y - frame.origin.y);

  for (NSInteger y = 0; y < gridH; y++) {
    for (NSInteger x = 0; x < gridW; x++) {
      // Only connect boundaries
      if (x > 0 && x < gridW - 1 && y > 0 && y < gridH - 1)
        continue;

      NSInteger particleIdx = y * gridW + x;
      Particle *p = &state.particles[particleIdx];

      CGFloat dx = relativeMousePos.x - p->position.x;
      CGFloat dy = relativeMousePos.y - p->position.y;
      CGFloat dist = sqrt(dx * dx + dy * dy);

      // Weight stiffness by proximity to mouse
      CGFloat maxDist = sqrt(frame.size.width * frame.size.width +
                             frame.size.height * frame.size.height);
      CGFloat weight = 1.0 - (dist / maxDist);
      weight = pow(weight, 2); // Sharper falloff

      if (weight < 0.1)
        continue;

      NSInteger idx = state.springCount++;
      state.springs[idx].a = particleIdx;
      state.springs[idx].b = mouseIdx;
      state.springs[idx].offset = CGVectorMake(dx, dy);
      state.springs[idx].stiffness = self.config.springStiffness * weight * 0.5;
    }
  }
}

- (void)updateWobblyPhysicsForState:(WindowEffectState *)state
                            atPoint:(NSPoint)point
                              delta:(NSTimeInterval)delta {
  if (delta > 0.1)
    delta = 0.1; // Cap delta to prevent instability

  // Convert point to relative
  NSPoint relativePoint = CGPointMake(point.x - state.window.frame.origin.x,
                                      point.y - state.window.frame.origin.y);

  // Update mouse particle position
  state.particles[state.mouseParticleIndex].position = relativePoint;

  // Run physics steps
  for (int step = 0; step < 15; step++) {
    [self physicsStepForState:state stepSize:delta * 7];
  }

  // Apply warp
  [self applyWarpForState:state];
}

- (void)physicsStepForState:(WindowEffectState *)state
                   stepSize:(CGFloat)stepSize {
  Particle *particles = state.particles;
  Spring *springs = state.springs;

  // Clear forces
  for (NSInteger i = 0; i < state.particleCount; i++) {
    particles[i].force = CGVectorMake(0, 0);
  }

  // Apply spring forces
  for (NSInteger i = 0; i < state.springCount; i++) {
    Spring *s = &springs[i];
    Particle *pa = &particles[s->a];
    Particle *pb = &particles[s->b];

    CGFloat dx = pb->position.x - pa->position.x - s->offset.dx;
    CGFloat dy = pb->position.y - pa->position.y - s->offset.dy;

    CGVector forceA =
        CGVectorMake(s->stiffness * 0.5 * dx, s->stiffness * 0.5 * dy);
    CGVector forceB = CGVectorMake(-forceA.dx, -forceA.dy);

    if (!pa->immobile && pb->immobile) {
      forceA.dx *= 2;
      forceA.dy *= 2;
    }
    if (pa->immobile && !pb->immobile) {
      forceB.dx *= 2;
      forceB.dy *= 2;
    }
    if (pa->immobile && pb->immobile)
      continue;

    pa->force.dx += forceA.dx;
    pa->force.dy += forceA.dy;
    pb->force.dx += forceB.dx;
    pb->force.dy += forceB.dy;
  }

  // Apply friction and integrate (Velocity Verlet)
  CGFloat friction = self.config.friction;
  for (NSInteger i = 0; i < state.particleCount; i++) {
    if (particles[i].immobile)
      continue;

    particles[i].force.dx -= particles[i].velocity.dx * friction;
    particles[i].force.dy -= particles[i].velocity.dy * friction;

    CGVector accel = CGVectorMake(particles[i].force.dx / particles[i].mass,
                                  particles[i].force.dy / particles[i].mass);

    particles[i].velocity.dx += accel.dx * stepSize;
    particles[i].velocity.dy += accel.dy * stepSize;

    particles[i].position.x += particles[i].velocity.dx * stepSize;
    particles[i].position.y += particles[i].velocity.dy * stepSize;
  }
}

- (void)applyWarpForState:(WindowEffectState *)state {
  NSWindow *window = state.window;
  if (!window)
    return;

  NSInteger gridW = self.config.gridWidth;
  NSInteger gridH = self.config.gridHeight;
  NSRect frame = window.frame;

  // Get primary screen height for coordinate conversion
  CGFloat screenHeight = NSScreen.screens.firstObject.frame.size.height;

  // Build warp mesh
  CGSPointWarp *mesh = calloc(gridW * gridH, sizeof(CGSPointWarp));

  for (NSInteger y = 0; y < gridH; y++) {
    for (NSInteger x = 0; x < gridW; x++) {
      NSInteger idx = y * gridW + x;
      // Flip y for mesh (0 at top)
      NSInteger meshY = (gridH - 1) - y;
      NSInteger meshIdx = meshY * gridW + x;

      // Local coords (relative to window)
      mesh[meshIdx].local.x = (x / (CGFloat)(gridW - 1)) * frame.size.width;
      mesh[meshIdx].local.y =
          (meshY / (CGFloat)(gridH - 1)) * frame.size.height;

      // Global coords (particle positions + window origin, flipped for CGS)
      mesh[meshIdx].global.x = frame.origin.x + state.particles[idx].position.x;
      mesh[meshIdx].global.y =
          screenHeight - (frame.origin.y + state.particles[idx].position.y);
    }
  }

  CGSWindowID windowID = (CGSWindowID)[window windowNumber];
  CGSSetWindowWarp(self.connection, windowID, (int)gridW, (int)gridH, mesh);

  free(mesh);

  // NO LONGER update window origin during active drag to avoid fighting
  // AppKit setFrameOrigin is now only handled during settlement
}

- (void)startWobblySettleAnimationForState:(WindowEffectState *)state {
  // Release mouse particle
  state.particles[state.mouseParticleIndex].immobile = NO;

  // Start display link for settle animation
  if (state.displayLink) {
    [state.displayLink invalidate];
  }

  // Note: weakState and weakSelf would be used for safer capture in blocks
  // but we're using objc_setAssociatedObject pattern instead

  state.displayLink =
      [NSScreen.mainScreen displayLinkWithTarget:self
                                        selector:@selector(wobblySettleStep:)];
  objc_setAssociatedObject(state.displayLink, "effectState", state,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  [state.displayLink addToRunLoop:[NSRunLoop currentRunLoop]
                          forMode:NSRunLoopCommonModes];
}

- (void)wobblySettleStep:(CADisplayLink *)displayLink {
  WindowEffectState *state =
      objc_getAssociatedObject(displayLink, "effectState");
  if (!state || !state.window) {
    [displayLink invalidate];
    return;
  }

  NSTimeInterval delta = displayLink.duration;

  // Run physics
  for (int step = 0; step < 15; step++) {
    [self physicsStepForState:state stepSize:delta * 7];
  }

  // Calculate total force to determine if settled
  CGFloat totalForce = 0;
  for (NSInteger i = 0; i < state.particleCount; i++) {
    totalForce +=
        fabs(state.particles[i].force.dx) + fabs(state.particles[i].force.dy);
  }

  if (totalForce < 20) {
    // Settled - reset warp and stop
    [self resetWarpForWindow:state.window];

    // Set final window position
    CGPoint finalOrigin = state.particles[0].position;
    [state.window setFrameOrigin:finalOrigin];

    [displayLink invalidate];
    state.displayLink = nil;
    [state freeMemory];

    MACWMFX_LOG_DEBUG(macwmfx_log_styler,
                      "Wobbly settle complete for window %ld",
                      (long)state.window.windowNumber);
  } else {
    [self applyWarpForState:state];
  }
}

#pragma mark - Scale Bounce Effect

- (void)applyScaleEffect:(WindowEffectState *)state scale:(CGFloat)scale {
  NSWindow *window = state.window;
  if (!window)
    return;

  NSRect frame = window.frame;
  NSInteger gridW = 2;
  NSInteger gridH = 2;

  CGFloat screenHeight = NSScreen.screens.firstObject.frame.size.height;

  // Calculate center
  CGFloat centerX = frame.origin.x + frame.size.width / 2;
  CGFloat centerY = frame.origin.y + frame.size.height / 2;

  CGFloat scaledW = frame.size.width * scale;
  CGFloat scaledH = frame.size.height * scale;

  CGSPointWarp mesh[4];

  // Bottom-left
  mesh[0].local.x = 0;
  mesh[0].local.y = frame.size.height;
  mesh[0].global.x = centerX - scaledW / 2;
  mesh[0].global.y = screenHeight - (centerY - scaledH / 2);

  // Bottom-right
  mesh[1].local.x = frame.size.width;
  mesh[1].local.y = frame.size.height;
  mesh[1].global.x = centerX + scaledW / 2;
  mesh[1].global.y = screenHeight - (centerY - scaledH / 2);

  // Top-left
  mesh[2].local.x = 0;
  mesh[2].local.y = 0;
  mesh[2].global.x = centerX - scaledW / 2;
  mesh[2].global.y = screenHeight - (centerY + scaledH / 2);

  // Top-right
  mesh[3].local.x = frame.size.width;
  mesh[3].local.y = 0;
  mesh[3].global.x = centerX + scaledW / 2;
  mesh[3].global.y = screenHeight - (centerY + scaledH / 2);

  CGSWindowID windowID = (CGSWindowID)[window windowNumber];
  CGSSetWindowWarp(self.connection, windowID, (int)gridW, (int)gridH, mesh);
}

- (void)animateScaleResetForState:(WindowEffectState *)state {
  // Animate scale back to 1.0 with spring effect

  // Quick spring-back animation

  // Quick spring-back animation
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        [self applyScaleEffect:state scale:1.02]; // Slight overshoot
      });
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        [self applyScaleEffect:state scale:0.99]; // Slight undershoot
      });
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        [self resetWarpForWindow:state.window];
      });
}

#pragma mark - Tilt Effect

- (void)applyTiltEffect:(WindowEffectState *)state atPoint:(NSPoint)point {
  NSWindow *window = state.window;
  if (!window)
    return;

  NSRect frame = window.frame;
  CGFloat screenHeight = NSScreen.screens.firstObject.frame.size.height;

  // Calculate tilt based on drag distance from start
  CGFloat dx = point.x - state.dragStartPoint.x;
  CGFloat dy = point.y - state.dragStartPoint.y;
  CGFloat maxTilt = 0.1; // Maximum perspective distortion

  // Normalize drag distance
  CGFloat tiltX = fmin(fmax(dx / 200.0, -1.0), 1.0) * maxTilt;
  CGFloat tiltY = fmin(fmax(dy / 200.0, -1.0), 1.0) * maxTilt;

  // Create perspective mesh (4 corners)
  CGSPointWarp mesh[4];

  // Adjust corners based on tilt
  CGFloat perspectiveTop = 1.0 + tiltY * 0.5;
  CGFloat perspectiveBottom = 1.0 - tiltY * 0.5;
  CGFloat perspectiveLeft = 1.0 - tiltX * 0.5;
  CGFloat perspectiveRight = 1.0 + tiltX * 0.5;

  CGFloat centerX = frame.origin.x + frame.size.width / 2;
  CGFloat centerY = frame.origin.y + frame.size.height / 2;

  // Bottom-left
  mesh[0].local.x = 0;
  mesh[0].local.y = frame.size.height;
  mesh[0].global.x =
      centerX - (frame.size.width / 2) * perspectiveLeft * perspectiveBottom;
  mesh[0].global.y =
      screenHeight - (centerY - (frame.size.height / 2) * perspectiveBottom);

  // Bottom-right
  mesh[1].local.x = frame.size.width;
  mesh[1].local.y = frame.size.height;
  mesh[1].global.x =
      centerX + (frame.size.width / 2) * perspectiveRight * perspectiveBottom;
  mesh[1].global.y =
      screenHeight - (centerY - (frame.size.height / 2) * perspectiveBottom);

  // Top-left
  mesh[2].local.x = 0;
  mesh[2].local.y = 0;
  mesh[2].global.x =
      centerX - (frame.size.width / 2) * perspectiveLeft * perspectiveTop;
  mesh[2].global.y =
      screenHeight - (centerY + (frame.size.height / 2) * perspectiveTop);

  // Top-right
  mesh[3].local.x = frame.size.width;
  mesh[3].local.y = 0;
  mesh[3].global.x =
      centerX + (frame.size.width / 2) * perspectiveRight * perspectiveTop;
  mesh[3].global.y =
      screenHeight - (centerY + (frame.size.height / 2) * perspectiveTop);

  CGSWindowID windowID = (CGSWindowID)[window windowNumber];
  CGSSetWindowWarp(self.connection, windowID, 2, 2, mesh);
}

#pragma mark - Inertia Effect

- (void)startInertiaAnimationForState:(WindowEffectState *)state {
  if (state.displayLink) {
    [state.displayLink invalidate];
  }

  state.displayLink =
      [NSScreen.mainScreen displayLinkWithTarget:self
                                        selector:@selector(inertiaStep:)];
  objc_setAssociatedObject(state.displayLink, "effectState", state,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  [state.displayLink addToRunLoop:[NSRunLoop currentRunLoop]
                          forMode:NSRunLoopCommonModes];
}

- (void)inertiaStep:(CADisplayLink *)displayLink {
  WindowEffectState *state =
      objc_getAssociatedObject(displayLink, "effectState");
  if (!state || !state.window) {
    [displayLink invalidate];
    return;
  }

  NSTimeInterval delta = displayLink.duration;

  // Apply friction to velocity (use local copy since we can't modify struct
  // members through property)
  CGFloat friction = self.config.friction * 3;
  CGVector vel = state.dragVelocity;
  vel.dx *= pow(0.9, delta * friction);
  vel.dy *= pow(0.9, delta * friction);
  state.dragVelocity = vel;

  // Check if velocity is low enough to stop
  CGFloat speed = sqrt(vel.dx * vel.dx + vel.dy * vel.dy);

  if (speed < 10) {
    [displayLink invalidate];
    state.displayLink = nil;
    return;
  }

  // Move window
  NSPoint currentOrigin = state.window.frame.origin;
  currentOrigin.x += vel.dx * delta;
  currentOrigin.y += vel.dy * delta;

  [state.window setFrameOrigin:currentOrigin];
}

@end

#pragma mark - NSWindow Swizzle for Drag Detection

ZKSwizzleInterfaceGroup(MACWMFX_NSWindow_DragEffects, NSWindow, NSWindow,
                        MACWMFX_DRAG_EFFECTS)

    @implementation MACWMFX_NSWindow_DragEffects

- (void)_startLiveResize {
  ZKOrig(void);

  WindowDragEffectManager *manager = [WindowDragEffectManager sharedManager];
  if (manager.enabled && manager.config.enabled) {
    [manager startDragForWindow:(NSWindow *)self
                        atPoint:[NSEvent mouseLocation]];
  }
}

- (void)_startLiveMove {
  ZKOrig(void);

  WindowDragEffectManager *manager = [WindowDragEffectManager sharedManager];
  MACWMFX_LOG_DEBUG(macwmfx_log_drag_effects, "_startLiveMove for window %ld",
                    (long)((NSWindow *)self).windowNumber);
  if (manager.enabled && manager.config.enabled) {
    [manager startDragForWindow:(NSWindow *)self
                        atPoint:[NSEvent mouseLocation]];
  }
}

- (void)_endLiveMove {
  WindowDragEffectManager *manager = [WindowDragEffectManager sharedManager];
  MACWMFX_LOG_DEBUG(macwmfx_log_drag_effects, "_endLiveMove for window %ld",
                    (long)((NSWindow *)self).windowNumber);
  if (manager.enabled && manager.config.enabled) {
    [manager endDragForWindow:(NSWindow *)self];
  }

  ZKOrig(void);
}

- (void)_endLiveResize {
  WindowDragEffectManager *manager = [WindowDragEffectManager sharedManager];
  MACWMFX_LOG_DEBUG(macwmfx_log_drag_effects, "_endLiveResize for window %ld",
                    (long)((NSWindow *)self).windowNumber);
  if (manager.enabled && manager.config.enabled) {
    [manager endDragForWindow:(NSWindow *)self];
  }

  ZKOrig(void);
}

- (void)setFrame:(NSRect)frame display:(BOOL)display {
  WindowDragEffectManager *manager = [WindowDragEffectManager sharedManager];
  if (manager.enabled && manager.config.enabled) {
    [manager window:(NSWindow *)self didResizeToFrame:frame];
  }
  ZKOrig(void, frame, display);
}

- (void)_handleMouseDown:(NSEvent *)event {
  WindowDragEffectManager *manager = [WindowDragEffectManager sharedManager];
  MACWMFX_LOG_DEBUG(macwmfx_log_drag_effects, "_handleMouseDown for window %ld",
                    (long)((NSWindow *)self).windowNumber);

  ZKOrig(void, event);
}

- (void)sendEvent:(NSEvent *)event {
  WindowDragEffectManager *manager = [WindowDragEffectManager sharedManager];

  // If we are dragging, we might want to ensure updates are happening
  if (manager.enabled && manager.config.enabled &&
      event.type == NSEventTypeLeftMouseDragged) {
    [manager updateDragForWindow:(NSWindow *)self
                         atPoint:[NSEvent mouseLocation]];
  }

  ZKOrig(void, event);
}

@end

// Also hook mouse-based drag
ZKSwizzleInterfaceGroup(MACWMFX_NSWindow_MouseDrag, NSWindow, NSWindow,
                        MACWMFX_DRAG_EFFECTS)

    @implementation MACWMFX_NSWindow_MouseDrag

- (void)performWindowDragWithEvent:(NSEvent *)event {
  WindowDragEffectManager *manager = [WindowDragEffectManager sharedManager];
  MACWMFX_LOG_INFO(macwmfx_log_drag_effects,
                   "performWindowDragWithEvent starting for window %ld",
                   (long)((NSWindow *)self).windowNumber);

  id monitor = nil;
  if (manager.enabled && manager.config.enabled) {
    [manager startDragForWindow:(NSWindow *)self
                        atPoint:[NSEvent mouseLocation]];

    // Add monitor to ensure updates during blocking performWindowDrag loop
    NSWindow *window = (NSWindow *)self;
    monitor = [NSEvent
        addLocalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDragged
                                     handler:^NSEvent *(NSEvent *ev) {
                                       [manager
                                           updateDragForWindow:window
                                                       atPoint:
                                                           [NSEvent
                                                               mouseLocation]];
                                       return ev;
                                     }];
  }

  ZKOrig(void, event);

  if (monitor) {
    [NSEvent removeMonitor:monitor];
  }

  MACWMFX_LOG_INFO(macwmfx_log_drag_effects,
                   "performWindowDragWithEvent ending for window %ld",
                   (long)((NSWindow *)self).windowNumber);

  if (manager.enabled && manager.config.enabled) {
    [manager endDragForWindow:(NSWindow *)self];
  }
}

@end

#pragma mark - Initialization

static void setupDragEffects(void) __attribute__((constructor));
static void setupDragEffects(void) {
  @try {
    if (!NSClassFromString(@"NSApplication"))
      return;
    if (!NSClassFromString(@"NSWindow"))
      return;

    // Check CGS connection
    CGSConnectionID cid = _CGSDefaultConnection();
    if (cid <= 0) {
      MACWMFX_LOG_ERROR(macwmfx_log_drag_effects,
                        "Failed to get CGS connection (cid: %d). Drag effects "
                        "will not work.",
                        cid);
    } else {
      MACWMFX_LOG_INFO(macwmfx_log_drag_effects,
                       "CGS connection active (cid: %d)", cid);
    }

    // Initialize swizzle group for drag effects
    ZKSwizzleGroup(MACWMFX_DRAG_EFFECTS);

    MACWMFX_LOG_INFO(macwmfx_log_drag_effects,
                     "Window drag effects module initialized");
  } @catch (NSException *e) {
    MACWMFX_LOG_ERROR(macwmfx_log_drag_effects,
                      "Failed to initialize drag effects: %@", e.reason);
  }
}

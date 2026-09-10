#import "../server/macwmfx_server.h"

@implementation macwmfxServerMessage

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeInteger:self.command forKey:@"command"];
  [coder encodeObject:self.data forKey:@"data"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _command = (macwmfxServerCommand)[coder decodeIntegerForKey:@"command"];
    _data = [coder decodeObjectOfClasses:[NSSet setWithArray:@[
                     [NSDictionary class], [NSArray class], [NSString class],
                     [NSNumber class]
                   ]]
                                  forKey:@"data"];
  }
  return self;
}

@end

@implementation macwmfxServerResponse

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeInteger:self.type forKey:@"type"];
  [coder encodeObject:self.data forKey:@"data"];
  [coder encodeObject:self.errorMessage forKey:@"errorMessage"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _type = (macwmfxServerResponseType)[coder decodeIntegerForKey:@"type"];
    _data = [coder decodeObjectOfClasses:[NSSet setWithArray:@[
                     [NSDictionary class], [NSArray class], [NSString class],
                     [NSNumber class]
                   ]]
                                  forKey:@"data"];
    _errorMessage = [coder decodeObjectOfClass:[NSString class]
                                        forKey:@"errorMessage"];
  }
  return self;
}

@end

// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "FBSDKFeatureManager.h"

#import "FBSDKDataPersisting.h"
#import "FBSDKGateKeeperManager.h"
#import "FBSDKGateKeeperManaging.h"
#import "FBSDKSettingsProtocol.h"

static NSString *const FBSDKFeatureManagerPrefix = @"com.facebook.sdk:FBSDKFeatureManager.FBSDKFeature";

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKFeatureManager ()

@property (nullable, nonatomic) Class<FBSDKGateKeeperManaging> gateKeeperManager;
@property (nullable, nonatomic) id<FBSDKSettings> settings;
@property (nullable, nonatomic) id<FBSDKDataPersisting> store;

@end

@implementation FBSDKFeatureManager

#pragma mark - Public methods

// Transitional singleton introduced as a way to change the usage semantics
// from a type-based interface to an instance-based interface.
// The goal is to move from:
// ClassWithoutUnderlyingInstance -> ClassRelyingOnUnderlyingInstance -> Instance
static FBSDKFeatureManager *sharedInstance;
static dispatch_once_t sharedInstanceNonce;
+ (instancetype)shared
{
  dispatch_once(&sharedInstanceNonce, ^{
    sharedInstance = [self new];
  });
  return sharedInstance;
}

- (void)configureWithGateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
                              settings:(id<FBSDKSettings>)settings
                                 store:(id<FBSDKDataPersisting>)store
{
  _gateKeeperManager = gateKeeperManager;
  _settings = settings;
  _store = store;
}

+ (void)checkFeature:(FBSDKFeature)feature
     completionBlock:(FBSDKFeatureManagerBlock)completionBlock
{
  [self.shared checkFeature:feature completionBlock:completionBlock];
}

- (void)checkFeature:(FBSDKFeature)feature
     completionBlock:(FBSDKFeatureManagerBlock)completionBlock
{
  // check if the feature is locally disabled by Crash Shield first
  NSString *version = [self.store stringForKey:[self storageKeyForFeature:feature]];
  if (version && [version isEqualToString:self.settings.sdkVersion]) {
    if (completionBlock) {
      completionBlock(false);
    }
    return;
  }
  // check gk
  [self.gateKeeperManager loadGateKeepers:^(NSError *_Nullable error) {
    if (completionBlock) {
      completionBlock([self isEnabled:feature]);
    }
  }];
}

- (BOOL)isEnabled:(FBSDKFeature)feature
{
  if (FBSDKFeatureCore == feature || FBSDKFeatureNone == feature) {
    return YES;
  }

  FBSDKFeature parentFeature = [self.class getParentFeature:feature];
  if (parentFeature == feature) {
    return [self checkGK:feature];
  } else {
    return [self isEnabled:parentFeature] && [self checkGK:feature];
  }
}

- (void)disableFeature:(FBSDKFeature)feature
{
  [self.store setObject:self.settings.sdkVersion forKey:[self storageKeyForFeature:feature]];
}

- (NSString *)storageKeyForFeature:(FBSDKFeature)feature
{
  return [FBSDKFeatureManagerPrefix stringByAppendingString:[self.class featureName:feature]];
}

#pragma mark - Private methods

+ (FBSDKFeature)getParentFeature:(FBSDKFeature)feature
{
  if ((feature & 0xFF) > 0) {
    return feature & 0xFFFFFF00;
  } else if ((feature & 0xFF00) > 0) {
    return feature & 0xFFFF0000;
  } else if ((feature & 0xFF0000) > 0) {
    return feature & 0xFF000000;
  } else {
    return 0;
  }
}

- (BOOL)checkGK:(FBSDKFeature)feature
{
  NSString *key = [NSString stringWithFormat:@"FBSDKFeature%@", [self.class featureName:feature]];
  BOOL defaultValue = [self.class defaultStatus:feature];

  return [self.gateKeeperManager boolForKey:key
                               defaultValue:defaultValue];
}

+ (NSString *)featureName:(FBSDKFeature)feature
{
  NSString *featureName;
  switch (feature) {
    case FBSDKFeatureNone: featureName = @"NONE"; break;
    case FBSDKFeatureCore: featureName = @"CoreKit"; break;
    case FBSDKFeatureAppEvents: featureName = @"AppEvents"; break;
    case FBSDKFeatureCodelessEvents: featureName = @"CodelessEvents"; break;
    case FBSDKFeatureRestrictiveDataFiltering: featureName = @"RestrictiveDataFiltering"; break;
    case FBSDKFeatureAAM: featureName = @"AAM"; break;
    case FBSDKFeaturePrivacyProtection: featureName = @"PrivacyProtection"; break;
    case FBSDKFeatureSuggestedEvents: featureName = @"SuggestedEvents"; break;
    case FBSDKFeatureIntelligentIntegrity: featureName = @"IntelligentIntegrity"; break;
    case FBSDKFeatureModelRequest: featureName = @"ModelRequest"; break;
    case FBSDKFeatureEventDeactivation: featureName = @"EventDeactivation"; break;
    case FBSDKFeatureSKAdNetwork: featureName = @"SKAdNetwork"; break;
    case FBSDKFeatureSKAdNetworkConversionValue: featureName = @"SKAdNetworkConversionValue"; break;
    case FBSDKFeatureInstrument: featureName = @"Instrument"; break;
    case FBSDKFeatureCrashReport: featureName = @"CrashReport"; break;
    case FBSDKFeatureCrashShield: featureName = @"CrashShield"; break;
    case FBSDKFeatureErrorReport: featureName = @"ErrorReport"; break;
    case FBSDKFeatureATELogging: featureName = @"ATELogging"; break;
    case FBSDKFeatureAEM: featureName = @"AEM"; break;
    case FBSDKFeatureLogin: featureName = @"LoginKit"; break;
    case FBSDKFeatureShare: featureName = @"ShareKit"; break;
    case FBSDKFeatureGamingServices: featureName = @"GamingServicesKit"; break;
  }

  return featureName;
}

+ (BOOL)defaultStatus:(FBSDKFeature)feature
{
  switch (feature) {
    case FBSDKFeatureRestrictiveDataFiltering:
    case FBSDKFeatureEventDeactivation:
    case FBSDKFeatureInstrument:
    case FBSDKFeatureCrashReport:
    case FBSDKFeatureCrashShield:
    case FBSDKFeatureErrorReport:
    case FBSDKFeatureAAM:
    case FBSDKFeaturePrivacyProtection:
    case FBSDKFeatureSuggestedEvents:
    case FBSDKFeatureIntelligentIntegrity:
    case FBSDKFeatureModelRequest:
    case FBSDKFeatureATELogging:
    case FBSDKFeatureAEM:
    case FBSDKFeatureSKAdNetwork:
    case FBSDKFeatureSKAdNetworkConversionValue:
      return NO;
    case FBSDKFeatureNone:
    case FBSDKFeatureLogin:
    case FBSDKFeatureShare:
    case FBSDKFeatureCore:
    case FBSDKFeatureAppEvents:
    case FBSDKFeatureCodelessEvents:
    case FBSDKFeatureGamingServices:
      return YES;
  }
}

#if DEBUG && FBTEST

+ (void)reset
{
  // Reset the nonce so that a new instance will be created.
  if (sharedInstanceNonce) {
    sharedInstanceNonce = 0;
  }
}

#endif

@end

NS_ASSUME_NONNULL_END

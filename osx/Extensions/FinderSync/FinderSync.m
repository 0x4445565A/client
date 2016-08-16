//
//  FinderSync.m
//  FinderSync
//
//  Created by Gabriel on 6/10/15.
//  Copyright (c) 2015 Keybase. All rights reserved.
//

#import "FinderSync.h"

#import <KBKit/KBFinder.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <KBKit/KBRPClient.h>
#import <KBKit/KBRPC.h>

// static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@interface FinderSync ()
@property KBFinder *finder;
@property (nonatomic) KBRPClient *client;
@end

@implementation FinderSync

- (instancetype)init {
  if ((self = [super init])) {
    [DDLog addLogger:DDASLLogger.sharedInstance withLevel:DDLogLevelDebug];
    DDLogInfo(@"FinderSync init");
    NSString *mountDir = @"/keybase";
    DDLogDebug(@"Finder sync using: %@", mountDir);
    FIFinderSyncController.defaultController.directoryURLs = [NSSet setWithObject:[NSURL fileURLWithPath:mountDir]];

    _finder = [[KBFinder alloc] initWithFinderSyncController:FIFinderSyncController.defaultController];
  }
  return self;
}

- (void)testClient {
  KBEnvConfig *config = [KBEnvConfig envConfigWithRunMode:KBRunModeProd useGroupContainer:YES];
  DDLogInfo(@"Using sock file: %@", config.sockFile);
  _client = [[KBRPClient alloc] initWithConfig:config options:0]; // options:KBRClientOptionsAutoRetry];
  [_client open:^(NSError *error) {
    if (error) {
      DDLogError(@"Error opening socket: %@", error);
      return;
    }
    [self testRequest];
  }];
}

- (void)testRequest {
  KBRConfigRequest *request = [[KBRConfigRequest alloc] initWithClient:self.client];
  [request getCurrentStatus:^(NSError *error, KBRGetCurrentStatusRes *getCurrentStatusRes) {
    DDLogInfo(@"Status: %@, %@", error, getCurrentStatusRes);
  }];
}

- (void)beginObservingDirectoryAtURL:(NSURL *)URL {
  // The user is now seeing the container's contents.
  // If they see it in more than one view at a time, we're only told once.
  DDLogInfo(@"beginObservingDirectoryAtURL:%@", URL.filePathURL);

  KBRFsRequest *request = [[KBRFsRequest alloc] initWithClient:self.client];
  [request listWithPath:URL.path completion:^(NSError *error, KBRListResult *listResult) {
    DDLogInfo(@"Error: %@, Result: %@", error, listResult);
  }];
}

- (void)endObservingDirectoryAtURL:(NSURL *)URL {
  // The user is no longer seeing the container's contents.
  DDLogInfo(@"endObservingDirectoryAtURL:%@", URL.filePathURL);
}

- (void)requestBadgeIdentifierForURL:(NSURL *)URL {
  [_finder badgeIdForPath:URL.filePathURL.path completion:^(NSString *badgeId) {
    DDLogInfo(@"Badge for path: %@: %@", URL.filePathURL.path, badgeId);
    [FIFinderSyncController.defaultController setBadgeIdentifier:badgeId forURL:URL];
  }];
}

#pragma mark Menu/Toolbar

- (NSString *)toolbarItemName {
  return @"Keybase";
}

- (NSString *)toolbarItemToolTip {
  return @"Keybase: ?";
}

- (NSImage *)toolbarItemImage {
  return [NSImage imageNamed:NSImageNameCaution];
}

- (NSMenu *)menuForMenuKind:(FIMenuKind)whichMenu {
  NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
  [menu addItemWithTitle:@"Open" action:@selector(open:) keyEquivalent:@""];
  return menu;
}

- (IBAction)open:(id)sender {
  NSURL *target = [[FIFinderSyncController defaultController] targetedURL];
  NSArray *items = [[FIFinderSyncController defaultController] selectedItemURLs];

  DDLogDebug(@"%@, target: %@, items:", [sender title], [target filePathURL]);
  [items enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
    DDLogDebug(@" %@", [obj filePathURL]);
  }];
}

@end


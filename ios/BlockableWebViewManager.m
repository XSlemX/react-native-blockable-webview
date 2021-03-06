//
//  BlockableWebViewManager.m
//  example
//
//  Created by Rafael Seemann on 18/10/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "BlockableWebViewManager.h"

#import "React/RCTBridge.h"
#import "React/RCTUIManager.h"
#import "BlockableWebView.h"
#import "React/UIView+React.h"

@interface BlockableWebViewManager () <BlockableWebViewDelegate>

@end

@implementation BlockableWebViewManager
{
  NSConditionLock *_shouldStartLoadLock;
  BOOL _shouldStartLoad;
}

RCT_EXPORT_MODULE()

- (UIView *)view
{
  BlockableWebView *webView = [BlockableWebView new];
  webView.delegate = self;
  return webView;
}

RCT_EXPORT_VIEW_PROPERTY(source, NSDictionary)
RCT_REMAP_VIEW_PROPERTY(bounces, _webView.scrollView.bounces, BOOL)
RCT_REMAP_VIEW_PROPERTY(scrollEnabled, _webView.scrollView.scrollEnabled, BOOL)
RCT_REMAP_VIEW_PROPERTY(decelerationRate, _webView.scrollView.decelerationRate, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(scalesPageToFit, BOOL)
RCT_EXPORT_VIEW_PROPERTY(injectedJavaScript, NSString)
RCT_EXPORT_VIEW_PROPERTY(contentInset, UIEdgeInsets)
RCT_EXPORT_VIEW_PROPERTY(automaticallyAdjustContentInsets, BOOL)
RCT_EXPORT_VIEW_PROPERTY(onLoadingStart, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onLoadingFinish, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onLoadingError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onShouldStartLoadWithRequest, RCTDirectEventBlock)
RCT_REMAP_VIEW_PROPERTY(allowsInlineMediaPlayback, _webView.allowsInlineMediaPlayback, BOOL)
RCT_REMAP_VIEW_PROPERTY(mediaPlaybackRequiresUserAction, _webView.mediaPlaybackRequiresUserAction, BOOL)
RCT_REMAP_VIEW_PROPERTY(dataDetectorTypes, _webView.dataDetectorTypes, UIDataDetectorTypes)

RCT_EXPORT_VIEW_PROPERTY(onNavigationBlocked, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(navigationBlockingPolicies, NSArray)


RCT_EXPORT_METHOD(goBack:(nonnull NSNumber *)reactTag)
{
  [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, BlockableWebView *> *viewRegistry) {
    BlockableWebView *view = viewRegistry[reactTag];
    if (![view isKindOfClass:[BlockableWebView class]]) {
      RCTLogError(@"Invalid view returned from registry, expecting BlockableWebView, got: %@", view);
    } else {
      [view goBack];
    }
  }];
}

RCT_EXPORT_METHOD(goForward:(nonnull NSNumber *)reactTag)
{
  [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, BlockableWebView *> *viewRegistry) {
    BlockableWebView *view = viewRegistry[reactTag];
    if (![view isKindOfClass:[BlockableWebView class]]) {
      RCTLogError(@"Invalid view returned from registry, expecting BlockableWebView, got: %@", view);
    } else {
      [view goForward];
    }
  }];
}

RCT_EXPORT_METHOD(reload:(nonnull NSNumber *)reactTag)
{
  [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, BlockableWebView *> *viewRegistry) {
    BlockableWebView *view = viewRegistry[reactTag];
    if (![view isKindOfClass:[BlockableWebView class]]) {
      RCTLogError(@"Invalid view returned from registry, expecting BlockableWebView, got: %@", view);
    } else {
      [view reload];
    }
  }];
}

RCT_EXPORT_METHOD(stopLoading:(nonnull NSNumber *)reactTag)
{
  [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, BlockableWebView *> *viewRegistry) {
    BlockableWebView *view = viewRegistry[reactTag];
    if (![view isKindOfClass:[BlockableWebView class]]) {
      RCTLogError(@"Invalid view returned from registry, expecting BlockableWebView, got: %@", view);
    } else {
      [view stopLoading];
    }
  }];
}

#pragma mark - Exported synchronous methods

- (BOOL)webView:(__unused BlockableWebView *)webView
shouldStartLoadForRequest:(NSMutableDictionary<NSString *, id> *)request
   withCallback:(RCTDirectEventBlock)callback
{
  _shouldStartLoadLock = [[NSConditionLock alloc] initWithCondition:arc4random()];
  _shouldStartLoad = YES;
  request[@"lockIdentifier"] = @(_shouldStartLoadLock.condition);
  callback(request);
  
  // Block the main thread for a maximum of 250ms until the JS thread returns
  if ([_shouldStartLoadLock lockWhenCondition:0 beforeDate:[NSDate dateWithTimeIntervalSinceNow:.25]]) {
    BOOL returnValue = _shouldStartLoad;
    [_shouldStartLoadLock unlock];
    _shouldStartLoadLock = nil;
    return returnValue;
  } else {
    RCTLogWarn(@"Did not receive response to shouldStartLoad in time, defaulting to YES");
    return YES;
  }
}

RCT_EXPORT_METHOD(startLoadWithResult:(BOOL)result lockIdentifier:(NSInteger)lockIdentifier)
{
  if ([_shouldStartLoadLock tryLockWhenCondition:lockIdentifier]) {
    _shouldStartLoad = result;
    [_shouldStartLoadLock unlockWithCondition:0];
  } else {
    RCTLogWarn(@"startLoadWithResult invoked with invalid lockIdentifier: "
               "got %zd, expected %zd", lockIdentifier, _shouldStartLoadLock.condition);
  }
}

@end

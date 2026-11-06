//
//  HudTests.m
//  HudTests
//
//  Created by Matej Bukovinski on 31. 01. 16.
//  Copyright © 2016 Matej Bukovinski. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MBProgressHUD.h"
#import "../HudDemo/MBHudDemoSceneDelegate.h"


#define MBTestHUDIsVisible(hud, rootView) \
do { \
XCTAssertEqualObjects(hud.superview, rootView, @"The hud should be added to the view."); \
XCTAssertEqual(hud.alpha, 1.f, @"The HUD should be visible."); \
XCTAssertFalse(hud.hidden, @"The HUD should be visible."); \
XCTAssertEqual(hud.bezelView.alpha, 1.f, @"The HUD should be visible."); \
} while (0)

#define MBTestHUDIsHiden(hud, rootView) \
do { \
XCTAssertEqual(hud.alpha, 0.f, @"The hud should be faded out."); \
} while (0)

#define MBTestHUDIsHidenAndRemoved(hud, rootView) \
do { \
XCTAssertFalse([rootView.subviews containsObject:hud], @"The HUD should not be part of the view hierarchy."); \
MBTestHUDIsHiden(hud, rootView); \
XCTAssertNil(hud.superview, @"The HUD should not have a superview."); \
} while (0)

@interface MBTestHUD : MBProgressHUD
@end

@implementation MBTestHUD
@end

@interface HudTests : XCTestCase <MBProgressHUDDelegate>

@property (nonatomic) XCTestExpectation *hideExpectation;
@property (nonatomic, copy) dispatch_block_t hideChecks;

@end


@implementation HudTests

#pragma mark - Initialization

- (void)testInitializers {
    XCTAssertNotNil([[MBProgressHUD alloc] initWithView:[UIView new]]);
    UIView *nilView = nil;
    XCTAssertThrows([[MBProgressHUD alloc] initWithView:nilView]);
    XCTAssertNotNil([[MBProgressHUD alloc] initWithFrame:CGRectZero]);
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 480.f)];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:NO];
    [view encodeWithCoder:archiver];
    [archiver finishEncoding];
    XCTAssertNil(archiver.error);

    NSError *error = nil;
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:archiver.encodedData error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(unarchiver);
    unarchiver.requiresSecureCoding = NO;

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithCoder:unarchiver];
    [unarchiver finishDecoding];
    XCTAssertNil(unarchiver.error);
    XCTAssertNotNil(hud);
    XCTAssertEqualObjects([NSValue valueWithCGRect:hud.frame], [NSValue valueWithCGRect:view.frame]);
    XCTAssertEqual(hud.mode, MBProgressHUDModeIndeterminate);
    XCTAssertEqual(hud.alpha, 0.f);
    XCTAssertNotNil(hud.label);
    XCTAssertNotNil(hud.bezelView);
}

#pragma mark - Convenience

- (void)testHUDContainingView {
    UIView *container = [UIView new];
    MBTestHUD *outerHUD = [[MBTestHUD alloc] initWithView:container];
    [container addSubview:outerHUD];
    MBProgressHUD *innerHUD = [[MBProgressHUD alloc] initWithView:outerHUD];
    [outerHUD addSubview:innerHUD];
    innerHUD.mode = MBProgressHUDModeCustomView;
    UIView *content = [UIView new];
    UIView *nestedContent = [UIView new];
    [content addSubview:nestedContent];
    innerHUD.customView = content;

    XCTAssertEqual([MBProgressHUD HUDContainingView:innerHUD], innerHUD);
    XCTAssertEqual([MBProgressHUD HUDContainingView:innerHUD.bezelView], innerHUD);
    XCTAssertEqual([MBProgressHUD HUDContainingView:nestedContent], innerHUD);
    XCTAssertEqual([MBTestHUD HUDContainingView:nestedContent], outerHUD);
    XCTAssertNil([MBProgressHUD HUDContainingView:container]);
    XCTAssertNil([MBProgressHUD HUDContainingView:[UIView new]]);

    [innerHUD showAnimated:NO];
    [innerHUD hideAnimated:NO];
    XCTAssertNil([MBProgressHUD HUDForView:outerHUD]);
    XCTAssertEqual([MBProgressHUD HUDContainingView:nestedContent], innerHUD, @"Containment does not filter finished HUDs.");
    [innerHUD removeFromSuperview];
    XCTAssertNil([MBTestHUD HUDContainingView:nestedContent]);
    XCTAssertEqual([MBProgressHUD HUDContainingView:nestedContent], innerHUD);
}

- (void)testNonAnimatedConvenienceHUDPresentation {
    UIView *rootView = [self hostRootView];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootView animated:NO];

    XCTAssertNotNil(hud, @"A HUD should be created.");
    MBTestHUDIsVisible(hud, rootView);

    XCTAssertEqual(hud.bezelView.alpha, 1.f, @"The HUD should be visible.");
    XCTAssertFalse([hud.bezelView.layer.animationKeys containsObject:@"opacity"], @"The opacity should NOT be animated.");

    XCTAssertEqualObjects([MBProgressHUD HUDForView:rootView], hud, @"The HUD should be found via the convenience operation.");

    XCTAssertTrue([MBProgressHUD hideHUDForView:rootView animated:NO], @"The HUD should be found and removed.");

    MBTestHUDIsHidenAndRemoved(hud, rootView);

    XCTAssertFalse([MBProgressHUD hideHUDForView:rootView animated:NO], @"A subsequent HUD hide operation should fail.");
}

- (void)testAnimatedConvenienceHUDPresentation {
    UIView *rootView = [self hostRootView];

    self.hideExpectation = [self expectationWithDescription:@"The hudWasHidden: delegate should have been called."];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootView animated:YES];
    hud.delegate = self;

    XCTAssertNotNil(hud, @"A HUD should be created.");
    MBTestHUDIsVisible(hud, rootView);

    XCTAssertEqual(hud.bezelView.alpha, 1.f, @"The HUD should be visible.");
    XCTAssertTrue([hud.bezelView.layer.animationKeys containsObject:@"opacity"], @"The opacity should be animated.");

    XCTAssertEqualObjects([MBProgressHUD HUDForView:rootView], hud, @"The HUD should be found via the convenience operation.");

    XCTAssertTrue([MBProgressHUD hideHUDForView:rootView animated:YES], @"The HUD should be found and removed.");

    XCTAssertTrue([rootView.subviews containsObject:hud], @"The HUD should still be part of the view hierarchy.");
    XCTAssertEqual(hud.alpha, 1.f, @"The hud should still be visible.");
    XCTAssertEqualObjects(hud.superview, rootView, @"The hud should be added to the view.");
    XCTAssertEqual(hud.bezelView.alpha, 0.f, @"The HUD bezel should be animated out.");
    XCTAssertTrue([hud.bezelView.layer.animationKeys containsObject:@"opacity"], @"The opacity should be animated.");

    self.hideChecks = ^{
        MBTestHUDIsHidenAndRemoved(hud, rootView);

        XCTAssertFalse([MBProgressHUD hideHUDForView:rootView animated:YES], @"A subsequent HUD hide operation should fail.");
    };

    [self waitForExpectationsWithTimeout:5. handler:nil];
}

- (void)testCompletionBlock {
    UIView *rootView = [self hostRootView];

    self.hideExpectation = [self expectationWithDescription:@"The hudWasHidden: delegate should have been called."];
    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"The completionBlock: should have been called."];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootView animated:YES];
    hud.delegate = self;
    hud.completionBlock = ^{
        [completionExpectation fulfill];
    };

    [hud hideAnimated:YES];

    [self waitForExpectationsWithTimeout:5. handler:nil];
}

#pragma mark - Modes

- (void)testHUDMatchesNewSuperviewBounds {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 480.f)];
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithFrame:CGRectMake(10.f, 20.f, 40.f, 60.f)];

    [container addSubview:hud];
    XCTAssertTrue(CGRectEqualToRect(hud.frame, container.bounds));

    UIView *otherContainer = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 640.f, 360.f)];
    otherContainer.bounds = CGRectMake(15.f, 25.f, 640.f, 360.f);
    [otherContainer addSubview:hud];
    XCTAssertEqualObjects(hud.superview, otherContainer);
    XCTAssertTrue(CGRectEqualToRect(hud.frame, otherContainer.bounds));

    CGRect frame = hud.frame;
    [hud removeFromSuperview];
    XCTAssertNil(hud.superview);
    XCTAssertTrue(CGRectEqualToRect(hud.frame, frame));
}

- (void)testHUDResizesWithSuperview {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 480.f)];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:container animated:NO];

    // Rotation and scene resizing must not depend on status bar notifications.
    for (NSValue *size in @[[NSValue valueWithCGSize:CGSizeMake(480.f, 320.f)],
                            [NSValue valueWithCGSize:CGSizeMake(240.f, 320.f)]]) {
        container.bounds = (CGRect){CGPointZero, size.CGSizeValue};
        [container layoutIfNeeded];

        XCTAssertTrue(CGRectEqualToRect(hud.frame, container.bounds));
        XCTAssertEqualWithAccuracy(hud.bezelView.center.x, CGRectGetMidX(hud.bounds), 0.5f);
        XCTAssertEqualWithAccuracy(hud.bezelView.center.y, CGRectGetMidY(hud.bounds), 0.5f);
    }

    [hud hideAnimated:NO];
}

- (void)testHUDTracksSceneRotation {
    XCTAssertTrue(NSThread.isMainThread);
    UIView *rootView = [self hostRootView];
    UIWindow *window = rootView.window;
    UIWindowScene *scene = window.windowScene;
    XCTAssertNotNil(scene);
    if (!scene) return;

    NSPredicate *active = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        return scene.activationState == UISceneActivationStateForegroundActive &&
            scene.effectiveGeometry.interfaceOrientation != UIInterfaceOrientationUnknown &&
            window.rootViewController.transitionCoordinator == nil;
    }];
    XCTNSPredicateExpectation *ready = [[XCTNSPredicateExpectation alloc] initWithPredicate:active object:nil];
    XCTWaiterResult readyResult = [XCTWaiter waitForExpectations:@[ready] timeout:5.f];
    XCTAssertEqual(readyResult, XCTWaiterResultCompleted);
    if (readyResult != XCTWaiterResultCompleted) return;

    UIInterfaceOrientation originalOrientation = scene.effectiveGeometry.interfaceOrientation;
    __block MBProgressHUD *hud = nil;
    __weak HudTests *weakSelf = self;
    [self addTeardownBlock:^{
        [hud removeFromSuperview];
        [weakSelf rotateWindow:window toOrientation:originalOrientation];
    }];

    for (UIView *parent in @[rootView, window]) {
        hud = [MBProgressHUD showHUDAddedTo:parent animated:NO];
        CGSize portraitSize = CGSizeZero;
        for (NSNumber *value in @[@(UIInterfaceOrientationPortrait),
                                  @(UIInterfaceOrientationLandscapeLeft),
                                  @(UIInterfaceOrientationPortrait)]) {
            UIInterfaceOrientation orientation = value.integerValue;
            if (![self rotateWindow:window toOrientation:orientation]) return;

            [parent layoutIfNeeded];
            [hud layoutIfNeeded];
            MBTestHUDIsVisible(hud, parent);
            XCTAssertTrue(CGRectEqualToRect(hud.frame, parent.bounds));
            XCTAssertTrue(CGRectEqualToRect(hud.backgroundView.frame, hud.bounds));
            XCTAssertEqualWithAccuracy(hud.bezelView.center.x, CGRectGetMidX(hud.bounds), 0.5f);
            XCTAssertEqualWithAccuracy(hud.bezelView.center.y, CGRectGetMidY(hud.bounds), 0.5f);
            if (UIInterfaceOrientationIsPortrait(orientation)) {
                if (CGSizeEqualToSize(portraitSize, CGSizeZero)) {
                    portraitSize = window.bounds.size;
                } else {
                    XCTAssertEqualWithAccuracy(window.bounds.size.width, portraitSize.width, 0.5f);
                    XCTAssertEqualWithAccuracy(window.bounds.size.height, portraitSize.height, 0.5f);
                }
            } else {
                XCTAssertEqualWithAccuracy(window.bounds.size.width, portraitSize.height, 0.5f);
                XCTAssertEqualWithAccuracy(window.bounds.size.height, portraitSize.width, 0.5f);
            }
            NSLog(@"Scene rotation: host=%@ orientation=%ld window=%@ HUD=%@", NSStringFromClass(parent.class),
                  (long)orientation, NSStringFromCGRect(window.bounds), NSStringFromCGRect(hud.frame));
        }
        [hud removeFromSuperview];
        hud = nil;
    }
}

- (void)testRoundDeterminate {
    UIView *rootView = [self hostRootView];

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:rootView];
    hud.mode = MBProgressHUDModeDeterminate;
    [rootView addSubview:hud];
    [hud showAnimated:NO];

    MBTestHUDIsVisible(hud, rootView);
    XCTAssertNotNil([self view:hud firstSubviewOfClass:[MBRoundProgressView class]]);

    XCTAssertTrue([MBProgressHUD hideHUDForView:rootView animated:NO], @"The HUD should be found and removed.");
    MBTestHUDIsHidenAndRemoved(hud, rootView);
}

- (void)testRoundAnnularDeterminate {
    UIView *rootView = [self hostRootView];

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:rootView];
    hud.mode = MBProgressHUDModeAnnularDeterminate;
    [rootView addSubview:hud];
    [hud showAnimated:NO];

    MBTestHUDIsVisible(hud, rootView);
    XCTAssertNotNil([self view:hud firstSubviewOfClass:[MBRoundProgressView class]]);

    XCTAssertTrue([MBProgressHUD hideHUDForView:rootView animated:NO], @"The HUD should be found and removed.");
    MBTestHUDIsHidenAndRemoved(hud, rootView);
}

- (void)testDeterminateHorizontalBar {
    UIView *rootView = [self hostRootView];

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:rootView];
    hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
    [rootView addSubview:hud];
    [hud showAnimated:NO];

    MBTestHUDIsVisible(hud, rootView);
    XCTAssertNotNil([self view:hud firstSubviewOfClass:[MBBarProgressView class]]);

    XCTAssertTrue([MBProgressHUD hideHUDForView:rootView animated:NO], @"The HUD should be found and removed.");
    MBTestHUDIsHidenAndRemoved(hud, rootView);

}

#pragma mark - Customization

- (void)testBackgroundColorCanBeCleared {
    MBBackgroundView *background = [MBBackgroundView new];
    XCTAssertNil(background.color);
    XCTAssertNil(background.backgroundColor);
    UIBlurEffectStyle blurStyle = background.blurEffectStyle;

    for (NSNumber *value in @[@(MBProgressHUDBackgroundStyleBlur), @(MBProgressHUDBackgroundStyleSolidColor)]) {
        background.style = value.integerValue;
        background.color = UIColor.redColor;
        XCTAssertEqualObjects(background.backgroundColor, UIColor.redColor);
        UIVisualEffectView *effect = (UIVisualEffectView *)[self view:background firstSubviewOfClass:UIVisualEffectView.class];
        background.color = nil;
        XCTAssertNil(background.color);
        XCTAssertNil(background.backgroundColor);
        XCTAssertEqual(background.blurEffectStyle, blurStyle);
        if (background.style == MBProgressHUDBackgroundStyleBlur) {
            XCTAssertNotNil(effect.effect);
            XCTAssertEqual([self view:background firstSubviewOfClass:UIVisualEffectView.class], effect);
        } else {
            XCTAssertNil(effect);
        }
    }

    background.color = UIColor.blueColor;
    background.style = MBProgressHUDBackgroundStyleBlur;
    XCTAssertEqualObjects(background.backgroundColor, UIColor.blueColor);
    background.color = nil;
    background.style = MBProgressHUDBackgroundStyleSolidColor;
    XCTAssertNil(background.backgroundColor);
    background.style = MBProgressHUDBackgroundStyleBlur;
    XCTAssertNil(background.backgroundColor);
    XCTAssertNotNil([self view:background firstSubviewOfClass:UIVisualEffectView.class]);
}

- (void)testButtonBorderTracksColorAppearance {
    UIView *rootView = [self hostRootView];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootView animated:NO];
    [self addTeardownBlock:^{ [hud hideAnimated:NO]; }];
    UIButton *button = hud.button;
    UIColor *dynamicColor = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {
        return traits.userInterfaceStyle == UIUserInterfaceStyleDark ? UIColor.whiteColor : UIColor.blackColor;
    }];
    [button setTitleColor:dynamicColor forState:UIControlStateNormal];

    for (NSNumber *value in @[@(UIUserInterfaceStyleLight), @(UIUserInterfaceStyleDark), @(UIUserInterfaceStyleLight)]) {
        UIUserInterfaceStyle style = value.integerValue;
        UIColor *expected = style == UIUserInterfaceStyleDark ? UIColor.whiteColor : UIColor.blackColor;
        button.overrideUserInterfaceStyle = style;
        NSPredicate *updated = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
            return button.traitCollection.userInterfaceStyle == style && button.layer.borderColor &&
                CGColorEqualToColor(button.layer.borderColor, expected.CGColor);
        }];
        XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:updated object:nil];
        XCTAssertEqual([XCTWaiter waitForExpectations:@[expectation] timeout:2.f], XCTWaiterResultCompleted);
    }

    [button setTitleColor:UIColor.redColor forState:UIControlStateNormal];
    button.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    [button layoutIfNeeded];
    XCTAssertTrue(CGColorEqualToColor(button.layer.borderColor, UIColor.redColor.CGColor));
}

- (void)testButtonBorderTracksControlState {
    MBProgressHUD *hud = [MBProgressHUD new];
    UIButton *button = hud.button;
    [button setTitleColor:UIColor.redColor forState:UIControlStateNormal];
    [button setTitleColor:UIColor.blueColor forState:UIControlStateSelected];
    [button setTitleColor:UIColor.greenColor forState:UIControlStateHighlighted];
    [button setTitleColor:UIColor.grayColor forState:UIControlStateDisabled];
    XCTAssertTrue(CGColorEqualToColor(button.layer.borderColor, UIColor.redColor.CGColor), @"Inactive state colors must not replace the border.");
    button.selected = YES;
    XCTAssertTrue(CGColorEqualToColor(button.layer.borderColor, UIColor.blueColor.CGColor));
    button.selected = NO;
    button.highlighted = YES;
    XCTAssertTrue(CGColorEqualToColor(button.layer.borderColor, UIColor.greenColor.CGColor));
    button.highlighted = NO;
    button.enabled = NO;
    XCTAssertTrue(CGColorEqualToColor(button.layer.borderColor, UIColor.grayColor.CGColor));
    button.enabled = YES;
    XCTAssertTrue(CGColorEqualToColor(button.layer.borderColor, UIColor.redColor.CGColor));
}

- (void)testEffectViewOrderAfterSettingBlurStyle {
    UIView *rootView = [self hostRootView];

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:rootView];

    [hud.bezelView.subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        XCTAssert(![view isKindOfClass:UIVisualEffectView.class] || idx == 0, @"Just the first subview should be a visual effect view.");
    }];

    hud.bezelView.blurEffectStyle = UIBlurEffectStyleDark;

    [hud.bezelView.subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        XCTAssert(![view isKindOfClass:UIVisualEffectView.class] || idx == 0, @"Just the first subview should be a visual effect view even after changing the blurEffectStyle.");
    }];
}

#pragma mark - Delay

- (void)testDelayedHide {
    UIView *rootView = [self hostRootView];

    self.hideExpectation = [self expectationWithDescription:@"The hudWasHidden: delegate should have been called."];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootView animated:NO];
    hud.delegate = self;

    XCTAssertNotNil(hud, @"A HUD should be created.");

    [hud hideAnimated:NO afterDelay:2];

    MBTestHUDIsVisible(hud, rootView);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        MBTestHUDIsVisible(hud, rootView);
    });

    XCTestExpectation *hideCheckExpectation = [self expectationWithDescription:@"Hide check"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // After the grace time passes, the HUD should still not be shown.
        MBTestHUDIsHidenAndRemoved(hud, rootView);
        [hideCheckExpectation fulfill];
    });

    [self waitForExpectationsWithTimeout:5. handler:nil];

    MBTestHUDIsHidenAndRemoved(hud, rootView);
}

- (void)testDelayedHideDoesNotRace {
    // https://github.com/jdg/MBProgressHUD/issues/503
    UIView *rootView = [self hostRootView];

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:rootView];
    [rootView addSubview:hud];

    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:0.3];
    MBTestHUDIsVisible(hud, rootView);

    XCTestExpectation *hideCheckExpectation = [self expectationWithDescription:@"Hide check"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [hud showAnimated:YES];
        [hud hideAnimated:YES afterDelay:0.3];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            MBTestHUDIsHiden(hud, rootView);
            [hideCheckExpectation fulfill];
        });
    });

    [self waitForExpectationsWithTimeout:5. handler:nil];

    [hud removeFromSuperview];
    MBTestHUDIsHidenAndRemoved(hud, rootView);
}

#pragma mark - Ruse

- (void)testNonAnimatedHudReuse {
    UIView *rootView = [self hostRootView];

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:rootView];
    [rootView addSubview:hud];
    [hud showAnimated:NO];

    XCTAssertNotNil(hud, @"A HUD should be created.");

    [hud hideAnimated:NO];
    [hud showAnimated:NO];

    MBTestHUDIsVisible(hud, rootView);

    [hud hideAnimated:NO];
    [hud removeFromSuperview];
}

- (void)testUnfinishedHidingAnimation {
  UIView *rootView = [self hostRootView];

  MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootView animated:NO];

  [hud hideAnimated:YES];

  // Cancel all animations. It will cause `UIView+animate...` to call completionBlock with `finished = NO`.
  // It's same as if you call `[hud hideAnimated:YES]` while the app is in background.
  [hud.bezelView.layer removeAllAnimations];
  [hud.backgroundView.layer removeAllAnimations];

  XCTestExpectation *hideCheckExpectation = [self expectationWithDescription:@"Hide check"];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    // After the grace time passes, the HUD should still not be shown.
    MBTestHUDIsHidenAndRemoved(hud, rootView);
    [hideCheckExpectation fulfill];
  });

  [self waitForExpectationsWithTimeout:5. handler:nil];

  MBTestHUDIsHidenAndRemoved(hud, rootView);
}

- (void)testAnimatedImmediateHudReuse {
    UIView *rootView = [self hostRootView];

    XCTestExpectation *hideExpectation = [self expectationWithDescription:@"The hud should have been hidden."];

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:rootView];
    [rootView addSubview:hud];
    [hud showAnimated:YES];

    XCTAssertNotNil(hud, @"A HUD should be created.");

    [hud hideAnimated:YES];
    [hud showAnimated:YES];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        MBTestHUDIsVisible(hud, rootView);

        [hud hideAnimated:NO];
        [hud removeFromSuperview];

        [hideExpectation fulfill];
    });

    [self waitForExpectationsWithTimeout:5. handler:nil];
}

#pragma mark - Min show time

- (void)testMinShowTime {
    UIView *rootView = [self hostRootView];

    self.hideExpectation = [self expectationWithDescription:@"The hudWasHidden: delegate should have been called."];

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:rootView];
    hud.delegate = self;
    hud.removeFromSuperViewOnHide = YES;
    hud.minShowTime = 2.;
    [rootView addSubview:hud];
    [hud showAnimated:YES];

    XCTAssertNotNil(hud, @"A HUD should be created.");

    [hud hideAnimated:YES];

    __block BOOL checkedAfterOneSecond = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Check that the hud is still visible
        MBTestHUDIsVisible(hud, rootView);
        checkedAfterOneSecond = YES;
    });

    self.hideChecks = ^{
        XCTAssertTrue(checkedAfterOneSecond);
    };

    [self waitForExpectationsWithTimeout:5. handler:nil];

    MBTestHUDIsHidenAndRemoved(hud, rootView);
}

#pragma mark - Grace time

- (void)testGraceTime {
    UIView *rootView = [self hostRootView];

    self.hideExpectation = [self expectationWithDescription:@"The hudWasHidden: delegate should have been called."];

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:rootView];
    hud.delegate = self;
    hud.removeFromSuperViewOnHide = YES;
    hud.graceTime = 2.;
    [rootView addSubview:hud];
    [hud showAnimated:YES];

    XCTAssertNotNil(hud, @"A HUD should be created.");

    // The HUD should be added to the view but still hidden
    XCTAssertEqualObjects(hud.superview, rootView, @"The hud should be added to the view."); \
    XCTAssertEqual(hud.alpha, 0.f, @"The HUD should not be visible."); \
    XCTAssertFalse(hud.hidden, @"The HUD should be visible."); \
    XCTAssertEqual(hud.bezelView.alpha, 0.f, @"The HUD should not be visible."); \


    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // The HUD should be added to the view but still hidden
        XCTAssertEqualObjects(hud.superview, rootView, @"The hud should be added to the view."); \
        XCTAssertEqual(hud.alpha, 0.f, @"The HUD should not be visible."); \
        XCTAssertFalse(hud.hidden, @"The HUD should be visible."); \
        XCTAssertEqual(hud.bezelView.alpha, 0.f, @"The HUD should not be visible."); \
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // After the grace time passes, the HUD should be shown.
        MBTestHUDIsVisible(hud, rootView);
        [hud hideAnimated:YES];
    });

    [self waitForExpectationsWithTimeout:5. handler:nil];

    MBTestHUDIsHidenAndRemoved(hud, rootView);
}

- (void)testHideBeforeGraceTimeElapsed {
    UIView *rootView = [self hostRootView];

    self.hideExpectation = [self expectationWithDescription:@"The hudWasHidden: delegate should have been called."];

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:rootView];
    hud.delegate = self;
    hud.removeFromSuperViewOnHide = YES;
    hud.graceTime = 2.;
    [rootView addSubview:hud];
    [hud showAnimated:YES];

    XCTAssertNotNil(hud, @"A HUD should be created.");

    // The HUD should be added to the view but still hidden
    XCTAssertEqualObjects(hud.superview, rootView, @"The hud should be added to the view."); \
    XCTAssertEqual(hud.alpha, 0.f, @"The HUD should not be visible."); \
    XCTAssertFalse(hud.hidden, @"The HUD should be visible."); \
    XCTAssertEqual(hud.bezelView.alpha, 0.f, @"The HUD should not be visible."); \

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // The HUD should be added to the view but still hidden
        XCTAssertEqualObjects(hud.superview, rootView, @"The hud should be added to the view."); \
        XCTAssertEqual(hud.alpha, 0.f, @"The HUD should not be visible."); \
        XCTAssertFalse(hud.hidden, @"The HUD should be visible."); \
        XCTAssertEqual(hud.bezelView.alpha, 0.f, @"The HUD should not be visible."); \
        [hud hideAnimated:YES];
    });

    XCTestExpectation *hideCheckExpectation = [self expectationWithDescription:@"Hide check"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // After the grace time passes, the HUD should still not be shown.
        MBTestHUDIsHidenAndRemoved(hud, rootView);
        [hideCheckExpectation fulfill];
    });

    [self waitForExpectationsWithTimeout:5. handler:nil];

    MBTestHUDIsHidenAndRemoved(hud, rootView);
}

#pragma mark - Customization

- (void)testShape {
    UIView *rootView = [self hostRootView];

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:rootView];
    hud.removeFromSuperViewOnHide = YES;
    hud.offset = CGPointMake(50, 50);
    hud.square = YES;
    hud.label.text = @"Some long text...";
    [rootView addSubview:hud];
    [hud showAnimated:NO];

    [hud setNeedsLayout];
    [hud layoutIfNeeded];

    CGRect frame = hud.bezelView.frame;
    XCTAssertEqual(frame.size.width, frame.size.height);

    [hud hideAnimated:NO];

    MBTestHUDIsHidenAndRemoved(hud, rootView);
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud {
    if (self.hideChecks) self.hideChecks();
    self.hideChecks = nil;

    [self.hideExpectation fulfill];
    self.hideExpectation = nil;
}

#pragma mark - Helpers

- (BOOL)rotateWindow:(UIWindow *)window toOrientation:(UIInterfaceOrientation)orientation {
    UIWindowScene *scene = window.windowScene;
    UIViewController *controller = window.rootViewController;
    XCTestExpectation *settled = [[XCTestExpectation alloc] initWithDescription:@"The scene must reach a stable target orientation."];
    __block NSError *requestError = nil;
    __block BOOL finished = NO;
    __block BOOL transitionPending = NO;
    __block BOOL transitionCancelled = NO;
    __block id<UIViewControllerTransitionCoordinator> observedCoordinator = nil;
    __block NSArray<NSValue *> *previousGeometry = nil;
    __block NSUInteger stableSamples = 0;

    UIWindowSceneGeometryPreferencesIOS *preferences = [[UIWindowSceneGeometryPreferencesIOS alloc]
        initWithInterfaceOrientations:(UIInterfaceOrientationMask)(1UL << orientation)];
    [scene requestGeometryUpdateWithPreferences:preferences errorHandler:^(NSError *error) {
        if (finished) return;
        requestError = error;
        finished = YES;
        [settled fulfill];
    }];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^(NSTimer *timer) {
        if (finished) return;
        id<UIViewControllerTransitionCoordinator> coordinator = controller.transitionCoordinator;
        if (!coordinator && [controller isKindOfClass:UINavigationController.class]) {
            coordinator = ((UINavigationController *)controller).visibleViewController.transitionCoordinator;
        }
        if (coordinator && coordinator != observedCoordinator) {
            observedCoordinator = coordinator;
            transitionPending = [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                if (finished) return;
                transitionPending = NO;
                transitionCancelled = context.isCancelled;
            }];
            stableSamples = 0;
        }
        [window layoutIfNeeded];
        [controller.view layoutIfNeeded];
        NSArray<NSValue *> *geometry = @[[NSValue valueWithCGRect:window.bounds],
                                         [NSValue valueWithCGRect:controller.view.bounds]];
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            scene.effectiveGeometry.interfaceOrientation == orientation && !transitionPending &&
            window.bounds.size.width > 0.f && window.bounds.size.height > 0.f &&
            [geometry isEqualToArray:previousGeometry]) {
            stableSamples++;
        } else {
            stableSamples = 0;
        }
        previousGeometry = geometry;
        if (stableSamples >= 3) {
            finished = YES;
            [settled fulfill];
        }
    }];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[settled] timeout:5.f];
    finished = YES;
    [timer invalidate];
    XCTAssertNil(requestError, @"Scene request failed: %@", requestError);
    XCTAssertEqual(result, XCTWaiterResultCompleted, @"Target=%ld actual=%ld window=%@", (long)orientation,
                   (long)scene.effectiveGeometry.interfaceOrientation, NSStringFromCGRect(window.bounds));
    XCTAssertFalse(transitionCancelled);
    return result == XCTWaiterResultCompleted && requestError == nil && !transitionCancelled;
}

- (UIView *)hostRootView {
    __block UIView *rootView = nil;
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]] ||
                ![scene.session.role isEqualToString:UIWindowSceneSessionRoleApplication] ||
                (scene.activationState != UISceneActivationStateForegroundActive &&
                 scene.activationState != UISceneActivationStateForegroundInactive) ||
                ![scene.delegate isKindOfClass:[MBHudDemoSceneDelegate class]]) {
                continue;
            }
            UIWindow *window = ((MBHudDemoSceneDelegate *)scene.delegate).window;
            if (window.windowScene == scene && !window.hidden && window.rootViewController) {
                rootView = window.rootViewController.view;
                return YES;
            }
        }
        return NO;
    }];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:nil];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:5.f];
    XCTAssertEqual(result, XCTWaiterResultCompleted, @"The Demo scene must provide a visible host window.");
    XCTAssertNotNil(rootView);
    return rootView;
}

- (void)testSubviewLookup {
    UIView *rootView = [UIView new];
    XCTAssertNil([self view:rootView firstSubviewOfClass:[UILabel class]]);

    UIView *container = [UIView new];
    [rootView addSubview:container];
    XCTAssertNil([self view:rootView firstSubviewOfClass:[UILabel class]]);

    UILabel *label = [UILabel new];
    [container addSubview:label];
    XCTAssertEqual([self view:rootView firstSubviewOfClass:[UILabel class]], label);
}

- (nullable UIView *)view:(UIView *)view firstSubviewOfClass:(Class)clazz {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:clazz]) {
            return subview;
        }
    }
    for (UIView *subview in view.subviews) {
        UIView *theView = [self view:subview firstSubviewOfClass:clazz];
        if (theView) { return theView; }
    }
    return nil;
}

@end

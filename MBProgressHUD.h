//
//  MBProgressHUD.h
//  Version 1.2.0
//  Created by Matej Bukovinski on 2.4.09.
//

// This code is distributed under the terms and conditions of the MIT license.

// Copyright © 2009-2020 Matej Bukovinski
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

@class MBBackgroundView;
@class MBProgressHUD;
@protocol MBProgressHUDDelegate;


extern CGFloat const MBProgressMaxOffset;

typedef NS_ENUM(NSInteger, MBProgressHUDMode) {
    /// UIActivityIndicatorView.
    MBProgressHUDModeIndeterminate,
    /// A round, pie-chart like, progress view.
    MBProgressHUDModeDeterminate,
    /// Horizontal progress bar.
    MBProgressHUDModeDeterminateHorizontalBar,
    /// Ring-shaped progress view.
    MBProgressHUDModeAnnularDeterminate,
    /// Shows a custom view.
    MBProgressHUDModeCustomView,
    /// Shows only labels.
    MBProgressHUDModeText
};

typedef NS_ENUM(NSInteger, MBProgressHUDAnimation) {
    /// Opacity animation
    MBProgressHUDAnimationFade,
    /// Opacity + scale animation (zoom in when appearing zoom out when disappearing)
    MBProgressHUDAnimationZoom,
    /// Opacity + scale animation (zoom out style)
    MBProgressHUDAnimationZoomOut,
    /// Opacity + scale animation (zoom in style)
    MBProgressHUDAnimationZoomIn
};

typedef NS_ENUM(NSInteger, MBProgressHUDBackgroundStyle) {
    /// Solid color background
    MBProgressHUDBackgroundStyleSolidColor,
    /// UIVisualEffectView background view
    MBProgressHUDBackgroundStyleBlur
};

typedef void (^MBProgressHUDCompletionBlock)(void);

/// Called when the user taps the background area of a HUD that has background-tap handling enabled.
/// The tapped HUD instance is passed as the sole argument.
typedef void (^MBProgressHUDBackgroundTapHandler)(MBProgressHUD * _Nonnull hud);


NS_ASSUME_NONNULL_BEGIN


/**
 * Displays a simple HUD window containing a progress indicator and two optional labels for short messages.
 *
 * This is a simple drop-in class for displaying a progress HUD view similar to Apple's private UIProgressHUD class.
 * When added to a superview, the HUD fills its bounds and resizes with it. It catches all user input
 * in this region, thereby preventing user operations on components below the view.
 *
 * @note To still allow touches to pass through the HUD, you can set hud.userInteractionEnabled = NO.
 * @attention MBProgressHUD is a UI class and should therefore only be accessed on the main thread.
 */
@interface MBProgressHUD : UIView

/**
 * Creates a new HUD, adds it to provided view and shows it. The counterpart to this method is hideHUDForView:animated:.
 *
 * @note This method sets removeFromSuperViewOnHide. The HUD will automatically be removed from the view hierarchy when hidden.
 *
 * @param view The view that the HUD will be added to
 * @param animated If set to YES the HUD will appear using the current animationType. If set to NO the HUD will not use
 * animations while appearing.
 * @return A reference to the created HUD.
 *
 * @see hideHUDForView:animated:
 * @see animationType
 */
+ (instancetype)showHUDAddedTo:(UIView *)view animated:(BOOL)animated;

/// @name Showing and hiding

/**
 * Finds the top-most HUD subview that hasn't finished and hides it. The counterpart to this method is showHUDAddedTo:animated:.
 *
 * @note This method sets removeFromSuperViewOnHide. The HUD will automatically be removed from the view hierarchy when hidden.
 *
 * @param view The view that is going to be searched for a HUD subview.
 * @param animated If set to YES the HUD will disappear using the current animationType. If set to NO the HUD will not use
 * animations while disappearing.
 * @return YES if a HUD was found and removed, NO otherwise.
 *
 * @see showHUDAddedTo:animated:
 * @see animationType
 */
+ (BOOL)hideHUDForView:(UIView *)view animated:(BOOL)animated;

/**
 * Finds the top-most HUD subview that hasn't finished and returns it.
 *
 * @param view The view that is going to be searched.
 * @return A reference to the last HUD subview discovered.
 */
+ (nullable MBProgressHUD *)HUDForView:(UIView *)view NS_SWIFT_NAME(forView(_:));

/**
 * Returns the nearest HUD of the receiving class, starting with view itself and walking up its superviews.
 * Unlike HUDForView:, this method does not search subviews or filter out hidden or finished HUDs.
 * Call on the main thread. This method does not change the view hierarchy or HUD state.
 *
 * @param view The view whose enclosing HUD is requested. Must not be nil.
 * @return The nearest matching HUD, or nil if no matching ancestor exists.
 */
+ (nullable instancetype)HUDContainingView:(UIView *)view NS_SWIFT_NAME(containingView(_:));

/**
 * A convenience constructor that initializes the HUD with the view's bounds. Calls the designated constructor with
 * view.bounds as the parameter.
 *
 * @param view The view instance that will provide the bounds for the HUD. Should be the same instance as
 * the HUD's superview (i.e., the view that the HUD will be added to).
 */
- (instancetype)initWithView:(UIView *)view;

/**
 * Displays the HUD.
 *
 * @note You need to make sure that the main thread completes its run loop soon after this method call so that
 * the user interface can be updated. Call this method when your task is already set up to be executed in a new thread
 * (e.g., when using something like NSOperation or making an asynchronous call like NSURLRequest).
 *
 * @param animated If set to YES the HUD will appear using the current animationType. If set to NO the HUD will not use
 * animations while appearing.
 *
 * @see animationType
 */
- (void)showAnimated:(BOOL)animated;

/**
 * Hides the HUD. This still calls the hudWasHidden: delegate. This is the counterpart of the show: method. Use it to
 * hide the HUD when your task completes.
 *
 * @param animated If set to YES the HUD will disappear using the current animationType. If set to NO the HUD will not use
 * animations while disappearing.
 *
 * @see animationType
 */
- (void)hideAnimated:(BOOL)animated;

/**
 * Hides the HUD after a delay. This still calls the hudWasHidden: delegate. This is the counterpart of the show: method. Use it to
 * hide the HUD when your task completes.
 *
 * @param animated If set to YES the HUD will disappear using the current animationType. If set to NO the HUD will not use
 * animations while disappearing.
 * @param delay Delay in seconds until the HUD is hidden.
 *
 * @see animationType
 */
- (void)hideAnimated:(BOOL)animated afterDelay:(NSTimeInterval)delay;

/**
 * The HUD delegate object. Receives HUD state notifications.
 */
@property (weak, nonatomic) id<MBProgressHUDDelegate> delegate;

/**
 * Called after the HUD is hidden.
 */
@property (copy, nullable) MBProgressHUDCompletionBlock completionBlock;

/**
 * Grace period is the time (in seconds) that the invoked method may be run without
 * showing the HUD. If the task finishes before the grace time runs out, the HUD will
 * not be shown at all.
 * This may be used to prevent HUD display for very short tasks.
 * Defaults to 0 (no grace time).
 * @note The graceTime needs to be set before the hud is shown. You thus can't use `showHUDAddedTo:animated:`,
 * but instead need to alloc / init the HUD, configure the grace time and than show it manually.
 */
@property (assign, nonatomic) NSTimeInterval graceTime;

/**
 * The minimum time (in seconds) that the HUD is shown.
 * This avoids the problem of the HUD being shown and than instantly hidden.
 * Defaults to 0 (no minimum show time).
 */
@property (assign, nonatomic) NSTimeInterval minShowTime;

/**
 * Removes the HUD from its parent view when hidden.
 * Defaults to NO.
 */
@property (assign, nonatomic) BOOL removeFromSuperViewOnHide;

/**
 * Called each time the user taps the background area (outside the bezel).
 * The bezel and its content are excluded regardless of their userInteractionEnabled state.
 * The HUD must be displayed and not already requested to hide. Remote-control presses are excluded.
 * Setting userInteractionEnabled = NO on the HUD prevents touches from reaching its subviews.
 * Defaults to nil, which disables the internal tap recognizer. This property may be changed at any time;
 * the block active when the tap is recognized is called on the main thread with the HUD as its argument.
 * Configure it on the main thread. The block is retained when the HUD is hidden and reused.
 * Multiple taps can invoke the block, including while a delayed hide has not yet been requested.
 * The HUD does not automatically hide or cancel the underlying task or progress. The block may call
 * hideAnimated: on its argument; use completionBlock or the delegate to observe dismissal completion.
 * @warning To avoid a retain cycle, do not strongly capture the HUD or the object that owns it.
 *   Use the block argument or a weak reference instead.
 */
@property (copy, nonatomic, nullable) MBProgressHUDBackgroundTapHandler backgroundTapHandler;

/// @name Appearance

/**
 * MBProgressHUD operation mode. The default is MBProgressHUDModeIndeterminate.
 */
@property (assign, nonatomic) MBProgressHUDMode mode;

/**
 * A color that gets forwarded to all labels and supported indicators. Also sets the tintColor
 * for custom views. Set to nil to manage color individually.
 * Defaults to labelColor with an alpha of 0.7, adapting to the current appearance.
 */
@property (strong, nonatomic, nullable) UIColor *contentColor UI_APPEARANCE_SELECTOR;

/**
 * The animation type that should be used when the HUD is shown and hidden.
 */
@property (assign, nonatomic) MBProgressHUDAnimation animationType UI_APPEARANCE_SELECTOR;

/**
 * The bezel offset relative to the center of the view. You can use MBProgressMaxOffset
 * and -MBProgressMaxOffset to move the HUD all the way to the screen edge in each direction.
 * E.g., CGPointMake(0.f, MBProgressMaxOffset) would position the HUD centered on the bottom edge.
 */
@property (assign, nonatomic) CGPoint offset UI_APPEARANCE_SELECTOR;

/**
 * The amount of space between the HUD edge and the HUD elements (labels, indicators or custom views).
 * This also represents the minimum bezel distance to the edge of the HUD view.
 * Defaults to 20.f
 */
@property (assign, nonatomic) CGFloat margin UI_APPEARANCE_SELECTOR;

/**
 * The minimum size of the HUD bezel. Defaults to CGSizeZero (no minimum size).
 */
@property (assign, nonatomic) CGSize minSize UI_APPEARANCE_SELECTOR;

/**
 * Force the HUD dimensions to be equal if possible.
 */
@property (assign, nonatomic, getter = isSquare) BOOL square UI_APPEARANCE_SELECTOR;

/**
 * When enabled, the bezel center gets slightly affected by the device accelerometer data.
 * Defaults to NO.
 *
 * @note This can cause main thread checker assertions on certain devices. https://github.com/jdg/MBProgressHUD/issues/552
 */
@property (assign, nonatomic, getter=areDefaultMotionEffectsEnabled) BOOL defaultMotionEffectsEnabled UI_APPEARANCE_SELECTOR;

/// @name Progress

/**
 * The progress of the progress indicator, from 0.0 to 1.0. Defaults to 0.0.
 */
@property (assign, nonatomic) float progress;

/// @name ProgressObject

/**
 * The NSProgress object feeding the progress information to the progress indicator.
 */
@property (strong, nonatomic, nullable) NSProgress *progressObject;

/// @name Views

/**
 * The view containing the labels and indicator (or customView).
 */
@property (strong, nonatomic, readonly) MBBackgroundView *bezelView;

/**
 * View covering the entire HUD area, placed behind bezelView.
 */
@property (strong, nonatomic, readonly) MBBackgroundView *backgroundView;

/**
 * The UIView (e.g., a UIImageView) to be shown when the HUD is in MBProgressHUDModeCustomView.
 * The view should implement intrinsicContentSize for proper sizing. For best results use approximately 37 by 37 pixels.
 */
@property (strong, nonatomic, nullable) UIView *customView;

/**
 * A label that holds an optional short message to be displayed below the activity indicator. The HUD is automatically resized to fit
 * the entire text.
 */
@property (strong, nonatomic, readonly) UILabel *label;

/**
 * A label that holds an optional details message displayed below the labelText message. The details text can span multiple lines.
 */
@property (strong, nonatomic, readonly) UILabel *detailsLabel;

/**
 * A button that is placed below the labels. Visible only if a target / action is added and a title is assigned..
 * Its border follows the current title color, including control state and color appearance changes.
 */
@property (strong, nonatomic, readonly) UIButton *button;

@end


@protocol MBProgressHUDDelegate <NSObject>

@optional

/**
 * Called after the HUD was fully hidden from the screen.
 */
- (void)hudWasHidden:(MBProgressHUD *)hud;

@end


/**
 * A progress view for showing definite progress by filling up a circle (pie chart).
 */
@interface MBRoundProgressView : UIView

/**
 * Progress (0.0 to 1.0)
 */
@property (nonatomic, assign) float progress;

/**
 * Indicator progress color.
 * Defaults to white [UIColor whiteColor].
 */
@property (nonatomic, strong) UIColor *progressTintColor;

/**
 * Indicator background (non-progress) color.
 * Defaults to translucent white (alpha 0.1).
 */
@property (nonatomic, strong) UIColor *backgroundTintColor;

/*
 * Display mode - NO = round or YES = annular. Defaults to round.
 */
@property (nonatomic, assign, getter = isAnnular) BOOL annular;

@end


/**
 * A flat bar progress view.
 */
@interface MBBarProgressView : UIView

/**
 * Progress (0.0 to 1.0)
 */
@property (nonatomic, assign) float progress;

/**
 * Bar border line color.
 * Defaults to white [UIColor whiteColor].
 */
@property (nonatomic, strong) UIColor *lineColor;

/**
 * Bar background color.
 * Defaults to clear [UIColor clearColor];
 */
@property (nonatomic, strong) UIColor *progressRemainingColor;

/**
 * Bar progress color.
 * Defaults to white [UIColor whiteColor].
 */
@property (nonatomic, strong) UIColor *progressColor;

@end


@interface MBBackgroundView : UIView

/**
 * The background style.
 * Defaults to MBProgressHUDBackgroundStyleBlur.
 */
@property (nonatomic) MBProgressHUDBackgroundStyle style;

/**
 * The blur effect style, when using MBProgressHUDBackgroundStyleBlur.
 * Defaults to UIBlurEffectStyleRegular on tvOS and UIBlurEffectStyleSystemThickMaterial
 * on iOS and Mac Catalyst.
 */
@property (nonatomic) UIBlurEffectStyle blurEffectStyle;

/**
 * The background color or the blur tint color.
 *
 * Defaults to nil.
 * Setting nil clears the fill color in solid mode or the custom tint in blur mode, preserving the blur effect.
 */
@property (nonatomic, strong, nullable) UIColor *color;

@end

NS_ASSUME_NONNULL_END

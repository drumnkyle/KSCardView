/**
 The MIT License (MIT)
 
 Copyright (c) 2013 Kyle Sherman
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 File:
	KSCardView.h
 
 Author:
	Kyle Sherman
*/

#import <UIKit/UIKit.h>

/**
 @brief Parameter used to specify how far the card must be dragged for the card
 to leave the left or right edge.
 @remark Recommended value is 65.
*/
#define kHorizontalEdgeOffset   65

/**
 @brief Parameter used to specify how far the card must be dragged for the card
 to leave the top or bottom edge.
 @remark Recommended value is 65.
*/
#define kVerticalEdgeOffset     65

/**
 @brief Paramter used to specify how far past the resting point, the rubber band
 animation will go in the first pass.
 @remark Recommended value is 25.
*/
#define kRubberBandFirstPass    25

/**
 @brief Paramter used to specify how far past the resting point, the rubber band
 animation will go in the second pass.
 @remark Recommended value is 10.
 */
#define kRubberBandSecondPass   10

/**
 @brief Parameter stating the duration of the rubber band animation.
 @remark Recommended value is 0.75f.
*/
#define kRubberBandDuration     0.75f

/**
 @brief Parameter stating the duration of the card leaving animation.
 @remark Recommended value is 0.5f.
*/
#define kCardLeavesDuration     0.5f

/**
 @brief Rotation factor that controls how many degrees the rotation is.
 @detail This is a ratio; make this 1.0f for full rotation and less than 1 for
 less rotation.
 @remark Recommended value is 0.25f.
*/
#define kRotationFactor         0.25f

/**
 @brief Opacity factor that controls how quickly the opacity increases when overlay
 is fading in.
 @detail This is a ratio; make this 1.0f for a rapid change and less than 1 for
 a less quick transition.
 @remark Recommended value is 0.5f
*/
#define kOverlayOpacityFactor   0.5f

/**
 @brief Opacity factor that controls how quickly the opacity descreases when the
 view is dragged in any direction when there is an overlay present.
 @detail This is a ratio; make this greater than 1.0f for a rapid change and 
 less than 1 for a less quick transition.
 @remark Recommended value is 0.15f.
*/
#define kViewOpacityFactor      0.15f

/**
 @brief Opacity factor that controls how quickly the opacity descreases when the
 view is dragged to the left or right during the rotation animation.
 @detail This is a ratio; make this greater than 1.0f for a rapid change and
 less than 1 for a less quick transition.
 @remark Recommended value is 0.5f.
 */
#define kViewRotationOpacityFactor      0.5f

/**
 @brief This is the amount of degrees that the view starts at when it is being
 shown from the left or right.
 @remark Recommended value is 60.
 @see showFromLeft
 @see showFromRight
*/
#define kStartRotation          60


@protocol KSCardViewDelegate;


@interface KSCardView : UIView

/**
 @brief The delegate of the view. Ensure that you set this delegate so that you
 can perform functions when the cards leaves the screen.
*/
@property (nonatomic, weak) id <KSCardViewDelegate> delegate;

/**
 @brief A flag that can be set to not allow the view to be moved to the left.
*/
@property (nonatomic, assign) BOOL allowLeft;

/**
 @brief A flag that can be set to not allow the view to be moved to the right.
*/
@property (nonatomic, assign) BOOL allowRight;

/**
 @brief A flag that can be set to not allow the view to be moved to the top.
*/
@property (nonatomic, assign) BOOL allowUp;

/**
 @brief A flag that can be set to not allow the view to be moved to the bottom.
*/
@property (nonatomic, assign) BOOL allowDown;

/**
 @pre setCardViewFrame
 @brief This method initializes an instance of the class KSCardView. You must
 set the card view's frame before initializing. 
 @warning This is the only valid way to initialize an instance of a KSCardView.
 Others will throw an exception.
 @throws No Frame Specified
*/
- (instancetype)init;

/**
 @brief Sets the frame for every instance of KSCardView. This is a factory function.
 @param frame The frame to set as the KSCardView frame.
 @note This must be done before creating any instances of the KSCardView.
 @post Call the init function for each instance.
*/
+ (void)setCardViewFrame:(CGRect)frame;

/**
 @brief Sets the overlay views for each direction; nil can be specified if an
 overlay is not desired in a specific direction. This is a factory function.
 @param leftOverlay The view to be overlayed when the card view is dragged to 
 the left.
 @param rightOverlay The view to be overlayed when the card view is dragged to
 the right.
 @param upOverlay The view to be overlayed when the card view is dragged to
 the top.
 @param downOverlay The view to be overlayed when the card view is dragged to
 the bottom.
 @note This is done once and should be set up before creating any instances
 of the KSCardView. If this function is not called, all overlays will be nil;
 the KSCardView will still work.
*/
+ (void)setOverlayLeft:(UIView *)leftOverlay right:(UIView *)rightOverlay
                    up:(UIView *)upOverlay down:(UIView *)downOverlay;

/**
 @brief Presents the card from the left side of the screen. Opacity increases
 from 0 and rotation starts from -kStartRotation degrees to 0.
 @see kStartRotation
*/
- (void)showFromLeft;

/**
 @brief Presents the card from the right side of the screen. Opacity increases
 from 0 and rotation starts from kStartRotation degrees to 0.
 @see kStartRotation
*/
- (void)showFromRight;

/**
 @brief Presents the card from the top of the screen. Opacity increases
 from 0 to 1.
*/
- (void)showFromTop;

/**
 @brief Presents the card from the bottom of the screen. Opacity increases
 from 0 to 1.
*/
- (void)showFromBottom;

/**
 @pre Demo must be reset using demoReset.
 @brief Moves the card from the center of the screen upwards and performs the
 same animation as if someone dragged it. This can be used to demo the functionality
 to the user and explain what it does.
*/
- (void)demoUp;

/**
 @pre Demo must be reset using demoReset.
 @brief Moves the card from the center of the screen downwards and performs the
 same animation as if someone dragged it. This can be used to demo the functionality
 to the user and explain what it does.
*/
- (void)demoDown;

/**
 @pre Demo must be reset using demoReset.
 @brief Moves the card from the center of the screen to the left and performs the
 same animation as if someone dragged it. This can be used to demo the functionality
 to the user and explain what it does.
*/
- (void)demoLeft;

/**
 @pre Demo must be reset using demoReset.
 @brief Moves the card from the center of the screen to the right and performs the
 same animation as if someone dragged it. This can be used to demo the functionality
 to the user and explain what it does.
*/
- (void)demoRight;

/**
 @brief Reset card to it's starting position after a demo.
*/
- (void)demoReset;

/**
 @brief Make card leave the screen to the left. This will also call the delegate method. Allows the
 developer to control the card programmatically.
*/
- (void)leaveLeft;

/**
 @brief Make card leave the screen to the right. This will also call the delegate method. Allows the
 developer to control the card programmatically.
*/
- (void)leaveRight;

/**
 @brief Make card leave the screen at the top. This will also call the delegate method. Allows the
 developer to control the card programmatically.
*/
- (void)leaveTop;

/**
 @brief Make card leave the screen at the bottom. This will also call the delegate method. Allows the
 developer to control the card programmatically.
*/
- (void)leaveBottom;

@end

@protocol KSCardViewDelegate

/**
 @brief Callback delegate function that is called when the card leaves the top
 of the screen.
 @param cardView The card view that has left the screen.
 @see kVerticalEdgeOffset
*/
- (void)cardDidLeaveTopEdge:(KSCardView *)cardView;

/**
 @brief Callback delegate function that is called when the card leaves the bottom
 of the screen.
 @param cardView The card view that has left the screen.
 @see kVerticalEdgeOffset
*/
- (void)cardDidLeaveBottomEdge:(KSCardView *)cardView;

/**
 @brief Callback delegate function that is called when the card leaves the left
 side of the screen.
 @param cardView The card view that has left the screen.
 @see kHorizontalEdgeOffset
*/
- (void)cardDidLeaveLeftEdge:(KSCardView *)cardView;

/**
 @brief Callback delegate function that is called when the card leaves the right
 side of the screen.
 @param cardView The card view that has left the screen.
 @see kHorizontalEdgeOffset
*/
- (void)cardDidLeaveRightEdge:(KSCardView *)cardView;

@end
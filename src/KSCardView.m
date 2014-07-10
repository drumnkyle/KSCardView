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
	KSCardView.m
 
 Author:
	Kyle Sherman
*/

#import "KSCardView.h"

typedef NS_ENUM(NSUInteger, Direction)
{
    DirectionUp,
    DirectionDown,
    DirectionLeft,
    DirectionRight,
    
    DirectionCount
};

typedef NS_ENUM(NSUInteger, ViewTags)
{
    ViewTagUpImage = 1,
    ViewTagDownImage,
    ViewTagLeftImage,
    ViewTagRightImage,
};

__strong static UIView *s_overlayContainer = nil;
static CGRect s_cardFrame = { 0 };
static BOOL s_hasLeftOverlay = NO;
static BOOL s_hasRightOverlay = NO;
static BOOL s_hasUpOverlay = NO;
static BOOL s_hasDownOverlay = NO;

@interface KSCardView ()
{
	CGContextRef _ctx;
}

@property (nonatomic, assign) CGRect originalRect;
@property (nonatomic, assign) CGPoint originalCenter;
@property (nonatomic, assign) NSUInteger touchCount;
@property (nonatomic, assign) CGPoint shift;
@property (nonatomic, assign) CGFloat antiShift;
@property (nonatomic, assign) BOOL firstEdgeHit;
@property (nonatomic, assign) BOOL moveLaterally;
@property (nonatomic, assign) NSUInteger lastDirection;

+ (void)_addOverlay:(UIView *)image withDirection:(NSUInteger)direction;
- (void)_rubberBand;
- (void)_hideViewOverlays;
- (void)_cardLeaves:(NSUInteger)direction;
- (void)_showOverlayWithDirection:(NSUInteger)direction currentLocation:(CGPoint)currentLoc
        previousLocation:(CGPoint)prevLoc;
- (void)_resetRotation:(NSUInteger)direction;
- (void)_changeViewOpacityForDirection:(NSUInteger)direction;
@end

@implementation KSCardView

+ (void)setCardViewFrame:(CGRect)frame
{
    s_cardFrame = frame;
    s_overlayContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, s_cardFrame.size.width, s_cardFrame.size.height)];
}

+ (void)setOverlayLeft:(UIView *)leftOverlay right:(UIView *)rightOverlay
                    up:(UIView *)upOverlay down:(UIView *)downOverlay
{
    [KSCardView _addOverlay:leftOverlay withDirection:DirectionLeft];
    [KSCardView _addOverlay:rightOverlay withDirection:DirectionRight];
    [KSCardView _addOverlay:upOverlay withDirection:DirectionUp];
    [KSCardView _addOverlay:downOverlay withDirection:DirectionDown];
}

#pragma mark - Initializers
- (instancetype)initWithFrame:(CGRect)frame
{
    NSString *desc = @"You must call +setCardViewFrame followed by -init";
    [NSException raise:@"Invalid Initalizer" format:@"%@", desc];
    return nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    NSString *desc = @"You must call +setCardViewFrame followed by -init";
    [NSException raise:@"Invalid Initalizer" format:@"%@", desc];
    return nil;
}

#pragma mark Designated Initializer
- (instancetype)init
{
    if (s_cardFrame.size.height == 0.0f && s_cardFrame.size.width == 0.0f)
    {
        NSString *desc = @"You must call +setCardViewFrame first in order to "
        "initialize this object";
        [NSException raise:@"No Frame Specified" format:@"%@", desc];
    }
    self.originalRect = s_cardFrame;
    self = [super initWithFrame:self.originalRect];
    if (self)
    {
        self.allowUp = YES, self.allowDown = YES, self.allowLeft = YES, self.allowRight = YES;
        self.originalCenter = self.center;
        self.antiShift = 0.0f;
        self.lastDirection = DirectionCount;
        self.multipleTouchEnabled = YES;
        self.firstEdgeHit = YES;
    }
    return self;
}

#pragma mark - Presentation
- (void)showFromLeft
{
    // Based on frame, start with frame offscreen
    // Start with it rotated
    // Start with opacity at 0.
    self.layer.opacity = 0.0f;
    self.center = CGPointMake(-self.frame.size.width / 2, self.superview.center.y);
    self.transform = CGAffineTransformMakeRotation(-kStartRotation * M_PI / 180);
    [UIView animateWithDuration:0.5f animations:^{
        self.layer.opacity = 1.0f;
        self.transform = CGAffineTransformMakeRotation(0);
        self.center = self.originalCenter;
    }];
}

- (void)showFromRight
{
    self.layer.opacity = 0.0f;
    self.center = CGPointMake(1.5 * self.frame.size.width, self.superview.center.y);
    self.transform = CGAffineTransformMakeRotation(kStartRotation * M_PI / 180);
    [UIView animateWithDuration:0.5f animations:^{
        self.layer.opacity = 1.0f;
        self.transform = CGAffineTransformMakeRotation(0);
        self.center = self.originalCenter;
    }];
}

- (void)showFromTop
{
    self.layer.opacity = 0.0f;
    self.center = CGPointMake(self.superview.center.x, -self.superview.frame.size.height / 2);
    [UIView animateWithDuration:0.5f animations:^{
        self.layer.opacity = 1.0f;
        self.center = self.originalCenter;
    }];
}

- (void)showFromBottom
{
    self.layer.opacity = 0.0f;
    self.center = CGPointMake(self.superview.center.x, 1.5 * self.superview.frame.size.height);
    [UIView animateWithDuration:0.5f animations:^{
        self.layer.opacity = 1.0f;
        self.center = self.originalCenter;
    }];
}

#pragma mark - Demo Methods
- (void)demoUp
{
	// Shift the view upwards at a steady pace
	CGPoint demoShift = CGPointMake(self.center.x, kVerticalEdgeOffset);
	[self addSubview:s_overlayContainer];
	UIView *sub = nil;
	for (sub in [s_overlayContainer subviews])
	{
		if (sub.tag == ViewTagUpImage)
		{
			break;
		}
	}

	[UIView animateWithDuration:1.5f animations:^{
		self.center = demoShift;
		self.alpha = 0.5f;
		if (sub)
			sub.alpha = 1.0f;
	}];
}

- (void)demoDown
{
	// Shift the view downwards at a steady pace
	CGPoint demoShift = CGPointMake(self.center.x, self.superview.frame.size.height - kVerticalEdgeOffset);
	[self addSubview:s_overlayContainer];
	UIView *sub = nil;
	for (sub in [s_overlayContainer subviews])
	{
		if (sub.tag == ViewTagDownImage)
		{
			break;
		}
	}
	
	[UIView animateWithDuration:1.5f animations:^{
		self.center = demoShift;
		self.alpha = 0.5f;
		if (sub)
			sub.alpha = 1.0f;
	}];
}

- (void)demoLeft
{
	// Shift the view to the left at a steady pace
	CGPoint demoShift = CGPointMake(kHorizontalEdgeOffset, self.center.y);
	UIView *sub = nil;
	if (s_hasLeftOverlay)
	{
		[self addSubview:s_overlayContainer];
		for (sub in [s_overlayContainer subviews])
		{
			if (sub.tag == ViewTagLeftImage)
			{
				break;
			}
		}
	}
	
	[UIView animateWithDuration:1.5f animations:^{
		self.center = demoShift;
		self.alpha = 0.5f;
		if (s_hasLeftOverlay)
		{
			if (sub)
				sub.alpha = 1.0f;
		}
		else
		{
			self.transform = CGAffineTransformMakeRotation(-kStartRotation * M_PI * kRotationFactor / 180);
		}
	}];
}

- (void)demoRight
{
	// Shift the view to the right at a steady pace
	CGPoint demoShift = CGPointMake(self.superview.frame.size.width - kHorizontalEdgeOffset, self.center.y);
	UIView *sub = nil;
	if (s_hasRightOverlay)
	{
		[self addSubview:s_overlayContainer];
		for (sub in [s_overlayContainer subviews])
		{
			if (sub.tag == ViewTagRightImage)
			{
				break;
			}
		}
	}
	
	[UIView animateWithDuration:1.5f animations:^{
		self.center = demoShift;
		self.alpha = 0.5f;
		if (s_hasRightOverlay)
		{
			if (sub)
				sub.alpha = 1.0f;
		}
		else
		{
			self.transform = CGAffineTransformMakeRotation(kStartRotation * M_PI * kRotationFactor / 180);
		}
	}];
}

- (void)demoReset
{
	[UIView animateWithDuration:0.25f animations:^{
		self.center = self.originalCenter;
		self.alpha = 1.0f;
		self.transform = CGAffineTransformMakeRotation(0);
		for (UIView *view in [s_overlayContainer subviews])
		{
			switch (view.tag)
			{
				case ViewTagUpImage:
				case ViewTagDownImage:
				case ViewTagLeftImage:
				case ViewTagRightImage:
					view.alpha = 0.0f;
					break;
				default:
					break;
			}
		}
	}];
}

#pragma mark - Touch Handlers
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.count == 1)
    {
		self.touchCount = 0;
		[self addSubview:s_overlayContainer];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.count == 1)
    {
        self.touchCount++;
        if (self.touchCount == 3)
        {
            // Decide whether you are translating laterally or vertically
            if (abs(self.center.x - self.originalCenter.x) >
                abs(self.center.y - self.originalCenter.y))
                self.moveLaterally = YES;
            else
                self.moveLaterally = NO;
            
            self.firstEdgeHit = YES;
        }
		
        UITouch *touch = [[touches allObjects] firstObject];
        CGPoint center = self.center;
        CGPoint currentLoc = [touch locationInView:self];
        CGPoint prevLoc = [touch previousLocationInView:self];

        if (self.touchCount < 3)
        {
            center.x += (currentLoc.x - prevLoc.x);
            center.y += (currentLoc.y - prevLoc.y);
        }
        else // self.touchCount >= 3
        {
            if (self.moveLaterally)
            {
                if (currentLoc.x - prevLoc.x < 0.0f && !self.allowLeft)
                    return;
                else if (currentLoc.x - prevLoc.x > 0.0f && !self.allowRight)
                    return;
                center.x += (currentLoc.x - prevLoc.x);
            }
            else
            {
                if (currentLoc.y - prevLoc.y < 0.0f && !self.allowUp)
                    return;
                else if (currentLoc.y - prevLoc.y > 0.0f && !self.allowDown)
                    return;
                center.y += (currentLoc.y - prevLoc.y);
            }
        }
        
        self.center = center;
        
        // Rotate card outwards if moving laterally and edge has crossed border
        if (self.moveLaterally)
        {
            // Right Edge
            if ((self.center.x + self.frame.size.width / 2) >
                self.superview.frame.size.width)
            {
                [self _resetRotation:DirectionRight];
				self.lastDirection = DirectionRight;
				if (self.firstEdgeHit)
                {
                    self.firstEdgeHit = NO;
                    self.shift = CGPointMake(0, 0);
                }
				_shift.x += (currentLoc.x - prevLoc.x);
                [self _changeViewOpacityForDirection:DirectionRight];
                if (s_hasRightOverlay)
                {
                    [self _showOverlayWithDirection:DirectionRight currentLocation:currentLoc previousLocation:prevLoc];
                    // Don't do rotation if there is an image
                    // TODO: Maybe have another bool to override and still rotate?
                    return;
                }
                // Rotate to the right
				self.transform = CGAffineTransformMakeRotation(kRotationFactor * _shift.x * M_PI / 180);
            }
            // Left Edge
            else if ((self.center.x - self.frame.size.width / 2) < 0)
            {
                [self _resetRotation:DirectionLeft];
				self.lastDirection = DirectionLeft;
				if (self.firstEdgeHit)
                {
                    self.firstEdgeHit = NO;
                    self.shift = CGPointMake(0, 0);
                }
				_shift.x += (currentLoc.x - prevLoc.x);
                [self _changeViewOpacityForDirection:DirectionLeft];
                if (s_hasLeftOverlay)
                {
                    [self _showOverlayWithDirection:DirectionLeft currentLocation:currentLoc previousLocation:prevLoc];
                    // Don't do rotation if there is an image
                    return;
                }
                // Rotate to the left
                self.transform = CGAffineTransformMakeRotation(kRotationFactor * _shift.x * M_PI / 180);
            }
            else
            {
                self.transform = CGAffineTransformMakeRotation(0);
                self.layer.opacity = 1.0f;
                [self _hideViewOverlays];
            }
        }
        else // !_moveLaterally
        {
            // Bottom Edge
            if ((self.center.y + self.frame.size.height / 2) >
                self.superview.frame.size.height)
            {
				if (self.firstEdgeHit)
                {
                    self.firstEdgeHit = NO;
                    self.shift = CGPointMake(0, 0);
                }
				_shift.y += (currentLoc.y - prevLoc.y);
                [self _changeViewOpacityForDirection:DirectionDown];
                [self _showOverlayWithDirection:DirectionDown currentLocation:currentLoc
                      previousLocation:prevLoc];
            }
            // Top Edge
            else if ((self.center.y - self.frame.size.height / 2) < 0)
            {
				if (self.firstEdgeHit)
                {
                    self.firstEdgeHit = NO;
                    self.shift = CGPointMake(0, 0);
                }
				_shift.y += (currentLoc.y - prevLoc.y);
				[self _changeViewOpacityForDirection:DirectionUp];
                [self _showOverlayWithDirection:DirectionUp currentLocation:currentLoc previousLocation:prevLoc];
            }
            else
            {
                [self _hideViewOverlays];
            }
        }
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.count == 1)
    {
        self.touchCount = 0;
        self.firstEdgeHit = YES;
        // If the edge is past the border, do something
        // Otherwise, snap back to original location
        CGSize superSize = self.superview.frame.size;
        
        BOOL outRight = NO, outLeft = NO, outTop = NO, outBottom = NO;
        
        // Right edge
        if (self.center.x > (superSize.width - kHorizontalEdgeOffset))
        {
            outRight = YES;
            [self _cardLeaves:DirectionRight];
            return [self.delegate cardDidLeaveRightEdge:self];
        }
        else if ((self.center.x - kHorizontalEdgeOffset) < 0.0f)
        {
            outLeft = YES;
            [self _cardLeaves:DirectionLeft];
            return [self.delegate cardDidLeaveLeftEdge:self];
        }
        else if (self.center.y > (superSize.height - kVerticalEdgeOffset))
        {
            outBottom = YES;
            [self _cardLeaves:DirectionDown];
            return [self.delegate cardDidLeaveBottomEdge:self];
        }
        else if ((self.center.y - kVerticalEdgeOffset) < 0.0f)
        {
            outTop = YES;
            [self _cardLeaves:DirectionUp];
            return [self.delegate cardDidLeaveTopEdge:self];
        }
        
        // Bouce back
        if (!outRight && !outLeft && !outTop && !outBottom)
        {
            [self _rubberBand];
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.count == 1)
    {
        self.touchCount = 0;
        self.firstEdgeHit = YES;
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	for (UIView *view in self.subviews)
	{
		if ([view isKindOfClass:[UIScrollView class]])
		{
			if ([view pointInside:point withEvent:event])
			{
				return [view hitTest:point withEvent:event];
			}
		}
	}
	
	return [super hitTest:point withEvent:event];
}

#pragma mark - Internal Functions
+ (void)_addOverlay:(UIView *)overlay withDirection:(NSUInteger)direction
{
    if (!overlay)
        return;
    
    NSUInteger viewTag;
    
    switch (direction)
    {
        case DirectionLeft:
            s_hasLeftOverlay = YES;
            viewTag = ViewTagLeftImage;
            break;
        case DirectionRight:
            s_hasRightOverlay = YES;
            viewTag = ViewTagRightImage;
            break;
        case DirectionDown:
            s_hasDownOverlay = YES;
            viewTag = ViewTagDownImage;
            break;
        case DirectionUp:
            s_hasUpOverlay = YES;
            viewTag = ViewTagUpImage;
            break;
        default:
            break;
    }
    
    overlay.layer.opacity = 0.0f;
    overlay.tag = viewTag;
    [s_overlayContainer addSubview:overlay];
}

- (void)_rubberBand
{
    CGPoint cardCenter = self.center;
    BOOL isNegative = YES;
    BOOL isVertical = YES;
    if (!self.moveLaterally)
    {
        if (abs(cardCenter.y - _originalCenter.y) > abs(cardCenter.x - _originalCenter.x))
        {
            if (cardCenter.y < _originalCenter.y)
            {
                isNegative = NO;
                isVertical = YES;
            }
            else
            {
                isNegative = YES;
                isVertical = YES;
            }
        }
    }
    else
    {
        // Horizontal rubber band
        if (cardCenter.x < _originalCenter.x)
        {
            isNegative = NO;
            isVertical = NO;
        }
        else
        {
            isNegative = YES;
            isVertical = NO;
        }
    }

    [UIView animateWithDuration:kRubberBandDuration / 3.0f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         CGPoint center = self.originalCenter;
                         if (!isNegative && isVertical)
                             center.y += kRubberBandFirstPass;
                         else if (isNegative && isVertical)
                             center.y -= kRubberBandFirstPass;
                         else if (!isNegative && !isVertical)
                             center.x += kRubberBandFirstPass;
                         else if (isNegative && !isVertical)
                             center.x -= kRubberBandFirstPass;
                         self.center = center;
                         self.layer.opacity = 1.0f;
                         self.transform = CGAffineTransformMakeRotation(0);
                         [self _hideViewOverlays];
                     } completion:^(BOOL finished){
                         [UIView animateWithDuration:kRubberBandDuration / 3.0f animations:^{
                             CGPoint center = self.originalCenter;
                             if (!isNegative && isVertical)
                                 center.y -= kRubberBandSecondPass;
                             else if (isNegative && isVertical)
                                 center.y += kRubberBandSecondPass;
                             else if (!isNegative && !isVertical)
                                 center.x -= kRubberBandSecondPass;
                             else if (isNegative && !isVertical)
                                 center.x += kRubberBandSecondPass;
                             self.center = center;
                         } completion:^(BOOL finished){
                             [UIView animateWithDuration:kRubberBandDuration / 3.0f animations:^{
                                 self.center = self.originalCenter;
                             }];
                         }];
                     }];
}

- (void)_hideViewOverlays
{
    for (UIView *view in [s_overlayContainer subviews])
    {
        switch (view.tag)
        {
            case ViewTagDownImage:
            case ViewTagUpImage:
            case ViewTagLeftImage:
            case ViewTagRightImage:
                view.layer.opacity = 0.0f;
            default:
                break;
        }
    }
}

- (void)_cardLeaves:(NSUInteger)direction
{
    CGPoint end = CGPointMake(0, 0);
    // TODO: Add compatibility for all screen sizes
    switch (direction)
    {
        case DirectionUp:
            end = CGPointMake(self.center.x, -self.frame.size.height);
            break;
        case DirectionDown:
            end = CGPointMake(self.center.x, 2 * self.frame.size.height);
            break;
        case DirectionLeft:
            end = CGPointMake(-self.frame.size.width, self.center.y);
            break;
        case DirectionRight:
            end = CGPointMake(1.5 * self.frame.size.width, self.center.y);
            break;
        default:
            break;
    }
    
    [UIView animateWithDuration:kCardLeavesDuration animations:^{
        self.center = end;
        self.layer.opacity = 0.0f;
    }];
    [self _hideViewOverlays];
}

- (void)_showOverlayWithDirection:(NSUInteger)direction currentLocation:(CGPoint)currentLoc
        previousLocation:(CGPoint)prevLoc
{
    if (self.firstEdgeHit)
    {
        self.firstEdgeHit = NO;
        self.shift = CGPointMake(0, 0);
    }
    
    if (direction == DirectionUp || direction == DirectionDown)
    {
        _shift.y += (currentLoc.y - prevLoc.y);
    }
    else
    {
        _shift.x += (currentLoc.x - prevLoc.x);
    }
    
    for (UIView *view in [s_overlayContainer subviews])
    {
        if (view.tag == ViewTagDownImage && direction == DirectionDown)
        {
            view.layer.opacity = (kOverlayOpacityFactor * _shift.y / 100);
        }
        else if (view.tag == ViewTagUpImage && direction == DirectionUp)
        {
            view.layer.opacity = - (kOverlayOpacityFactor * _shift.y / 100);
        }
        else if (view.tag == ViewTagRightImage && direction == DirectionRight)
        {
            view.layer.opacity = (kOverlayOpacityFactor * _shift.x / 100);
        }
        else if (view.tag == ViewTagLeftImage && direction == DirectionLeft)
        {
            view.layer.opacity = - (kOverlayOpacityFactor * _shift.x / 100);
        }
    }
}

- (void)_resetRotation:(NSUInteger)direction
{
    if (self.lastDirection != direction && self.lastDirection != DirectionCount)
    {
        [UIView animateWithDuration:0.2f animations:^{
            self.transform = CGAffineTransformMakeRotation(0);
        }];
    }
}

- (void)_changeViewOpacityForDirection:(NSUInteger)direction
{
	switch (direction)
	{
		case DirectionUp:
			// Ensures the view doesn't rotate back the other direction.
			if (_shift.y > 0)
				_shift.y = 0;
			self.alpha = 1 + (kViewOpacityFactor * _shift.y / 100);
			break;
		case DirectionDown:
			if (_shift.y < 0)
				_shift.y = 0;
			self.alpha = 1 - (kViewOpacityFactor * _shift.y / 100);
			break;
		case DirectionLeft:
			if (_shift.x > 0)
				_shift.x = 0;
			if (!s_hasLeftOverlay)
				self.alpha = 1 + (kViewRotationOpacityFactor * _shift.x / 100);
			else
				self.alpha = 1 + (kViewOpacityFactor * _shift.x / 100);
			break;
		case DirectionRight:
			if (_shift.x < 0)
				_shift.x = 0;
			if (!s_hasLeftOverlay)
				self.alpha = 1 - (kViewRotationOpacityFactor * _shift.x / 100);
			else
				self.alpha = 1 - (kViewOpacityFactor * _shift.x / 100);
			break;
		default:
			break;
	}
}

@end

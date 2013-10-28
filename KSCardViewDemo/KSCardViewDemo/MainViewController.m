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
	MainViewController.m
 
 Author:
	Kyle Sherman
*/

#import "MainViewController.h"

@interface MainViewController ()

@property (nonatomic, assign) NSInteger currentCount;

- (void)_addCardContent:(KSCardView *)cardView forCard:(NSUInteger)cardNumber;

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    self.allCards = [[NSMutableArray alloc] init];
    self.currentCount = -1;
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    // Create cards
    CGRect cardFrame = CGRectMake(35, 100, 250, 400);
    
    // Setup overlay views
    NSString *upImagePath = [[NSBundle mainBundle] pathForResource:@"DeleteImage" ofType:@".png"];
    UIImage *upImage = [UIImage imageWithContentsOfFile:upImagePath];
    UIImageView *upImageView = [[UIImageView alloc] initWithImage:upImage];
    NSString *downImagePath = [[NSBundle mainBundle] pathForResource:@"ClockImage" ofType:@".png"];
    UIImage *downImage = [UIImage imageWithContentsOfFile:downImagePath];
    UIImageView *downImageView = [[UIImageView alloc] initWithImage:downImage];
    
    // Initialize all KSCardView instances
    [KSCardView setCardViewFrame:cardFrame];
    [KSCardView setOverlayLeft:nil right:nil up:upImageView down:downImageView];
    
    // Create each card view
    KSCardView *cardView = [[KSCardView alloc] init];
    KSCardView *cardView2 = [[KSCardView alloc] init];
    KSCardView *cardView3 = [[KSCardView alloc] init];
    [self _addCardContent:cardView forCard:1];
    [self _addCardContent:cardView2 forCard:2];
    [self _addCardContent:cardView3 forCard:3];

    cardView.delegate = self;
    cardView.layer.opacity = 0.0f;
    cardView.backgroundColor = [UIColor whiteColor];
    cardView2.delegate = self;
    cardView2.backgroundColor = [UIColor whiteColor];
    cardView2.layer.opacity = 0.0f;
    cardView3.delegate = self;
    cardView3.backgroundColor = [UIColor whiteColor];
    cardView3.layer.opacity = 0.0f;
    
    // Add cards to array
    [self.allCards addObject:cardView];
    [self.allCards addObject:cardView2];
    [self.allCards addObject:cardView3];
}

- (void)_addCardContent:(KSCardView *)cardView forCard:(NSUInteger)cardNumber
{
    // Create sample card content
    NSString *content = [NSString stringWithFormat:@"Content for card %d", (int)cardNumber];
    UILabel *cardText = [[UILabel alloc] init];
    cardText.frame = CGRectMake(0, 0, 300, 200);
    cardText.lineBreakMode = NSLineBreakByWordWrapping;
    cardText.textColor = [UIColor blackColor];
    cardText.text = content;
    cardText.font = [UIFont systemFontOfSize:22];
    [cardView addSubview:cardText];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.currentCount++;
    self.currentCardView = [self.allCards objectAtIndex:self.currentCount];
    [self.view addSubview:self.currentCardView];
    [self.currentCardView showFromLeft];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Demo Button Actions
- (IBAction)demoUp:(id)sender
{
    if (self.allCards.count != 0)
        [self.currentCardView demoUp];
}

- (IBAction)demoDown:(id)sender
{
    if (self.allCards.count != 0)
        [self.currentCardView demoDown];
}

- (IBAction)demoLeft:(id)sender
{
    if (self.allCards.count != 0)
        [self.currentCardView demoLeft];
}

- (IBAction)demoRight:(id)sender
{
    if (self.allCards.count != 0)
        [self.currentCardView demoRight];
}

- (IBAction)resetDemo:(id)sender
{
    if (self.allCards.count != 0)
        [self.currentCardView demoReset];
}

#pragma mark - Delegate functions
- (void)cardDidLeaveLeftEdge:(KSCardView *)cardView
{
    NSLog(@"%s", __FUNCTION__);
    self.currentCount++;
    BOOL success = YES;
    if (self.currentCount > self.allCards.count - 1)
    {
        // No next card -- show alert
        UIAlertView *noNextAlert = [[UIAlertView alloc]
                                        initWithTitle:@"No Next Card"
                                        message:@"You are at the last card."
                                        delegate:self cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil];
        [noNextAlert show];
        self.currentCount--;
        success = NO;
    }
    
    self.currentCardView = [_allCards objectAtIndex:_currentCount];
    [self.view addSubview:self.currentCardView];
    
    if (success)
        [self.currentCardView showFromRight];
    else
        [self.currentCardView showFromLeft];
}

- (void)cardDidLeaveRightEdge:(KSCardView *)cardView
{
    NSLog(@"%s", __FUNCTION__);
    self.currentCount--;
    BOOL success = YES;
    if (self.currentCount < 0)
    {
        // No previous card -- show alert
        UIAlertView *noPreviousAlert = [[UIAlertView alloc]
                                        initWithTitle:@"No Previous Card"
                                        message:@"You are at the first card."
                                        delegate:self cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil];
        [noPreviousAlert show];
        self.currentCount++;
        success = NO;
    }
    
    self.currentCardView = [_allCards objectAtIndex:_currentCount];
    [self.view addSubview:self.currentCardView];
    
    if (success)
        [self.currentCardView showFromLeft];
    else
        [self.currentCardView showFromRight];
}

- (void)cardDidLeaveTopEdge:(KSCardView *)cardView
{
    NSLog(@"%s", __FUNCTION__);
    [self.allCards removeObjectAtIndex:self.currentCount];
    BOOL success = YES;
	
	if (self.allCards.count == 0)
	{
		// Show alert that there are no cards left
		UIAlertView *noCards = [[UIAlertView alloc]
                                        initWithTitle:@"No More Cards"
                                        message:@"All cards have been removed."
                                        delegate:self cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil];
        [noCards show];
		return;
	}
	
    if (self.currentCount > self.allCards.count - 1)
    {
        self.currentCount--;
        success = NO;
    }
    
    self.currentCardView = [_allCards objectAtIndex:_currentCount];
    [self.view addSubview:self.currentCardView];
    
    if (success)
        [self.currentCardView showFromRight];
    else
        [self.currentCardView showFromLeft];
}

- (void)cardDidLeaveBottomEdge:(KSCardView *)cardView
{
    NSLog(@"%s", __FUNCTION__);
    BOOL success = YES;
    // Move current card to end
    // If at end, go to beginning
    if (self.currentCount == self.allCards.count - 1)
    {
        self.currentCount = 0;
        success = NO;
    }
    
    self.currentCardView = [self.allCards objectAtIndex:self.currentCount];
    if (success)
    {
        [self.allCards removeObjectAtIndex:self.currentCount];
        [self.allCards addObject:self.currentCardView];
        self.currentCardView = [self.allCards objectAtIndex:self.currentCount];
        [self.view addSubview:self.currentCardView];
        [self.currentCardView showFromRight];
    }
    else
    {
        self.currentCardView = [self.allCards objectAtIndex:self.currentCount];
        [self.view addSubview:self.currentCardView];
        [self.currentCardView showFromLeft];
    }
}

@end

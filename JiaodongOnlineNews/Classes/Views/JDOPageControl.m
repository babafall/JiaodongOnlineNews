//
//  JDOPageControl.m
//  JiaodongOnlineNews
//
//  Created by zhang yi on 13-5-23.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import "JDOPageControl.h"

#define MASK_VISIBLE_ALPHA 0.5
#define UPPER_TOUCH_LIMIT -10
#define LOWER_TOUCH_LIMIT 10
#define Left_Margin 6.5f
#define slider_top_margin 3.5f
#define slider_padding 3.5f
#define title_label_tag 100
#define title_normal_color [UIColor colorWithWhite:100.0/255.0 alpha:1.0]
#define title_normal_shadow [UIColor whiteColor]
#define title_highlight_color [UIColor whiteColor]
#define title_highlight_shadow [UIColor blackColor]

@implementation JDOPageControl

- (id)initWithFrame:(CGRect)frame background:(NSString *)backgroundImage slider:(NSString *)sliderImage pages:(NSArray *)pages{
    if (self = [super initWithFrame:frame]) {
        // 背景色
		_backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,frame.size.width,frame.size.height)];
        [_backgroundView setImage:[UIImage imageNamed:backgroundImage]];
        [self addSubview:_backgroundView];
        [self sendSubviewToBack:_backgroundView];
		// 滑动背景
		_slider = [[UIImageView alloc] initWithFrame:CGRectZero];
        [_slider setImage:[UIImage imageNamed:sliderImage]];
        [self insertSubview:_slider aboveSubview:_backgroundView];
        
        [self setPages:pages];
    }
    return self;
}

-(void) setPages:(NSArray *)pages{
    _animating = false;
    _currentPage = -1;
    _pages = pages;
    _numberOfPages = pages.count;
    float width = (self.frame.size.width-Left_Margin*2)/pages.count;
    for (int i=0; i<pages.count; i++) {
        UIButton *titleBtn = [[UIButton alloc] initWithFrame:CGRectMake(Left_Margin+i*width, 0, width,self.frame.size.height)];
        // pages中的内容必须是含有title属性的对象或包含该key值的Dictionary
        [titleBtn setTitle:[[pages objectAtIndex:i] valueForKey:@"title"] forState:UIControlStateNormal];
        [titleBtn setTitleColor:title_normal_color forState:UIControlStateNormal];
        // 不使用字体阴影
//        titleBtn.titleLabel.shadowOffset = CGSizeMake(0, 1);
//        [titleBtn setTitleShadowColor:title_normal_shadow forState:UIControlStateNormal];
        titleBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        // iOS5中,调整label的文字偏左2个像素以使其在整个button中居中,iOS6未测试时候需要调整
        [titleBtn setTitleEdgeInsets:UIEdgeInsetsMake( 0,2,0,0)];
//        titleBtn.titleLabel.backgroundColor = [UIColor blueColor];
        titleBtn.tag = title_label_tag+i;
        titleBtn.backgroundColor = [UIColor clearColor];
        [titleBtn addTarget:self action:@selector(onTitleClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:titleBtn];
    }
}

- (void) setTitleFontSize:(CGFloat) size{
    for (int i=0; i<_pages.count; i++) {
        UIButton *titleBtn = (UIButton *)[self viewWithTag:title_label_tag+i];
        [titleBtn.titleLabel setFont:[UIFont systemFontOfSize:size]];
    }
}

- (void)onTitleClicked:(UIButton *)titleBtn{
    int toPageIndex = titleBtn.tag - title_label_tag;
    if(_currentPage == toPageIndex) return;
    if(_animating == false) {
        _animating = true;
        [self setCurrentPage:toPageIndex animated:true];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    
}

- (void)setCurrentPage:(int)toPage{
    [self setCurrentPage:toPage animated:NO];
}

- (void)setCurrentPage:(int)toPage animated:(BOOL)animated{
    // 在scrollView中滑动时会持续触发该函数，增加currentPage的判断可优化执行
    if(_currentPage == toPage){
        _animating = false;
        return;
    }
    [self setTitleOfIndex:_currentPage toColor:title_normal_color shadowColor:title_normal_shadow offset:CGSizeMake(0, 1)];
    _currentPage = toPage;
	if (animated){
		[UIView beginAnimations:@"moveSlider" context:nil];
        [UIView setAnimationDelegate:self];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	}
	
	float width = (self.frame.size.width-2*Left_Margin)/self.numberOfPages;
	float x = Left_Margin+width*_currentPage;
    // 也可以只修改center,设置为对应labelButton的center
	[self.slider setFrame:CGRectMake(x+slider_padding,slider_top_margin,width-slider_padding*2,self.frame.size.height-slider_top_margin*2)];
	if (animated){
        [UIView commitAnimations];
    }else{
        [self setTitleOfIndex:toPage toColor:title_highlight_color shadowColor:title_highlight_shadow offset:CGSizeMake(0, -1)];
    }
}

- (void)setTitleOfIndex:(int)index toColor:(UIColor *)color shadowColor:(UIColor *)shadowColor offset:(CGSize) offset{
    if(index<0) return;
    UIButton *titleButton = (UIButton *)[self viewWithTag:title_label_tag+index];
    [titleButton setTitleColor:color forState:UIControlStateNormal];
//    titleButton.titleLabel.shadowOffset = offset;
//    [titleButton setTitleShadowColor:shadowColor forState:UIControlStateNormal];
}

//- (void)drawRect:(CGRect)rect {
//    // Drawing code
//	CGContextRef myContext = UIGraphicsGetCurrentContext();
//	float diameter = 5;
//	
//	CGFloat blackColor[4];
//	blackColor[0]=0.0;
//	blackColor[1]=0.0;
//	blackColor[2]=0.0;
//	blackColor[3]=1.0;
//	float width = self.frame.size.width/self.numberOfPages;
//	
//	int i;
//	for (i=0; i<self.numberOfPages; i++)
//	{
//		int x = i*width + (width-diameter)/2;
//		CGContextSetFillColor(myContext, blackColor);
//		CGContextFillEllipseInRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2,diameter,diameter));
//	}
//}


-(void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context{
    if([animationID isEqualToString:@"moveSlider"] && [finished boolValue]){
        [self setTitleOfIndex:_currentPage toColor:title_highlight_color shadowColor:title_highlight_shadow offset:CGSizeMake(0, -1)];
        _animating = false;
    }
    
}

@end

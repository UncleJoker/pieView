//
//  HPHPieChartView.m
//  dpw
//
//  Created by ZJE on 2018/10/19.
//  Copyright © 2018年 aaaa. All rights reserved.
//

#import "HPHPieChartView.h"
#import "HPHFinancialScoreModel.h"
#import "UIView+Layout.h"

// 支出颜色
#define COLOR_ARRAY_EXPENDITURE @[\
HexColor(@"#bd91ff"),\
HexColor(@"#87bcfe"),\
HexColor(@"#8cf3d2"),\
HexColor(@"#ffb8b8")\
]

// 收入颜色
#define COLOR_ARRAY_INCOME @[\
HexColor(@"#93e0fe"),\
HexColor(@"#5ca7ba")\
]

// 圆饼距离边缘的距离
#define CHART_MARGIN 40

// pi 转 角度
#define TO_RADIUS(value) ((value / M_PI) * 180)

// tag
static NSInteger TextBtnTag = 10000;

@implementation StrOrigin

@end

@implementation RadiusRange

@end

@interface HPHPieChartView()
{
    UIView *_cycleView;// 阴影背景
    UITapGestureRecognizer *_tap;
    CGPoint _centerPoint;
    UIButton *_textBtn;
}

@property (nonatomic,strong)NSMutableArray *modelArray;
@property (nonatomic,strong)NSMutableArray *colorArray;
@property (nonatomic,strong)NSMutableArray *radiusRangeArr;
// 记录每个str的y最大和最小值
@property(nonatomic,strong)NSMutableArray *strYArr;

@end

@implementation HPHPieChartView
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // 添加点击事件
        _tap =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selfTap:)];
        [self addGestureRecognizer:_tap];
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)draw {
    [self.strYArr removeAllObjects];
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self setNeedsDisplay];
}

#pragma mark - Aciton
- (void)selfTap:(UITapGestureRecognizer *)tap
{
    CGPoint point = [tap locationInView:self];// 点在视图的位置
    // 圆形中点
    CGPoint center =  CGPointMake(self.width * 0.5, self.height * 0.5);
    // 圆形半径
    CGFloat min = self.width > self.height ? self.height : self.width;
    CGFloat radius = min * 0.5 - CHART_MARGIN;
    // 判断点击是否在圆饼内
    float a = fabs(point.x-center.x);
    float b = fabs(point.y-center.y);
    float c = sqrtf(a*a+b*b);
    if (c<=radius&&self.dataArray.count!=0) {
        // 点在饼形图内
        NSInteger num=0;
        // 饼形图  收入与支出的起点不一样 不能用同一个方法来计算点的位置
        if (self.type != IncomePie) {
            num = [self PointOnArea:point];
        }else{
            num = [self compareAngleWtihTapPoint:point];
        }
        if (self.clickBlock) {
            self.clickBlock(num,self.type);
        }
    }
}

- (void)textClickAction:(UIButton *)sender
{
    if (self.clickBlock) {
        self.clickBlock(sender.tag-TextBtnTag,self.type);
    }
}

// 判断点在哪个扇形上
#pragma mark -- 根据点判断点击的位置在哪个扇形区(支出)
- (NSInteger)PointOnArea:(CGPoint)point {
    CGPoint p = [self PointAboutCenter:point];
    CGFloat radius = [self PointToRadiu:p];
    NSInteger num = [self RadiusToTag:radius];
    return num;
}

- (CGPoint)PointAboutCenter:(CGPoint)point {
    CGPoint  p;
    p.x = point.x - _centerPoint.x;
    p.y = point.y - _centerPoint.y;
    return p;
}

- (CGFloat)PointToRadiu:(CGPoint)point {
    float r = atan(point.y/point.x);// 点到圆形直线与x轴的夹角角度
    CGFloat radius = TO_RADIUS(r);
    if (point.x < 0 && point.y > 0) {
        radius = 180 + radius;
    } else if (point.x < 0 && point.y < 0) {
        radius = 180 + radius;
    } else if (point.x > 0 && point.y < 0) {
        radius = 360 + radius;
    }
    return radius;
}

//判断角度对应扇形区
- (NSInteger)RadiusToTag:(CGFloat)radius {
    for (int i = 0; i < self.radiusRangeArr.count; i++) {
        RadiusRange * range = [self.radiusRangeArr objectAtIndex:i];
        if (radius >= range.start/M_PI*180 && radius <= range.end/M_PI*180) {
            return i;
        }
    }
    return -1;
}

#pragma mark -- 根据点判断点击的位置在哪个扇形区(收入)
- (NSInteger)compareAngleWtihTapPoint:(CGPoint)point
{
    CGPoint p = [self PointAboutCenter:point];
    float r = atan(p.y/p.x);// -pi/2  到 pi/2
    CGFloat radius = fabs(TO_RADIUS(r));// 去绝对值
    radius = p.x > 0 ? 90 + radius: radius;
    // 只要取收入第一个数据占的圆比例
    CGFloat angle = 0;
    if (self.dataArray.count == 2) {
        HPHFinancialPieModel *model = self.dataArray[0];
        NSString *rate = [model.rate stringByReplacingOccurrencesOfString:@"%" withString:@""];
        angle = [rate floatValue]/100*360;
    }
    return radius > angle/2 ? 1 : 0 ;
}

#pragma mark - 绘图
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    [self.radiusRangeArr removeAllObjects];
    // Drawing code
    // 圆形中点
    _centerPoint =  CGPointMake(self.width * 0.5, self.height * 0.5);
    // 圆形半径
    CGFloat min = self.width > self.height ? self.height : self.width;
    CGFloat radius = min * 0.5 - CHART_MARGIN;
    
    // 更改绘图起点
    CGFloat start = self.type == IncomePie ? [self calculateStartPoint] : 0;
    CGFloat angle = 0;// 角度
    CGFloat end = start;// 终点

    if (![self checkDataIsNill]) {
        // 无数据处理
        
    }else {
        NSMutableArray *pointArray = [NSMutableArray array];
        NSMutableArray *centerArray = [NSMutableArray array];
        
        self.modelArray = [NSMutableArray array];
        self.colorArray = [NSMutableArray array];
        
        for (int i = 0; i < self.dataArray.count; i++) {
            
            HPHFinancialPieModel *model = self.dataArray[i];
            NSString *rate = [model.rate stringByReplacingOccurrencesOfString:@"%" withString:@""];
            CGFloat percent = [rate floatValue]/100;
            UIColor *color = self.type == IncomePie ? COLOR_ARRAY_INCOME[i]: COLOR_ARRAY_EXPENDITURE[i];
            start = end;
            angle = percent * M_PI * 2;
            end = start + angle;
            
            // 保存角度范围
            RadiusRange *item = [RadiusRange new];
            item.start = self.type == IncomePie ? start-[self calculateStartPoint]:start;
            item.end = self.type == IncomePie ? end-[self calculateStartPoint]:end;
            [self.radiusRangeArr addObject:item];
            
            UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:_centerPoint radius:radius startAngle:start endAngle:end clockwise:true];
            [color set];
            //添加一根线到圆心
            [path addLineToPoint:_centerPoint];
            [path fill];
            
            // 获取弧度的中心角度
            CGFloat radianCenter = (start + end) * 0.5;
            
            // 获取指引线的起点
            CGFloat lineStartX = self.frame.size.width * 0.5 + radius * cos(radianCenter);
            CGFloat lineStartY = self.frame.size.height * 0.5 + radius * sin(radianCenter);
            CGPoint point = CGPointMake(lineStartX, lineStartY);
            
            [pointArray addObject:[NSValue valueWithCGPoint:point]];
            [centerArray addObject:[NSNumber numberWithFloat:radianCenter]];
            [self.modelArray addObject:model];
            [self.colorArray addObject:color];
        }
        // 通过pointArray绘制指引线
        [self drawLineWithPointArray:pointArray centerArray:centerArray];
    }
}

- (BOOL)checkDataIsNill
{
    for (int i = 0; i < self.dataArray.count; i ++) {
        HPHFinancialPieModel *item = self.dataArray[i];
        NSString *rate = [item.rate stringByReplacingOccurrencesOfString:@"%" withString:@""];
        if ([rate floatValue] != 0) {
            return YES;
        }
    }
    return NO;
}

// 根据数据计算起点
- (CGFloat)calculateStartPoint
{
    CGFloat startP = 0;
    HPHFinancialPieModel *item0 = [[HPHFinancialPieModel alloc] init];
    HPHFinancialPieModel *item1 = [[HPHFinancialPieModel alloc] init];
    if (self.dataArray.count == 2) {
        item0 = self.dataArray[0];
        item1 = self.dataArray[1];
    }else{
        return startP;
    }
    NSString *rate0 = [item0.rate stringByReplacingOccurrencesOfString:@"%" withString:@""];
    NSString *rate1 = [item1.rate stringByReplacingOccurrencesOfString:@"%" withString:@""];
    startP = [rate0 floatValue]/100 >= [rate1 floatValue]/100 ? 2*M_PI+M_PI*[rate1 floatValue]/100 : M_PI-M_PI*[rate0 floatValue]/100;
//    startP = item0.rate >= item1.rate ? 2*M_PI+M_PI*item1.rate : M_PI-M_PI*item0.rate;
    return startP;
}

- (void)drawLineWithPointArray:(NSArray *)pointArray centerArray:(NSArray *)centerArray {
    
    // 记录每一个指引线包括数据所占用位置的和（总体位置）
    CGRect rect = CGRectZero;
    
    // 用于计算指引线长度
    CGFloat width = self.bounds.size.width * 0.5;
    
    for (int i = 0; i < pointArray.count; i++) {
        // 取出数据
        NSValue *value = pointArray[i];
        // 每个圆弧中心点的位置
        CGPoint point = value.CGPointValue;
        // 每个圆弧中心点的角度
        CGFloat radianCenter = [centerArray[i] floatValue];
        // 颜色（绘制数据时要用）
        UIColor *color = [UIColor colorWithRed:21/255.0 green:21/255.0 blue:21/255.0 alpha:0.5];;
        // 模型数据（绘制数据时要用）
        HPHFinancialPieModel *model = self.modelArray[i];
        // 模型的数据
        NSString *name = [NSString stringWithFormat:@"%@,%@", model.total_name,model.rate];
        NSString *number = [NSString stringWithFormat:@"%@元", self.type == IncomePie ? model.income_amount : model.out_amount];
        
        // 圆弧中心点的x值和y值
        CGFloat x = point.x;
        CGFloat y = point.y;
        
        // 指引线终点的位置（x, y）
        CGFloat startX = x + 10 * cos(radianCenter);
        CGFloat startY = y + 10 * sin(radianCenter);
        
        // 指引线转折点的位置(x, y)
        CGFloat breakPointX = x + 20 * cos(radianCenter);
        CGFloat breakPointY = y + 20 * sin(radianCenter);
        
        // 转折点到中心竖线的垂直长度（为什么+20, 在实际做出的效果中，有的转折线很丑，+20为了美化）
        CGFloat margin = fabs(width - breakPointX) + 20;
        // 指引线长度
        CGFloat lineWidth = width - margin;
        // 指引线起点（x, y）
        CGFloat endX;
        CGFloat endY;
        
        // 绘制文字和数字时，所占的size（width和height）
        // width使用lineWidth更好，我这么写固定值是为了达到产品要求
        CGFloat numberWidth = 120.f;
        CGFloat numberHeight = 15.f;
        
        CGFloat titleWidth = numberWidth;
        CGFloat titleHeight = numberHeight;
        
        // 绘制文字和数字时的起始位置（x, y）与上面的合并起来就是frame
        CGFloat numberX;
        CGFloat numberY = breakPointY - numberHeight;
        
        CGFloat titleX = breakPointX;
        CGFloat titleY = breakPointY + 2;
        
        
        // 文本段落属性(绘制文字和数字时需要)
        NSMutableParagraphStyle * paragraph = [[NSMutableParagraphStyle alloc]init];
        // 文字靠右
        paragraph.alignment = NSTextAlignmentRight;
        // 判断x位置，确定在指引线向左还是向右绘制
        // 根据需要变更指引线的起始位置
        // 变更文字和数字的位置
        if (x <= width) { // 在左边
            // 文字靠左
            endX = 10;
            endY = breakPointY;
            paragraph.alignment = NSTextAlignmentLeft;
            numberX = endX;
            titleX = endX;
        } else {    
            // 在右边
            endX = self.bounds.size.width - 10;
            endY = breakPointY;
            numberX = endX - numberWidth;
            titleX = endX - titleWidth;
        }
        
        if (i != 0) {
            // 当i!=0时，就需要计算位置总和(方法开始出的rect)与rect1(将进行绘制的位置)是否有重叠
            CGRect rect1 = CGRectMake(numberX, numberY, numberWidth, titleY + titleHeight - numberY);
            CGFloat margin = 0;
            
            if (CGRectIntersectsRect(rect, rect1)) {
                // 两个面积重叠
                // 三种情况
                // 1. 压上面
                // 2. 压下面
                // 3. 包含
                // 通过计算让面积重叠的情况消除
                if (CGRectContainsRect(rect, rect1)) {
                    // 包含
                    if (i % self.dataArray.count <= self.dataArray.count * 0.5 - 1) {
                        // 将要绘制的位置在总位置偏上
                        margin = CGRectGetMaxY(rect1) - rect.origin.y;
                        endY -= margin;
                    } else {
                        // 将要绘制的位置在总位置偏下
                        margin = CGRectGetMaxY(rect) - rect1.origin.y;
                        endY += margin;
                    }
                } else {
                    // 相交
                    if (CGRectGetMaxY(rect1) > rect.origin.y && rect1.origin.y < rect.origin.y) { // 压在总位置上面
                        margin = CGRectGetMaxY(rect1) - rect.origin.y;
                        endY -= margin;
                    } else if (rect1.origin.y < CGRectGetMaxY(rect) &&  CGRectGetMaxY(rect1) > CGRectGetMaxY(rect)) {  // 压总位置下面
                        margin = CGRectGetMaxY(rect) - rect1.origin.y;
                        endY += margin;
                    }
                }
            }
            titleY = endY + 2;
            numberY = endY - numberHeight;
        
            // 通过计算得出的将要绘制的位置
            CGRect rect2 = CGRectMake(numberX, numberY, numberWidth, titleY + titleHeight - numberY);
            
            // 把新获得的rect和之前的rect合并
            if (numberX == rect.origin.x) {
                // 当两个位置在同一侧的时候才需要合并
                if (rect2.origin.y < rect.origin.y) {
                    rect = CGRectMake(rect.origin.x, rect2.origin.y, rect.size.width, rect.size.height + rect2.size.height);
                } else {
                    rect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height + rect2.size.height);
                }
            }
        } else {
            rect = CGRectMake(numberX, numberY, numberWidth, titleY + titleHeight - numberY);
        }
        
        // 重新制定转折点
        if (endX == 10) {
            breakPointX = endX + lineWidth;
        } else {
            breakPointX = endX - lineWidth;
        }
        
        breakPointY = endY;
        
        
        // 绘图前需要检查当前文字是否被遮住了
        // 1.每个指引线上的文字的最大y和最小y
        CGFloat margins = 0;
        CGFloat yMax = titleY+numberHeight*2;
        CGFloat yMin = titleY;
        if (self.strYArr.count != 0) {
            for (StrOrigin *origin in self.strYArr) {
                // 先保证同一边
                if ((origin.x <= width && titleX <= width) || (origin.x > width && titleX > width)) {
                    if (!(yMax < origin.yMin || yMin > origin.yMax)) {
                        // 有被遮住
                        if (yMax<=origin.yMax) {// 上移 减
                            margins += yMax-origin.yMin;
                            yMax -= margins;
                            yMin -= margins;
                        }
                        if (yMin>=origin.yMin) {// 下移 加
                            margins = origin.yMax-yMin;
                            yMax += margins;
                            yMin += margins;
                        }
                    }
                }
            }
        }
        
        StrOrigin *item = [StrOrigin new];
        item.yMax = yMax;
        item.yMin = yMin;
        item.x = titleX;
        [self.strYArr addObject:item];
        
        // 绘制图形  判断数据占比是否为0, 0不绘制
        if ([[model.rate stringByReplacingOccurrencesOfString:@"%" withString:@""] floatValue] != 0) {
            //1.获取上下文
            CGContextRef ctx = UIGraphicsGetCurrentContext();
            //2.绘制路径
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(endX, endY+margins)];
            [path addLineToPoint:CGPointMake(breakPointX, breakPointY+margins)];
            [path addLineToPoint:CGPointMake(startX, startY)];
            CGContextSetLineWidth(ctx, 0.5);
            
            //设置颜色
            [color set];
            
            //3.把绘制的内容添加到上下文当中
            CGContextAddPath(ctx, path.CGPath);
            //4.把上下文的内容显示到View上(渲染到View的layer)(stroke fill)
            CGContextStrokePath(ctx);
            
            // 在终点处添加点(小圆点)
            // movePoint，让转折线指向小圆点中心
            CGFloat movePoint = -2.5;
            
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = color;
            [self addSubview:view];
            CGRect rect = view.frame;
            rect.size = CGSizeMake(5, 5);
            rect.origin = CGPointMake(startX + movePoint, startY + movePoint);
            view.frame = rect;
            view.layer.cornerRadius = 2.5;
            view.layer.masksToBounds = true;
            
            // 绘图
            //指引线上面的数字
            [name drawInRect:CGRectMake(numberX, numberY+margins, numberWidth, numberHeight) withAttributes:@{NSFontAttributeName:FONT_SIZE_10, NSForegroundColorAttributeName:color,NSParagraphStyleAttributeName:paragraph}];
            
            // 指引线下面的title
            [number drawInRect:CGRectMake(titleX, titleY+margins, titleWidth, titleHeight) withAttributes:@{NSFontAttributeName:FONT_SIZE_10,NSForegroundColorAttributeName:color,NSParagraphStyleAttributeName:paragraph}];
            
            // 添加文字点击按钮
            _textBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
            _textBtn.frame = CGRectMake(numberX, numberY+margins, numberWidth, numberHeight+titleHeight);
            _textBtn.tag = TextBtnTag + i;
            _textBtn.backgroundColor = [UIColor clearColor];
            [_textBtn addTarget:self action:@selector(textClickAction:) forControlEvents:(UIControlEventTouchUpInside)];
            [self addSubview:_textBtn];
        }
    }
}

#pragma mark setters and getters
- (NSMutableArray *)radiusRangeArr
{
    if (!_radiusRangeArr) {
        _radiusRangeArr = [NSMutableArray array];
    }
    return _radiusRangeArr;
}

- (NSMutableArray *)strYArr
{
    if (!_strYArr) {
        _strYArr = [NSMutableArray array];
    }
    return _strYArr;
}

@end

//
//  HPHPieChartView.h
//  dpw
//
//  Created by ZJE on 2018/10/19.
//  Copyright © 2018年 aa. All rights reserved.
//
//  饼状图

#import <UIKit/UIKit.h>

// 饼形数据类型
typedef NS_ENUM(NSInteger, PieChartType){
    ExpenditurePie=1,                  // 支出
    IncomePie,                         // 收入
};

@interface StrOrigin : NSObject
@property(nonatomic,assign)CGFloat yMin;
@property(nonatomic,assign)CGFloat yMax;
@property(nonatomic,assign)CGFloat x;// 起点
@end

@interface RadiusRange : NSObject
@property (nonatomic, assign) CGFloat start;
@property (nonatomic, assign)  CGFloat end;
@end

typedef void(^ClickPieBlock)(NSInteger index, PieChartType type);

@interface HPHPieChartView : UIView

@property (nonatomic,strong)ClickPieBlock clickBlock;

/**
 圆饼类型
 */
@property (nonatomic,assign)PieChartType type;

/**
 起点
 */
@property (nonatomic,assign)CGFloat start;

/**
 数据数组
 */
@property (strong, nonatomic) NSArray *dataArray;


/**
 绘制方法
 */
- (void)draw;

@end

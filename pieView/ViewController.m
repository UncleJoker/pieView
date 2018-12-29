//
//  ViewController.m
//  pieView
//
//  Created by 林 on 2018/11/16.
//  Copyright © 2018年 zje. All rights reserved.
//

#import "ViewController.h"
#import "HPHPieChartView.h"

@interface ViewController ()

@property (nonatomic,strong)HPHPieChartView *pieView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUI];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)setUI
{
    
}

#pragma mark setters and getters
- (HPHPieChartView *)pieView
{
    if (!_pieView) {
        _pieView = [[HPHPieChartView alloc] init];
        _pieView.backgroundColor = [UIColor whiteColor];
        _pieView.type = ExpenditurePie;
    }
    return _pieView;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

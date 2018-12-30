/**
 * 图表
 * @author 郑业强 2018-12-16 创建文件
 */

#import "ChartController.h"
#import "ChartNavigation.h"
#import "ChartSegmentControl.h"
#import "ChartDate.h"
#import "ChartTableView.h"
#import "ChartHUD.h"
#import "ChartModel.h"
#import "ChartRangeModel.h"


#pragma mark - 声明
@interface ChartController()

@property (nonatomic, strong) ChartNavigation *navigation;
@property (nonatomic, strong) ChartSegmentControl *seg;
@property (nonatomic, strong) ChartDate *subdate;
@property (nonatomic, strong) ChartHUD *chud;
@property (nonatomic, strong) ChartTableView *table;

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) NSInteger selectIndex;
@property (nonatomic, strong) NSMutableArray<ChartModel *> *models;
@property (nonatomic, strong) ChartRangeModel *timeModel;

@end


#pragma mark - 实现
@implementation ChartController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setJz_navigationBarHidden:true];
    [self setDate:[NSDate date]];
    [self navigation];
    [self seg];
    [self subdate];
    [self table];
    [self chud];
    [self setSelectIndex:0];
    [self bookRangeRequest];
}


#pragma mark - 请求
// 时间范围
- (void)bookRangeRequest {
    @weakify(self)
    [AFNManager POST:GetBookRangeRequest params:nil complete:^(APPResult *result) {
        @strongify(self)
        if (result.status == ServiceCodeSuccess) {
            [self setTimeModel:[ChartRangeModel mj_objectWithKeyValues:result.data]];
        } else {
            [self showTextHUD:result.message delay:1.f];
        }
    }];
}
// 查账(组)
- (void)bookGroupRequest {
    @weakify(self)
    NSMutableDictionary *param = ({
        NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
        [param setObject:@(self.navigation.selectIndex) forKey:@"isIncome"];
        if (_seg.seg.selectedSegmentIndex == 0) {
            [param setObject:@([self.date year]) forKey:@"year"];
            [param setObject:@([self.date month]) forKey:@"month"];
            [param setObject:@([self.date day]) forKey:@"day"];
            [param setObject:@([self.date weekOfYear]) forKey:@"week"];
            [param setObject:@(1) forKey:@"week_year"];
        } else if (_seg.seg.selectedSegmentIndex == 1) {
            [param setObject:@([self.date year]) forKey:@"year"];
            [param setObject:@([self.date month]) forKey:@"month"];
        } else if (_seg.seg.selectedSegmentIndex == 2) {
            [param setObject:@([self.date year]) forKey:@"year"];
        }
        param;
    });
    [AFNManager POST:getBookGroupRequest params:param complete:^(APPResult *result) {
        @strongify(self)
        if (result.status == ServiceCodeSuccess) {
            [self setModels:[ChartModel mj_objectArrayWithKeyValuesArray:result.data]];
        } else {
            [self showTextHUD:result.message delay:1.f];
        }
    }];
}
// 查账(条)
- (void)bookListRequest {
    @weakify(self)
    NSMutableDictionary *param = ({
        NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
        [param setObject:@(self.navigation.selectIndex) forKey:@"isIncome"];
        if (_seg.seg.selectedSegmentIndex == 0) {
            [param setObject:@([self.date year]) forKey:@"year"];
            [param setObject:@([self.date month]) forKey:@"month"];
            [param setObject:@([self.date day]) forKey:@"day"];
            [param setObject:@([self.date weekOfYear]) forKey:@"week"];
            [param setObject:@(1) forKey:@"week_year"];
        } else if (_seg.seg.selectedSegmentIndex == 1) {
            [param setObject:@([self.date year]) forKey:@"year"];
            [param setObject:@([self.date month]) forKey:@"month"];
        } else if (_seg.seg.selectedSegmentIndex == 2) {
            [param setObject:@([self.date year]) forKey:@"year"];
        }
        param;
    });
    [AFNManager POST:GetBookListRequest params:param complete:^(APPResult *result) {
        @strongify(self)
        if (result.status == ServiceCodeSuccess) {
            
        } else {
            [self showTextHUD:result.message delay:1.f];
        }
    }];
}



#pragma mark - set
- (void)setTimeModel:(ChartRangeModel *)timeModel {
    _timeModel = timeModel;
    _subdate.timeModel = timeModel;
    [self setDate:[NSDate dateWithYMD:[NSString stringWithFormat:@"%ld-%02ld-%02ld", timeModel.max_year, timeModel.max_month, timeModel.max_day]]];
    [self bookGroupRequest];
}
- (void)setModels:(NSMutableArray<ChartModel *> *)models {
    _models = models;
    _subdate.models = models;
    _table.models = models;
    [self bookListRequest];
}
- (void)setSelectIndex:(NSInteger)selectIndex {
    _selectIndex = selectIndex;
    _navigation.selectIndex = selectIndex;
    _table.selectIndex = selectIndex;
}


#pragma mark - get
- (ChartNavigation *)navigation {
    if (!_navigation) {
        @weakify(self)
        _navigation = [ChartNavigation loadFirstNib:CGRectMake(0, 0, SCREEN_WIDTH, NavigationBarHeight)];
        [[_navigation.button rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(UIControl *button) {
            @strongify(self)
            [self.chud show];
        }];
        [self.view addSubview:_navigation];
    }
    return _navigation;
}
- (ChartSegmentControl *)seg {
    if (!_seg) {
        @weakify(self)
        _seg = [ChartSegmentControl loadFirstNib:CGRectMake(0, NavigationBarHeight, SCREEN_WIDTH, countcoordinatesX(50))];
        [[_seg.seg rac_signalForControlEvents:UIControlEventValueChanged] subscribeNext:^(UISegmentedControl *seg) {
            @strongify(self)
            [self.subdate setIndex:seg.selectedSegmentIndex];
            [self bookRangeRequest];
        }];
        [self.view addSubview:_seg];
    }
    return _seg;
}
- (ChartDate *)subdate {
    if (!_subdate) {
        @weakify(self)
        _subdate = [ChartDate loadCode:CGRectMake(0, _seg.bottom, SCREEN_WIDTH, countcoordinatesX(45))];
        [_subdate setComplete:^(ChartSubModel *model) {
            @strongify(self)
            NSInteger month = model.month == -1 ? 1 : model.month;
            NSInteger day = model.day == -1 ? 1 : model.day;
            NSString *str = [NSString stringWithFormat:@"%ld-%02ld-%02ld", model.year, month, day];
            [self setDate:[NSDate dateWithYMD:str]];
            [self bookGroupRequest];
        }];
        [self.view addSubview:_subdate];
    }
    return _subdate;
}
- (ChartTableView *)table {
    if (!_table) {
        _table = [ChartTableView initWithFrame:({
            CGFloat top = self.subdate.bottom;
            CGFloat height = SCREEN_HEIGHT - top - TabbarHeight;
            CGRectMake(0, top, SCREEN_WIDTH, height);
        })];
        [self.view addSubview:_table];
    }
    return _table;
}
- (ChartHUD *)chud {
    if (!_chud) {
        @weakify(self)
        _chud = [ChartHUD loadCode:CGRectMake(0, _seg.bottom, SCREEN_WIDTH, SCREEN_HEIGHT - _seg.bottom - TabbarHeight)];
        [_chud setComplete:^(NSInteger index) {
            @strongify(self)
            [self setSelectIndex:index];
            [self bookRangeRequest];
        }];
        [self.view addSubview:_chud];
    }
    return _chud;
}


@end

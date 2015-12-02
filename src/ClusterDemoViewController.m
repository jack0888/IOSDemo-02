//
//  ClusterDemoViewController.m
//  IphoneMapSdkDemo
//
//  Created by wzy on 15/9/18.
//  Copyright © 2015年 Baidu. All rights reserved.
//

#import "ClusterDemoViewController.h"
#import "BMKClusterManager.h"

/*
 *点聚合Annotation
 */
@interface ClusterAnnotation : BMKPointAnnotation

///所包含annotation个数
@property (nonatomic, assign) NSInteger size;
@end

@implementation ClusterAnnotation
@synthesize size = _size;
@end


/*
 *点聚合AnnotationView
 */
@interface ClusterAnnotationView : BMKPinAnnotationView {
    
}

@property (nonatomic, assign) NSInteger size;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UILabel *labelTitle;

@end

@implementation ClusterAnnotationView

@synthesize size = _size;
@synthesize label = _label;
@synthesize labelTitle = _labelTitle;

- (id)initWithAnnotation:(id<BMKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setBounds:CGRectMake(0.f, 0.f, 77.f, 77.f)];
        
        UIImageView *borderImage=[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 75, 108)];
        [borderImage setImage:[UIImage imageNamed:@"首页景点图片框.png"]];
        [self addSubview:borderImage];
        
        UILabel *shadow=[[UILabel alloc] initWithFrame:CGRectMake(31.f, 108.f, 14.f, 8.f)];
        shadow.layer.borderWidth = 10;
        shadow.layer.cornerRadius = 4;
        shadow.layer.borderColor = [UIColor grayColor].CGColor;
        shadow.layer.shadowColor = [UIColor blackColor].CGColor;
        shadow.layer.shadowOpacity = 1.0;
        shadow.layer.shadowRadius = 10.0;
        shadow.layer.shadowOffset = CGSizeMake(0, 3);
        shadow.clipsToBounds = NO;
        [self addSubview:shadow];
        
        _label = [[UILabel alloc] initWithFrame:CGRectMake(-5.f, -5.f, 20.f, 20.f)];
        _label.textColor = [UIColor whiteColor];
        [_label.layer setMasksToBounds:YES];
        _label.layer.cornerRadius = 10;
        _label.font = [UIFont systemFontOfSize:11];
        _label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_label];
        
        _labelTitle = [[UILabel alloc] initWithFrame:CGRectMake(2.f, 75.f, 73.f, 20.f)];
        _labelTitle.textColor = [UIColor blackColor];
        _labelTitle.font = [UIFont systemFontOfSize:11];
        _labelTitle.textAlignment = NSTextAlignmentCenter;
        _labelTitle.backgroundColor=[UIColor whiteColor];
        _labelTitle.alpha=1;
        [self addSubview:_labelTitle];
        
        self.alpha = 1;
    }
    return self;
}

- (void)setSize:(NSInteger)size {
    _size = size;
    if (_size == 1) {
        self.label.hidden = YES;
        self.pinColor = BMKPinAnnotationColorRed;
        return;
    }
    self.label.hidden = NO;
    if (size > 20) {
        self.label.backgroundColor = [UIColor redColor];
    } else if (size > 10) {
        self.label.backgroundColor = [UIColor purpleColor];
    } else if (size > 5) {
        self.label.backgroundColor = [UIColor blueColor];
    } else {
        self.label.backgroundColor = [UIColor greenColor];
    }
    self.label.backgroundColor = [UIColor colorWithRed:89/255.0 green:205/255.0 blue:62/255.0 alpha:1];
    _label.text = [NSString stringWithFormat:@"%ld", (long)size];
    _labelTitle.text = @"NULL";
}

@end

@interface ClusterDemoViewController() {
    BMKClusterManager *_clusterManager;//点聚合管理类
    NSInteger _clusterZoom;//聚合级别
    NSMutableArray *_clusterCaches;//点聚合缓存标注
}

@end


@implementation ClusterDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //适配ios7
    if( ([[[UIDevice currentDevice] systemVersion] doubleValue]>=7.0)) {
        self.navigationController.navigationBar.translucent = NO;
    }
    
    _clusterCaches = [[NSMutableArray alloc] init];
    for (NSInteger i = 3; i < 21; i++) {
        [_clusterCaches addObject:[NSMutableArray array]];
    }
    
    //点聚合管理类
    _clusterManager = [[BMKClusterManager alloc] init];
    CLLocationCoordinate2D coor = CLLocationCoordinate2DMake(39.915, 116.404);
    //向点聚合管理类中添加标注
    for (NSInteger i = 0; i < 20; i++) {
        double lat =  (arc4random() % 100) * 0.001f;
        double lon =  (arc4random() % 100) * 0.001f;
        BMKClusterItem *clusterItem = [[BMKClusterItem alloc] init];
        clusterItem.coor = CLLocationCoordinate2DMake(coor.latitude + lat, coor.longitude + lon);
        [_clusterManager addClusterItem:clusterItem];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_mapView viewWillAppear];
    _mapView.delegate = self; // 此处记得不用的时候需要置nil，否则影响内存的释放
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_mapView viewWillDisappear];
    _mapView.delegate = nil; // 不用时，置nil
}
- (void)viewDidUnload {
    [super viewDidUnload];
}
- (void)dealloc {
    if (_mapView) {
        _mapView = nil;
    }
}

//更新聚合状态
- (void)updateClusters {
    _clusterZoom = (NSInteger)_mapView.zoomLevel;
    @synchronized(_clusterCaches) {
        __block NSMutableArray *clusters = [_clusterCaches objectAtIndex:(_clusterZoom - 3)];
        
        if (clusters.count > 0) {
            [_mapView removeAnnotations:_mapView.annotations];
            [_mapView addAnnotations:clusters];
        } else {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                ///获取聚合后的标注
                __block NSArray *array = [_clusterManager getClusters:_clusterZoom];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    for (int i=0;i<[array count];i++) {
                        BMKCluster *item=array[i];
                        ClusterAnnotation *annotation = [[ClusterAnnotation alloc] init];
                        annotation.coordinate = item.coordinate;
                        annotation.size = item.size;
//                        ParkEntity *entity = nil;//homeEntity.mutableArrayPark[i];
//                        int k;
//                        for(k=0;k<[homeEntity.mutableArrayPark count];k++){
//                            ParkEntity *entityTemp=homeEntity.mutableArrayPark[k];
//                            if([entityTemp.title isEqualToString:item.name]==YES){
//                                entity = entityTemp;
//                                break;
//                            }
//                        }
//                        annotation.title = [NSString stringWithFormat:@"%d",k];
//                        annotation.subtitle = entity.album_thumb;
                        [clusters addObject:annotation];
                    }
                    
                    [_mapView removeAnnotations:_mapView.annotations];
                    [_mapView addAnnotations:clusters];
                    
//                    if(setMapCenter==YES && [homeEntity.mutableArrayPark count]>0){
//                        ParkEntity *entity = homeEntity.mutableArrayPark[0];
//                        CLLocation *location = [[CLLocation alloc] initWithLatitude:[entity.latitude doubleValue] longitude:[entity.longitude doubleValue]];
//                        [_mapView setCenterCoordinate:location.coordinate animated:NO];
//                        setMapCenter=NO;
//                        _mapView.zoomLevel=mapZoomLevel;
//                    }
                });
            });
        }
    }
}

#pragma mark - BMKMapViewDelegate
// 根据anntation生成对应的View
- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation
{
    //普通annotation
    NSString *AnnotationViewID = @"ClusterMark";
    ClusterAnnotation *cluster = (ClusterAnnotation*)annotation;
    ClusterAnnotationView *annotationView = [[ClusterAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationViewID];
    annotationView.size = cluster.size;
    annotationView.canShowCallout = NO;//在点击大头针的时候会弹出那个黑框框
    annotationView.draggable = NO;//禁止标注在地图上拖动
    annotationView.annotation = cluster;
    //    annotationView.image=[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:annotation.subtitle]]];
    annotationView.centerOffset=CGPointMake(0,-80);
    
    UIView *viewForImage=[[UIView alloc]init];
    UIImageView *imageview=[[UIImageView alloc]init];
    NSLog(@"========%d",[UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) : NO);
    if([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) : NO){
        [viewForImage setFrame:CGRectMake(0, 0, 225, 225)];
        [imageview setFrame:CGRectMake(0, 0, 225, 225)];
    }else{
        [viewForImage setFrame:CGRectMake(0, 0, 150, 150)];
        [imageview setFrame:CGRectMake(0, 0, 150, 150)];
    }
    //同步加载
    //    [imageview setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:annotation.subtitle]]]];
    //异步加载
    //    [imageview sd_setImageWithURL:[NSURL URLWithString:annotation.subtitle] placeholderImage:[UIImage imageNamed:@"placehodeLoading.png"]];
    
//    [imageview sd_setImageWithURL:[NSURL URLWithString:annotation.subtitle] placeholderImage:[UIImage imageNamed:@"placehodeLoading.png"] options:SDWebImageLowPriority | SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
//     {
//         annotationView.image=[self getImageFromView:viewForImage];//修改默认图片不替换问题
//     }];
    
    [imageview setImage:[UIImage imageNamed:@"placehodeLoading.png"]];
    
    imageview.layer.masksToBounds=YES;
    imageview.layer.cornerRadius = 10;
    [viewForImage addSubview:imageview];
    annotationView.image=[self getImageFromView:viewForImage];
//    if([homeEntity.mutableArrayPark count]>0){
//        int index = [cluster.title intValue];
//        ParkEntity *entity = homeEntity.mutableArrayPark[index];
//        annotationView.labelTitle.text = entity.title;
//    }
    return annotationView;
}

-(UIImage *)getImageFromView:(UIView *)view{
    UIGraphicsBeginImageContext(view.bounds.size);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

/**
 *当点击annotation view弹出的泡泡时，调用此接口
 *@param mapView 地图View
 *@param view 泡泡所属的annotation view
 */
- (void)mapView:(BMKMapView *)mapView annotationViewForBubble:(BMKAnnotationView *)view {
    if ([view isKindOfClass:[ClusterAnnotationView class]]) {
        ClusterAnnotation *clusterAnnotation = (ClusterAnnotation*)view.annotation;
        if (clusterAnnotation.size > 1) {
            [mapView setCenterCoordinate:view.annotation.coordinate];
            [mapView zoomIn];
        }
    }
}

/**
 *地图初始化完毕时会调用此接口
 *@param mapview 地图View
 */
- (void)mapViewDidFinishLoading:(BMKMapView *)mapView {
    [self updateClusters];
}

/**
 *地图渲染每一帧画面过程中，以及每次需要重绘地图时（例如添加覆盖物）都会调用此接口
 *@param mapview 地图View
 *@param status 此时地图的状态
 */
- (void)mapView:(BMKMapView *)mapView onDrawMapFrame:(BMKMapStatus *)status {
    if (_clusterZoom != 0 && _clusterZoom != (NSInteger)mapView.zoomLevel) {
        [self updateClusters];
    }
}

-(void)mapView:(BMKMapView *)mapView didSelectAnnotationView:(BMKAnnotationView *)view {
    if ([view isKindOfClass:[ClusterAnnotationView class]]) {
        ClusterAnnotation *clusterAnnotation = (ClusterAnnotation*)view.annotation;
        if (clusterAnnotation.size > 1) {
            [mapView setCenterCoordinate:view.annotation.coordinate];
            [mapView zoomIn];
        }else {
//            ParkEntity *entity = [homeEntity.mutableArrayPark objectAtIndex:[clusterAnnotation.title integerValue]];
//            if ([entity.is_business isEqualToString:@"0"] == YES) {
//                IntroduceViewController *vc = [[IntroduceViewController alloc] init];
//                vc.parkEntity = entity;
//                [self.navigationController pushViewController:vc animated:YES];
//            } else {
//                WrapperViewController *vc = [[WrapperViewController alloc] init];
//                vc.parkEntity = entity;
//                [self.navigationController pushViewController:vc animated:YES];
//            }
        }
    }
    [_mapView deselectAnnotation:view.annotation animated:YES];
}

@end

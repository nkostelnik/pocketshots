#import "TimelineViewController.h"

#import "NSBundle+Documents.h"

#import "TimelineCollectionViewCell.h"
#import "PhotoViewController.h"

#import "PhotoAlbum.h"
#import "Photo.h"

@interface UIBarButtonItem(MyCategory)

+ (UIBarButtonItem*)barItemWithImage:(UIImage*)image target:(id)target action:(SEL)action;

@end

@implementation UIBarButtonItem(MyCategory)

+ (UIBarButtonItem*)barItemWithImage:(UIImage*)image target:(id)target action:(SEL)action{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  
  button.frame = CGRectMake(0.0, 00.0, image.size.width, image.size.height);
  [button setBackgroundImage:image forState:UIControlStateNormal];
  [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
  
  UIView* view = [[UIView alloc] initWithFrame:button.frame];
  [view addSubview:button];
  
  UIBarButtonItem* forward = [[UIBarButtonItem alloc] initWithCustomView:view];
  return forward;
}

@end

@interface TimelineViewController ()

@end

@implementation TimelineViewController

@synthesize photosCollectionView;

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    photoAlbum = [[PhotoAlbum alloc] initWithDirectory:[NSBundle mainBundle].documentsPath];
    cellsLoaded = 0;
  }
  return self;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return photoAlbum.photoCount;
}

- (void)newPhoto {
  [self performSegueWithIdentifier:@"photo" sender:self];
}

- (void)viewDidLoad {
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
  
  emptyViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EmptyViewController"];
  [self addChildViewController:emptyViewController];
  
  self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:37/255.0 green:38/255.0 blue:40/255.0 alpha:1.0f];
  self.navigationController.toolbar.barTintColor = [UIColor colorWithRed:37/255.0 green:38/255.0 blue:40/255.0 alpha:1.0f];
  
  UIImage *buttonImage = [UIImage imageNamed:@"CameraButton"];
  UIBarButtonItem* cameraButtonItem = [UIBarButtonItem barItemWithImage:buttonImage target:self action:@selector(newPhoto)];
  UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [self setToolbarItems:[NSArray arrayWithObjects:left, cameraButtonItem, right, nil] animated:YES];
}

- (void)animateInNav {
  [self.navigationController setNavigationBarHidden:NO animated:YES];
  [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)resetCellsLoaded {
  cellsLoaded = 0;
}

- (void)animateInContent {
  photosCollectionView.delegate = self;
  [photoAlbum loadPhotos];
  [photosCollectionView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  if (cellsLoaded < 1) {
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.navigationController setToolbarHidden:YES animated:NO];

    [self performSelector:@selector(animateInNav) withObject:nil afterDelay:0.5];
    [self performSelector:@selector(animateInContent) withObject:nil afterDelay:1.0];
  } else {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    photosCollectionView.delegate = self;
    [photoAlbum loadPhotos];
    [photosCollectionView reloadData];
  }
  
  PhotoAlbum* dummyPhotoAlbum = [[PhotoAlbum alloc] initWithDirectory:[NSBundle mainBundle].documentsPath];
  [dummyPhotoAlbum loadPhotos];
  
  if (dummyPhotoAlbum.photoCount <= 0) {
    photosCollectionView.emptyState_view = emptyViewController.view;
  } else {
    photosCollectionView.emptyState_view = nil;
  }
  
  
  self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [UIColor whiteColor],NSForegroundColorAttributeName,
                                  [UIColor whiteColor],NSBackgroundColorAttributeName,
                                  [UIFont fontWithName:@"Futura-CondensedExtraBold" size:21.0], NSFontAttributeName,
                                  nil];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  photosCollectionView.delegate = nil;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  TimelineCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCollectonViewCell" forIndexPath:indexPath];
  
  Photo* photo = [photoAlbum photoAtIndex:indexPath.row];
  cell.photo.image = [UIImage imageWithContentsOfFile:photo.path];
  cell.photoPath = photo.path;
  
  cell.date.attributedText = photo.formattedDate;
  cell.timelineViewController = self;
  cell.initialFrame = cell.frame;
  
  UIGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDetected:)];
  panGestureRecognizer.delegate = self;
  [cell addGestureRecognizer:panGestureRecognizer];
  
  [collectionView.panGestureRecognizer requireGestureRecognizerToFail:panGestureRecognizer];
  
  if (cellsLoaded++ < 2) {
    CGFloat y = cell.center.y;
    cell.center = CGPointMake(cell.center.x, cell.center.y + 500);
    [UIView animateWithDuration:0.75 animations:^{
      cell.center = CGPointMake(cell.center.x, y);
    }];
  }
  
  return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  BOOL isDetailSegue = [segue.identifier isEqualToString:@"detail"];
  if (isDetailSegue) {
    TimelineCollectionViewCell* timeLineCollectionViewCell = sender;
    PhotoViewController* photoViewController = segue.destinationViewController;
    [photoViewController setPhotoPath:timeLineCollectionViewCell.photoPath];
  }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  
  float scrollOffset = scrollView.contentOffset.y;
  if (scrollOffset <= 0) {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController setToolbarHidden:NO animated:YES];
    return;
  }

  CGPoint translation = [scrollView.panGestureRecognizer translationInView:scrollView.superview];

  if (translation.y > 0) {
    if (translation.y > 150) {
      [self.navigationController setNavigationBarHidden:NO animated:YES];
      [self.navigationController setToolbarHidden:NO animated:YES];
    }
  } else {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController setToolbarHidden:YES animated:YES];
  }
}

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer {
  CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view];
  BOOL result = (translation.y * translation.y < translation.x * translation.x);
  return result;
}

- (void)panDetected:(UIPanGestureRecognizer *)panRecognizer {
  if (panRecognizer.state == UIGestureRecognizerStateBegan) {
    TimelineCollectionViewCell* contentContainer =  (TimelineCollectionViewCell*)panRecognizer.view;
    contentContainer.initialFrame = contentContainer.frame;
  }
  
  if (panRecognizer.state == UIGestureRecognizerStateChanged) {
    TimelineCollectionViewCell* contentContainer =  (TimelineCollectionViewCell*)panRecognizer.view;
    
    CGPoint translation = [panRecognizer translationInView:panRecognizer.view];
    
    CGPoint viewPosition = contentContainer.center;
    viewPosition.x += translation.x;
    if (viewPosition.x <= 160) {
      contentContainer.center = viewPosition;
      [panRecognizer setTranslation:CGPointZero inView:panRecognizer.view];
    }
  }
  
  if (panRecognizer.state == UIGestureRecognizerStateEnded) {
    TimelineCollectionViewCell* cell = (TimelineCollectionViewCell*)panRecognizer.view;
    if (panRecognizer.view.center.x < 50) {
      [UIView animateWithDuration:0.4
                       animations:^{panRecognizer.view.frame = CGRectMake(panRecognizer.view.frame.origin.x - 500, panRecognizer.view.frame.origin.y, panRecognizer.view.frame.size.width, panRecognizer.view.frame.size.height);}
                       completion:^(BOOL finished) {
                         
                         UIAlertView* deleteAlert = [[UIAlertView alloc] initWithTitle:@"Delete Photo"
                                                                               message:@"Are you sure?"
                                                                              delegate:self
                                                                     cancelButtonTitle:@"Cancel"
                                                                     otherButtonTitles:@"Delete", nil];
                         deleteAlert.tag = [photosCollectionView indexPathForCell:cell].row;
                         [deleteAlert show];
                         
                         [cell setHidden:YES];
                       }];
    } else {
      TimelineCollectionViewCell* contentContainer =  (TimelineCollectionViewCell*)panRecognizer.view;
      [UIView animateWithDuration:0.2
                       animations:^{panRecognizer.view.frame = contentContainer.initialFrame; }
                       completion: nil];
    }
  }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (1 == buttonIndex) {
    TimelineCollectionViewCell* cell = (TimelineCollectionViewCell*)[photosCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:alertView.tag inSection:0]];
    [self deletePhotoCell:cell];
  }
  
  if (0 == buttonIndex) {
    TimelineCollectionViewCell* cell =  (TimelineCollectionViewCell*)[photosCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:alertView.tag inSection:0]];
    [UIView animateWithDuration:0.2
                     animations:^{cell.frame = cell.initialFrame; }
                     completion: nil];
  }
}

- (void)deletePhotoCell:(TimelineCollectionViewCell*)viewCell {
  [photoAlbum deletePhoto:viewCell.photoPath];
  NSIndexPath* indexPath = [photosCollectionView indexPathForCell:viewCell];
  
  if (photoAlbum.photoCount <= 0) {
    photosCollectionView.emptyState_view = emptyViewController.view;
  }
  
  [photosCollectionView deleteItemsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil]];
}

@end

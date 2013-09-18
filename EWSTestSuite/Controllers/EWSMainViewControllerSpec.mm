#import <CoreData/CoreData.h>
#import "EWSMainViewController.h"
#import "EWSAPIClient.h"
#import "EWSMainLabTableViewCell.h"
#import "SpecFactories.h"
#import <objc/runtime.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface EWSMainViewController (SpecTest)

@property (nonatomic, strong) NSFetchedResultsController *fetchedRequestController;

@end

SPEC_BEGIN(EWSMainViewControllerSpec)

describe(@"EWSMainViewController", ^{
    __block EWSMainViewController<UITableViewDataSource, UITableViewDelegate, EWSMainLabTableViewCellLabNotificationProtocol>
    *mainVC;

    beforeEach(^{
        mainVC = [[EWSMainViewController alloc] initWithNibName:nil bundle:nil];
        [mainVC viewDidLoad];
        NSLog(@"mainVc conforms   %@", [NSNumber numberWithBool:[mainVC conformsToProtocol:@protocol(UITableViewDelegate)]]);
        NSLog(@"mainVc conforms   %@", [NSNumber numberWithBool:[mainVC conformsToProtocol:@protocol(UITableViewDataSource)]]);

        spy_on(mainVC);
        
        mainVC stub_method("showProgressHudWhilePolling");
        mainVC stub_method("updateLabUsage");
    });
    
    context(@"valid properties", ^{
        it(@"should not want fullLayout", ^{
            mainVC.wantsFullScreenLayout should_not be_truthy;
        });
        
        it(@"should have a blackOpaqueStatusBar", ^{
            [mainVC preferredStatusBarStyle] should equal(UIStatusBarStyleBlackOpaque);
        });
        it(@"should have a mainTableView", ^{
            [mainVC respondsToSelector:@selector(mainTableView)] should be_truthy;
        });
        
        describe(@"mainTableView", ^{
            it(@"should have mainVC as its delegates for protocols", ^{
                mainVC.mainTableView.delegate should equal(mainVC);
                mainVC.mainTableView.dataSource should equal(mainVC);
            });
        });
        
        context(@"private properties", ^{
            describe(@"fetchedRequestController", ^{
                it(@"should always return exactly one section", ^{
                    [[mainVC.fetchedRequestController sections] count] should equal(1);
                });
                
//                it(@"should always return 13 elements in the section", ^{
//                    NSArray *sections = [mainVC.fetchedRequestController sections];
//                    [[sections[0] objects] count] should equal(13);
//                });
            });
        });
        
    });
 
    context(@"UITableViewProtocol methods", ^{
        describe(@"tableView:heightForRowAtIndexPath:", ^{
            it(@"should return 64", ^{
                CGFloat height = [mainVC tableView:mainVC.mainTableView heightForRowAtIndexPath:nil];
                height should equal(64);
            });
        });
    });
    
    context(@"UIAlertViewDelegate methods", ^{
        describe(@"alertView:ClickedButtonAtIndex:", ^{
            it(@"should unregister the cell at index 0", ^{
                UIAlertView *testAlertView = [[UIAlertView alloc] initWithTitle:nil
                                                                        message:nil
                                                                       delegate:mainVC
                                                              cancelButtonTitle:@"wtf"
                                                              otherButtonTitles:@"hi", nil];
                [mainVC alertView:testAlertView clickedButtonAtIndex:0];
                
            });
        });
    });

    context(@"EWSMainLabTableViewCellLabNotificationProtocol methods", ^{
        describe(@"#userTappedTicketStatusButton:", ^{
            context(@"lab eligibility", ^{
                __block EWSMainLabTableViewCell *testCell;
                
                beforeEach(^{
                    testCell = [[EWSMainLabTableViewCell alloc] init];
                    [testCell setDelegate:mainVC];
                    spy_on(mainVC);
                    mainVC stub_method("showAlertViewForIneligibleLabNotification");
                    mainVC stub_method("promptRegistrationCancellation:");
                });
                
                it(@"should present a modalViewController if it is eligible for notification", ^{
                    EWSLab *eligibleLab = [EWSLab labFactoryValidForNotification];
                    [testCell setLabObject:eligibleLab];
                    [mainVC userTappedTicketStatusButton:testCell];
                    mainVC should have_received("presentViewController:animated:completion:");
                });
                
                it(@"should not present a modalViewController if it is ineligible for notification", ^{
                    EWSLab *ineligibleLab = [EWSLab labFactoryNotValidForNotification];
                    [testCell setLabObject:ineligibleLab];
                    [mainVC userTappedTicketStatusButton:testCell];
                    mainVC should_not have_received("presentViewController:animated:completion:");
                });
                
                it(@"should show an alertView when the lab is ineligible for notification", ^{
                    EWSLab *ineligibleLab = [EWSLab labFactoryNotValidForNotification];
                    [testCell setLabObject:ineligibleLab];
                    //                mainVC stub_method("showAlertViewForIneligibleLabNotification");
                    [mainVC userTappedTicketStatusButton:testCell];
                    mainVC should have_received("showAlertViewForIneligibleLabNotification");
                });
                
            });
            
            context(@"when the cell is already registered", ^{
                __block EWSMainLabTableViewCell *testCell;
                
                beforeEach(^{
                    testCell = [[EWSMainLabTableViewCell alloc] init];
                    [testCell setLabObject:[EWSLab labFactoryRegisteredForNotification]];
                    [testCell setDelegate:mainVC];
                });
                
                it(@"should not present notificationViewController", ^{
                    spy_on(mainVC);
                    mainVC stub_method("promptRegistrationCancellation:");
                    [mainVC userTappedTicketStatusButton:testCell];
                    mainVC should_not have_received("presentViewController:animated:completion:");
                });
                
                it(@"should call promptRegistrationCancellation", ^{
                    spy_on(mainVC);
                    mainVC stub_method("promptRegistrationCancellation:");
                    [mainVC userTappedTicketStatusButton:testCell];
                    mainVC should have_received("promptRegistrationCancellation:");
                });
            });
        });
    });
    
});

SPEC_END

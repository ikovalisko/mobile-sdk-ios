/*   Copyright 2013 APPNEXUS INC
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "AdSettingsTVC.h"
#import "AdSettings.h"
#import "DataDisplayHelper.h"
#import "NoCaretUITextField.h"
#import "ANLogging.h"
#import "ANAdProtocol.h"
#import "AppNexusSDKAppSectionHeaderView.h"
#import "AppNexusSDKAppModalViewController.h"
#import "CustomKeywordsTVC.h"

#define CLASS_NAME @"AdSettingsTVC"

#define INVALID_HEX_ALERT_TITLE @""
#define INVALID_HEX_ALERT_MESSAGE @"Invalid Hex Color. Please specify color in ARGB format."
#define INVALID_HEX_ALERT_CANCEL @"OK"

#pragma mark Section Header Constants

static NSString *const AdSettingsSectionHeaderViewIdentifier = @"AdSettingsSectionHeaderViewIdentifier";

static NSInteger const AdSettingsSectionHeaderGeneralIndex = 0;
static NSInteger const AdSettingsSectionHeaderAdvancedIndex = 1;

static NSInteger const AdSettingsSectionGeneralNumRows = 5;
static NSInteger const AdSettingsSectionAdvancedNumRows = 8;

static BOOL AdSettingsSectionGeneralIsOpen = YES;
static BOOL AdSettingsSectionAdvancedIsOpen = NO;

static NSString *const AdSettingsSectionHeaderTitleLabelGeneral = @"General";
static NSString *const AdSettingsSectionHeaderTitleLabelAdvanced = @"Advanced";

#pragma end

@interface AdSettingsTVC () <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource,
AppNexusSDKAppSectionHeaderViewDelegate, AppNexusSDKAppModalViewControllerDelegate>

@property (strong, nonatomic) AdSettings *persistentSettings;

#pragma mark General
@property (weak, nonatomic) IBOutlet UISegmentedControl *adTypeToggle;
@property (weak, nonatomic) IBOutlet UISegmentedControl *allowPSAToggle;
@property (weak, nonatomic) IBOutlet UISegmentedControl *browserTypeToggle;
@property (weak, nonatomic) IBOutlet UITextField *placementIDTextField;
@property (weak, nonatomic) IBOutlet UITextField *ageTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderToggle;
@property (weak, nonatomic) IBOutlet UITextField *reserveTextField;

# pragma mark Banner
@property (weak, nonatomic) IBOutlet NoCaretUITextField *sizeTextField;
@property (strong, nonatomic) UIPickerView *sizePickerView;

@property (weak, nonatomic) IBOutlet NoCaretUITextField *refreshRateTextField;
@property (strong, nonatomic) UIPickerView *refreshRatePickerView;

#pragma mark Interstitial
@property (weak, nonatomic) IBOutlet UITextField *backgroundColorTextField;
@property (weak, nonatomic) IBOutlet UIView *colorView;

#pragma mark Debug
@property (weak, nonatomic) IBOutlet UITextField *memberIDTextField;
@property (weak, nonatomic) IBOutlet UITextField *dongleTextField;

@end

@implementation AdSettingsTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self currentSettingsSetup];
    
    UINib *sectionHeaderNib = [UINib nibWithNibName:@"AppNexusSDKAppSectionHeaderView" bundle:nil];
    [self.tableView registerNib:sectionHeaderNib forHeaderFooterViewReuseIdentifier:AdSettingsSectionHeaderViewIdentifier];
}

- (IBAction)makeKeyboardDisappear:(id)sender {
    [sender resignFirstResponder];
}

#pragma mark Current Settings Setup

- (void)currentSettingsSetup {
    DataDisplayHelper *helper = [[DataDisplayHelper alloc] init];
    self.sizeDelegate = helper;
    self.refreshRateDelegate = helper;
    self.reservePriceDelegate = helper;
    
    [self pickerViewSetup];
    [self segmentedControlsSetup];
    [self textFieldsSetup];
}

#pragma mark Picker Views - Initial Setup

- (void)pickerViewSetup {
    
    self.sizePickerView = [self generatePickerView];
    self.sizeTextField.inputView = self.sizePickerView;
    self.sizePickerView.delegate = self;
    [self.sizePickerView selectRow:[[self.sizeDelegate class]
                                    indexForBannerSizeWithWidth:self.persistentSettings.bannerWidth
                                    height:self.persistentSettings.bannerHeight]
                       inComponent:0
                          animated:NO];
    
    self.refreshRatePickerView = [self generatePickerView];
    self.refreshRateTextField.inputView = self.refreshRatePickerView;
    self.refreshRatePickerView.delegate = self;
    [self.refreshRatePickerView selectRow:[[self.refreshRateDelegate class] indexForRefreshRate:self.persistentSettings.refreshRate]
                              inComponent:0
                                 animated:NO];
}

#pragma mark Picker Views - Delegate Methods

- (UIPickerView *)generatePickerView {
    return [[UIPickerView alloc] initWithFrame:CGRectMake(0.0,0.0,self.view.frame.size.width,162.0)];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    // Update persistent ad settings on change
    if (pickerView == self.sizePickerView) {
        [self saveAdWidth:[[self.sizeDelegate class] bannerWidthAtIndex:row]
             andAdHeight:[[self.sizeDelegate class] bannerHeightAtIndex:row]];
        [self.sizeTextField sendActionsForControlEvents:UIControlEventEditingChanged];
    } else if (pickerView == self.refreshRatePickerView) {
        [self saveRefreshRate:[[self.refreshRateDelegate class] refreshRateAtIndex:row]];
        [self.refreshRateTextField sendActionsForControlEvents:UIControlEventEditingChanged];
    }
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (pickerView == self.sizePickerView) {
        return [[self.sizeDelegate class] sizeCount]; // return number of sizes
    } else if (pickerView == self.refreshRatePickerView) {
        return [[self.refreshRateDelegate class] refreshRateCount]; // return number of refresh rates
    }
    return 0;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1; // This picker view only has one column
}


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (pickerView == self.sizePickerView) {
        return [[self.sizeDelegate class] sizeStringAtIndex:row]; // return size at array index
    } else if (pickerView == self.refreshRatePickerView) {
        return [[self.refreshRateDelegate class] refreshRateStringAtIndex:row]; // return refresh rate at array index
    }
    return @"";
}

#pragma mark Picker Views - On Tap

- (IBAction)refreshRateTap:(UITapGestureRecognizer *)sender {
    if ([self.refreshRateTextField isEditing]) {
        [self.refreshRateTextField resignFirstResponder];
    } else {
        [self.refreshRateTextField becomeFirstResponder];
    }
}

- (IBAction)sizeTap:(UITapGestureRecognizer *)sender {
    if ([self.sizeTextField isEditing]) {
        [self.sizeTextField resignFirstResponder];
    } else {
        [self.sizeTextField becomeFirstResponder];
    }
}

#pragma mark Persistent Settings

- (AdSettings *)persistentSettings {
    if (!_persistentSettings) _persistentSettings = [[AdSettings alloc] init];
    return _persistentSettings;
}

- (void)saveAdWidth:(NSInteger)width andAdHeight:(NSInteger)height {
    self.persistentSettings.bannerWidth = width;
    self.persistentSettings.bannerHeight = height;
    self.sizeTextField.text = [[self.sizeDelegate class] bannerSizeWithWidth:self.persistentSettings.bannerWidth
                                                                      height:self.persistentSettings.bannerHeight];
}

- (void)saveRefreshRate:(NSInteger)refreshRate {
    self.persistentSettings.refreshRate = refreshRate;
    self.refreshRateTextField.text = [[self.refreshRateDelegate class] refreshRateStringFromInteger:self.persistentSettings.refreshRate];
}

- (void)saveMemberID:(NSInteger)memberID {
    self.persistentSettings.memberID = memberID;
}

- (void)savePlacementID:(NSInteger)placementID {
    self.persistentSettings.placementID = placementID;
}

- (void)saveDongle:(NSString *)dongle {
    self.persistentSettings.dongle = dongle;
}

- (void)saveAdType:(NSInteger)adType {
    self.persistentSettings.adType = adType;
}

- (void)saveBrowser:(NSInteger)browserType {
    self.persistentSettings.browserType = browserType;
}

- (void)saveAllowPSA:(BOOL)allowPSA {
    self.persistentSettings.allowPSA = allowPSA;
}

- (void)saveReserve:(double)reserve {
    self.persistentSettings.reserve = reserve;
}

- (void)saveAge:(NSString *)age {
    self.persistentSettings.age = age;
}

- (void)saveGender:(NSInteger)gender {
    self.persistentSettings.gender = gender;
}

- (BOOL)saveBackgroundColor:(NSString *)backgroundColor {
    if ([AdSettings backgroundColorIsValid:backgroundColor]) {
        self.persistentSettings.backgroundColor = backgroundColor; // Save as is, regardless of case
        // change color of UIView
        return YES;
    }
    
    return NO;
}

#pragma mark Text Fields - Initial Setup

- (void)textFieldsSetup {
    self.refreshRateTextField.text = [[self.refreshRateDelegate class] refreshRateStringFromInteger:self.persistentSettings.refreshRate];
    self.sizeTextField.text = [[self.sizeDelegate class] bannerSizeWithWidth:self.persistentSettings.bannerWidth
                                                                      height:self.persistentSettings.bannerHeight];
    
    self.memberIDTextField.text = [NSString stringWithFormat:@"%d", self.persistentSettings.memberID];
    self.dongleTextField.text = self.persistentSettings.dongle;
    self.placementIDTextField.text = [NSString stringWithFormat:@"%d", self.persistentSettings.placementID];
    self.backgroundColorTextField.text = self.persistentSettings.backgroundColor;
    self.ageTextField.text = self.persistentSettings.age;
    self.reserveTextField.text = [[self.reservePriceDelegate class] stringFromReservePrice:self.persistentSettings.reserve];
}

#pragma mark Text Fields - On Tap

- (IBAction)memberIDTap:(UITapGestureRecognizer *)sender {
    if ([self.memberIDTextField isEditing]) {
        [self.memberIDTextField resignFirstResponder];
    } else {
        [self saveTextFieldSettings];
        [self.memberIDTextField becomeFirstResponder];
    }
}

- (IBAction)placementIDTap:(UITapGestureRecognizer *)sender {
    if ([self.placementIDTextField isEditing]) {
        [self.placementIDTextField resignFirstResponder];
    } else {
        [self saveTextFieldSettings];
        [self.placementIDTextField becomeFirstResponder];
    }
}

- (IBAction)dongleTap:(UITapGestureRecognizer *)sender {
    if ([self.dongleTextField isEditing]) {
        [self.dongleTextField resignFirstResponder];
    } else {
        [self saveTextFieldSettings];
        [self.dongleTextField becomeFirstResponder];
    }
}
- (IBAction)backgroundColorTap:(UITapGestureRecognizer *)sender {
    if ([self.backgroundColorTextField isEditing]) {
        [self.backgroundColorTextField resignFirstResponder];
    } else {
        [self saveTextFieldSettings];
        [self.backgroundColorTextField becomeFirstResponder];
    }
}

- (IBAction)ageTap:(UITapGestureRecognizer *)sender {
    if ([self.ageTextField isEditing]) {
        [self.ageTextField resignFirstResponder];
    } else {
        [self saveTextFieldSettings];
        [self.ageTextField becomeFirstResponder];
    }
}

- (IBAction)reserveTap:(UITapGestureRecognizer *)sender {
    if ([self.reserveTextField isEditing]) {
        [self.reserveTextField resignFirstResponder];
    } else {
        [self saveTextFieldSettings];
        [self.reserveTextField becomeFirstResponder];
    }
}

#pragma mark Text Fields - Did End

- (IBAction)placementEditDidEnd:(UITextField *)sender {
    [self savePlacementID:[self.placementIDTextField.text intValue]];
}

- (IBAction)backgroundColorEditDidEnd:(UITextField *)sender {
    [self handleBackgroundColorChange];
}

- (IBAction)memberIDEditDidEnd:(UITextField *)sender {
    [self saveMemberID:[self.memberIDTextField.text intValue]];
}

- (IBAction)dongleEditDidEnd:(UITextField *)sender {
    [self saveDongle:self.dongleTextField.text];
}

- (IBAction)ageEditingDidEnd:(UITextField *)sender {
    [self saveAge:self.ageTextField.text];
}

- (IBAction)reserveEditingDidEnd:(UITextField *)sender {
    [self saveReserve:[self.reserveTextField.text doubleValue]];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView { // on scroll, save text field settings and resign any first responder
    [scrollView endEditing:YES];
}

- (void)saveTextFieldSettings {
    if ([self.memberIDTextField isEditing]) {
        [self saveMemberID:[self.memberIDTextField.text intValue]];
    }
    if ([self.dongleTextField isEditing]) {
        [self saveDongle:self.dongleTextField.text];
    }
    if ([self.placementIDTextField isEditing]) {
        [self savePlacementID:[self.placementIDTextField.text intValue]];
    }
    if ([self.backgroundColorTextField isEditing]) {
        [self handleBackgroundColorChange];
    }
    if ([self.ageTextField isEditing]) {
        [self saveAge:self.ageTextField.text];
    }
    if ([self.reserveTextField isEditing]) {
        [self saveReserve:[self.reserveTextField.text doubleValue]];
    }
}

- (void)handleBackgroundColorChange {
    BOOL isValid = [self saveBackgroundColor:self.backgroundColorTextField.text];
    if (!isValid) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:INVALID_HEX_ALERT_TITLE
                                                        message:INVALID_HEX_ALERT_MESSAGE
                                                       delegate:self
                                              cancelButtonTitle:INVALID_HEX_ALERT_CANCEL
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        self.backgroundColorTextField.text = self.persistentSettings.backgroundColor;
    }
}

#pragma mark Segmented Controls - Initial Setup 

- (void)segmentedControlsSetup {
    if (self.persistentSettings.adType == AD_TYPE_BANNER) {
        self.adTypeToggle.selectedSegmentIndex = 0;
        [self toggleAdType:YES];
    } else if (self.persistentSettings.adType == AD_TYPE_INTERSTITIAL) {
        self.adTypeToggle.selectedSegmentIndex = 1;
        [self toggleAdType:NO];
    }
    
    self.allowPSAToggle.selectedSegmentIndex = (self.persistentSettings.allowPSA) ? 0 : 1;
    
    if (self.persistentSettings.browserType == BROWSER_TYPE_IN_APP) {
        self.browserTypeToggle.selectedSegmentIndex = 0;
    } else if (self.persistentSettings.browserType == BROWSER_TYPE_DEVICE) {
        self.browserTypeToggle.selectedSegmentIndex = 1;
    }
    
    self.genderToggle.selectedSegmentIndex = self.persistentSettings.gender;
}

#pragma mark Segmented Controls - On Change

- (IBAction)setAdTypeSegmentedControl:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex) {
        [self saveAdType:AD_TYPE_INTERSTITIAL];
        [self toggleAdType:NO];
    } else {
        [self saveAdType:AD_TYPE_BANNER];
        [self toggleAdType:YES];
    }
}

- (IBAction)setAllowPSASegmentedControl:(UISegmentedControl *)sender {
    sender.selectedSegmentIndex ? [self saveAllowPSA:NO] : [self saveAllowPSA:YES];
}

- (IBAction)setBrowserSegmentedControl:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex) {
        [self saveBrowser:BROWSER_TYPE_DEVICE];
    } else {
        [self saveBrowser:BROWSER_TYPE_IN_APP];
    }
}

- (IBAction)setGenderSegmentedControl:(UISegmentedControl *)sender {
    [self saveGender:sender.selectedSegmentIndex];
}

- (void)toggleAdType:(BOOL)isBanner {
    UIColor *bannerColors = isBanner ? [UIColor orangeColor] : [UIColor grayColor];
    UIColor *interstitialColors = !isBanner ? [UIColor orangeColor] : [UIColor grayColor];
    [self.sizeTextField setUserInteractionEnabled:isBanner];
    self.sizeTextField.textColor = bannerColors;
    [self.sizePickerView setUserInteractionEnabled:isBanner];
    [self.refreshRateTextField setUserInteractionEnabled:isBanner];
    self.refreshRateTextField.textColor = bannerColors;
    [self.refreshRatePickerView setUserInteractionEnabled:isBanner];

    [self.backgroundColorTextField setUserInteractionEnabled:!isBanner];
    self.backgroundColorTextField.textColor = interstitialColors;
}

#pragma mark Section Headers

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    AppNexusSDKAppSectionHeaderView *sectionHeaderView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:AdSettingsSectionHeaderViewIdentifier];
    if (section == AdSettingsSectionHeaderGeneralIndex) {
        sectionHeaderView.titleLabel.text = AdSettingsSectionHeaderTitleLabelGeneral;
        sectionHeaderView.disclosureButton.selected = AdSettingsSectionGeneralIsOpen;
    } else if (section == AdSettingsSectionHeaderAdvancedIndex) {
        sectionHeaderView.titleLabel.text = AdSettingsSectionHeaderTitleLabelAdvanced;
        sectionHeaderView.disclosureButton.selected = AdSettingsSectionAdvancedIsOpen;
    }
    sectionHeaderView.section = section;
    sectionHeaderView.delegate = self;
    return sectionHeaderView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 48.0f;
}

- (void)sectionHeaderView:(AppNexusSDKAppSectionHeaderView *)sectionHeaderView sectionOpened:(NSInteger)section {
    NSInteger numRows = 0;
    if (section == AdSettingsSectionHeaderGeneralIndex) {
        if (AdSettingsSectionGeneralIsOpen) return;
        AdSettingsSectionGeneralIsOpen = YES;
        numRows = AdSettingsSectionGeneralNumRows;
    } else if (section == AdSettingsSectionHeaderAdvancedIndex) {
        if (AdSettingsSectionAdvancedIsOpen) return;
        AdSettingsSectionAdvancedIsOpen = YES;
        numRows = AdSettingsSectionAdvancedNumRows;
    }
    NSMutableArray *indexPathsToAdd = [[NSMutableArray alloc] init];
    for (NSInteger i=0; i < numRows; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:section];
        [indexPathsToAdd addObject:indexPath];
    }
    [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
}

- (void)sectionHeaderView:(AppNexusSDKAppSectionHeaderView *)sectionHeaderView sectionClosed:(NSInteger)section {
    NSInteger numRows = 0;
    if (section == AdSettingsSectionHeaderGeneralIndex) {
        if (!AdSettingsSectionGeneralIsOpen) return;
        AdSettingsSectionGeneralIsOpen = NO;
        numRows = AdSettingsSectionGeneralNumRows;
    } else if (section == AdSettingsSectionHeaderAdvancedIndex) {
        if (!AdSettingsSectionAdvancedIsOpen) return;
        AdSettingsSectionAdvancedIsOpen = NO;
        numRows = AdSettingsSectionAdvancedNumRows;
    }
    NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
    for (NSInteger i=0; i < numRows; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:section];
        [indexPathsToDelete addObject:indexPath];
    }
    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == AdSettingsSectionHeaderGeneralIndex) {
        if (AdSettingsSectionGeneralIsOpen) return AdSettingsSectionGeneralNumRows;
    } else if (section == AdSettingsSectionHeaderAdvancedIndex) {
        if (AdSettingsSectionAdvancedIsOpen) return AdSettingsSectionAdvancedNumRows;
    }
    return 0;
}

#pragma mark Custom Keywords Modal View Controller

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[AppNexusSDKAppModalViewController class]]) {
        AppNexusSDKAppModalViewController *help = (AppNexusSDKAppModalViewController *)[segue destinationViewController];
        help.orientation = [UIApplication sharedApplication].statusBarOrientation;
        [UIApplication sharedApplication].keyWindow.rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
        help.delegate = self;
    }
}

- (void)sdkAppModalViewControllerShouldDismiss:(AppNexusSDKAppModalViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:^{
        [UIApplication sharedApplication].keyWindow.rootViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        self.persistentSettings = nil;
    }];
}

@end

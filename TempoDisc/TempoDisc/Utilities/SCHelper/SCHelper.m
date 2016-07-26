#import "SCHelper.h"

#define kMaxLogoSize CGSizeMake(50.,50.)

#define kFontNameSemiBold @""

@implementation SCHelper

+ (BOOL)isNilOrEmpty:(NSString*)string {
	
	if ([string isKindOfClass:[NSNumber class]]) {
		return string ? NO : YES;
	}
	
	if (string == nil || [string isEqual:[NSNull null]] || [[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] || [string isEqualToString:@"<null>"]) {
		return YES;
	}
	else {
		return NO;
	}
}

+ (BOOL)stringIsValidEmail:(NSString *)checkString
{
	BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
	NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
	NSString *laxString = @".+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*";
	NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
	NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
	return [emailTest evaluateWithObject:checkString];
}

+ (BOOL)stringIsValidName:(NSString *)checkString {
	
	NSString *nameRegex = @"^\\p{L}+[\\p{L}\\p{Z}\\p{P}]{0,}";
	NSPredicate *nameTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", nameRegex];
	return [nameTest evaluateWithObject:checkString];
	
}

+ (BOOL)stringIsValidAddress:(NSString *)checkString {
	
	NSString *addressRegex = @"/\\s+(\\d{2,5}\\s+)(?![a|p]m\b)(([a-zA-Z|\\s+]{1,5}){1,2})?([\\s|\\,|.]+)?(([a-zA-Z|\\s+]{1,30}){1,4})(court|ct|street|st|drive|dr|lane|ln|road|rd|blvd)([\\s|\\,|.|\\;]+)?(([a-zA-Z|\\s+]{1,30}){1,2})([\\s|\\,|.]+)?\b(AK|AL|AR|AZ|CA|CO|CT|DC|DE|FL|GA|GU|HI|IA|ID|IL|IN|KS|KY|LA|MA|MD|ME|MI|MN|MO|MS|MT|NC|ND|NE|NH|NJ|NM|NV|NY|OH|OK|OR|PA|RI|SC|SD|TN|TX|UT|VA|VI|VT|WA|WI|WV|WY)([\\s|\\,|.]+)?(\\s+\\d{5})?([\\s|\\,|.]+)/i";
	NSPredicate *addressTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", addressRegex];
	return [addressTest evaluateWithObject:checkString];
}

+ (UIImage *)imageWithColor:(UIColor *)color
{
	CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
	UIGraphicsBeginImageContext(rect.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSetFillColorWithColor(context, [color CGColor]);
	CGContextFillRect(context, rect);
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size
{
	CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
	UIGraphicsBeginImageContext(rect.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSetFillColorWithColor(context, [color CGColor]);
	CGContextFillRect(context, rect);
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}

+ (NSInteger)numberOfElementsInString:(NSString *)string {
	if ([SCHelper isNilOrEmpty:string]) {
		return 0;
	}
	if ([string containsString:@"."] || [string containsString:@","]) {
		if ([string containsString:@"."]) {
			return [[string componentsSeparatedByString:@"."] count];
		}
		else {
			return [[string componentsSeparatedByString:@","] count];
		}
	}
	else {
		return 1;
	}
}

+ (UITableViewCell *)cellForView:(UIView *)view {
	UITableViewCell *cell = (UITableViewCell*)view.superview;
	while (![cell isKindOfClass:[UITableViewCell class]] && cell.superview) {
		cell = (UITableViewCell*)cell.superview;
	}
	if ([cell isKindOfClass:[UITableViewCell class]]) {
		return cell;
	}
	else {
		return nil;
	}
}

+ (NSIndexPath *)indexPathForView:(UIView *)view inTableView:(UITableView *)tableView {
	UITableViewCell *cell = [SCHelper cellForView:view];
	if (cell) {
		return [tableView indexPathForCell:cell];
	}
	else {
		return nil;
	}
}



+ (UIImage *)convertImageToGrayScale:(UIImage *)image {
	
	
	// Create image rectangle with current image width/height
	CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
	
	// Grayscale color space
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	
	// Create bitmap content with current image size and grayscale colorspace
	CGContextRef context = CGBitmapContextCreate(nil, image.size.width, image.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
	
	// Draw image into current context, with specified rectangle
	// using previously defined context (with grayscale colorspace)
	CGContextDrawImage(context, imageRect, [image CGImage]);
	
	// Create bitmap image info from pixel data in current context
	CGImageRef imageRef = CGBitmapContextCreateImage(context);
	
	// Release colorspace, context and bitmap information
	CGColorSpaceRelease(colorSpace);
	CGContextRelease(context);
	
	context = CGBitmapContextCreate(nil,image.size.width, image.size.height, 8, 0, nil, kCGImageAlphaOnly );
	CGContextDrawImage(context, imageRect, [image CGImage]);
	CGImageRef mask = CGBitmapContextCreateImage(context);
	
	// Create a new UIImage object
	UIImage *newImage = [UIImage imageWithCGImage:CGImageCreateWithMask(imageRef, mask)];
	CGImageRelease(imageRef);
	CGImageRelease(mask);
	
	// Return the new grayscale image
	return newImage;
}

+ (UIImage*)scaledImageFromImage:(UIImage*)image {
	CGSize originalImageSize = image.size;
	CGSize allowedImageSize = kMaxLogoSize;
	CGSize sizeToScaleTo = image.size;
	if (originalImageSize.height < allowedImageSize.height &&
		originalImageSize.width < allowedImageSize.width) {
		//no scaling needed
		return image;
	}
	if (originalImageSize.height > allowedImageSize.height) {
		CGFloat scaleFactorHeight = allowedImageSize.height / sizeToScaleTo.height;
		sizeToScaleTo.height = allowedImageSize.height;
		sizeToScaleTo.width *= scaleFactorHeight;
		
		if (sizeToScaleTo.width > allowedImageSize.width) {
			CGFloat scaleFactorWidth = allowedImageSize.width / sizeToScaleTo.width;
			sizeToScaleTo.width = allowedImageSize.width;
			sizeToScaleTo.height *= scaleFactorWidth;
		}
	}
	else if (originalImageSize.width > allowedImageSize.width) {
		CGFloat scaleFactorWidth = sizeToScaleTo.width / originalImageSize.width;
		sizeToScaleTo.width = allowedImageSize.width;
		sizeToScaleTo.height *= scaleFactorWidth;
		
		if (sizeToScaleTo.height > allowedImageSize.height) {
			CGFloat scaleFactorHeight = allowedImageSize.height / sizeToScaleTo.height;
			sizeToScaleTo.height = allowedImageSize.height;
			sizeToScaleTo.width *= scaleFactorHeight;
		}
	}
	
	UIGraphicsBeginImageContextWithOptions(sizeToScaleTo, false, 1.0);
	[image drawInRect:CGRectMake(0.0, 0.0, sizeToScaleTo.width, sizeToScaleTo.height)];
	UIImage* scaledImage;
	@autoreleasepool {
		scaledImage = UIGraphicsGetImageFromCurrentImageContext();
	}
	UIGraphicsEndImageContext();
	
	return scaledImage;
}

+ (NSString *)formattedTimeLeftForDate:(NSDate *)postDate fromDate:(NSDate *)fromDate withFormatter:(NSNumberFormatter *)formatter {
	NSDate *currentTimestamp = fromDate;
	NSTimeInterval difference = [postDate timeIntervalSinceDate:currentTimestamp];
	if (difference > 0) {
		if (fabs(difference) > 60*60*24) {
			float days = difference/60./60./24.;
			NSInteger numberOfDays = days-(NSInteger)days < .5 ? difference/60./60./24. : difference/60./60./24.+1;
			if (difference > 0) {
				return [NSString stringWithFormat:NSLocalizedString(@"%ld %@ left", nil), numberOfDays, numberOfDays == 1 ? NSLocalizedString(@"day", nil) : NSLocalizedString(@"days", nil)];
			}
			else {
				return [NSString stringWithFormat:NSLocalizedString(@"Draw in progress", nil)];
			}
			
		}
		else {
			NSInteger hours = fabs(difference)/60/60;
			NSInteger minutes = (fabs(difference)-hours*60*60)/60;
			NSInteger seconds = (NSInteger)(fabs(difference)-hours*60*60-minutes*60)%60;
			return [NSString stringWithFormat:@"%@:%@:%@",[formatter stringFromNumber:@(hours)], [formatter stringFromNumber:@(minutes)], [formatter stringFromNumber:@(seconds)]];
		}
	}
	else {
		return [NSString stringWithFormat:NSLocalizedString(@"Draw in progress", nil)];
	}
}

+ (NSString *)formattedTimePassedForDate:(NSDate *)postDate fromDate:(NSDate *)date withFormatter:(NSNumberFormatter *)formatter {
	NSDate *currentTimestamp = date;
	NSTimeInterval difference = [postDate timeIntervalSinceDate:currentTimestamp];
	if (fabs(difference) > 60*60*24) {
		NSInteger numberOfDays = difference/60./60./24.;
		if (difference > 0) {
			return [NSString stringWithFormat:NSLocalizedString(@"%ld %@ left", nil), numberOfDays, numberOfDays == 1 ? NSLocalizedString(@"day", nil) : NSLocalizedString(@"days", nil)];
		}
		else {
			return [NSString stringWithFormat:NSLocalizedString(@"%ld %@ ago", nil), -numberOfDays, numberOfDays == -1 ? NSLocalizedString(@"day", nil) : NSLocalizedString(@"days", nil)];
		}
		
	}
	else if (fabs(difference) > 60*60*2) {
		NSInteger hours = fabs(difference)/60/60;
		return [NSString stringWithFormat:NSLocalizedString(@"%ld hours ago", nil), hours];
	}
	else {
//		NSInteger hours = fabs(difference)/60/60;
//		NSInteger minutes = (fabs(difference)-hours*60*60)/60;
//		NSInteger seconds = (NSInteger)(fabs(difference)-hours*60*60-minutes*60)%60;
		return [NSString stringWithFormat:@"less than an hour ago"/*,[formatter stringFromNumber:@(hours)], [formatter stringFromNumber:@(minutes)], [formatter stringFromNumber:@(seconds)]*/];
	}
}

+(NSString*)formattedTimeLeftForDate:(NSDate*)postDate withFormatter:(NSNumberFormatter*)formatter {
	return [SCHelper formattedTimeLeftForDate:postDate fromDate:[NSDate date] withFormatter:formatter];
}

+ (NSString *)formattedTimePassedForDate:(NSDate *)postDate withFormatter:(NSNumberFormatter *)formatter {
	return [SCHelper formattedTimePassedForDate:postDate fromDate:[NSDate date] withFormatter:formatter];
}

+ (void)adjustFontsForViews:(NSArray *)views {
	if ([UIScreen mainScreen].bounds.size.width <= 320) {
		for (UIView *view in views) {
			[SCHelper adjustFontForView:view];
			[SCHelper adjustFontsForViews:view.subviews];
		}
	}
}

+ (void)adjustFontForView:(UIView*)view {
	float multiplier = 0.883489784;
	if ([view isKindOfClass:[UILabel class]]) {
		UILabel *label = (UILabel*)view;
		if (label.tag == kTagSemiboldFont && [UIDevice currentDevice].systemVersion.floatValue < 8.0) {
			label.font = [UIFont fontWithName:kFontNameSemiBold size:label.font.pointSize];
		}
		[(UILabel*)view setFont:[UIFont fontWithName:[(UILabel*)view font].fontName size:[(UILabel*)view font].pointSize*multiplier]];
	}
	else if ([view isKindOfClass:[UIButton class]]) {
		UIButton *button = (UIButton*)view;
		if (button.tag == kTagSemiboldFont && [UIDevice currentDevice].systemVersion.floatValue < 8.0) {
			[button.titleLabel setFont:[UIFont fontWithName:kFontNameSemiBold size:button.titleLabel.font.pointSize]];
		}
		[button.titleLabel setFont:[UIFont fontWithName:button.titleLabel.font.fontName size:button.titleLabel.font.pointSize*multiplier]];
	}
	else if ([view isKindOfClass:[UITextField class]]) {
		UITextField *field = (UITextField*)view;
		if (field.tag == kTagSemiboldFont && [UIDevice currentDevice].systemVersion.floatValue < 8.0) {
			field.font = [UIFont fontWithName:kFontNameSemiBold size:field.font.pointSize];
		}
		[field setFont:[UIFont fontWithName:field.font.fontName size:field.font.pointSize*multiplier]];
	}
}

+ (void)adjustConstantsForConstraints:(NSArray *)constraints {
	if ([UIScreen mainScreen].bounds.size.width <= 320) {
		for (NSLayoutConstraint *constraint in constraints) {
			constraint.constant *= 0.883489784;
		}
	}
}

+ (float)sizeModifier {
	if ([UIScreen mainScreen].bounds.size.width > 320) {
		return 1.;
	}
	return 0.883489784;
}

+ (BOOL)isValidEmail:(NSString *)checkString
{
	BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
	NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
	NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
	NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
	NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
	return [emailTest evaluateWithObject:checkString];
}

+ (NSString*)formattedStringFromNumber:(NSNumber*)number withFormatter:(NSNumberFormatter *)formatter{
	if (number.doubleValue >= 1000000) {
		return [NSString stringWithFormat:@"%@m", [formatter stringFromNumber:@(number.doubleValue/1000000)]];
	}
	else if (number.doubleValue >= 1000) {
		return [NSString stringWithFormat:@"%@k", [formatter stringFromNumber:@(number.doubleValue/1000)]];
	}
	else {
		return [formatter stringFromNumber:number];
	}
}

@end

#import <UIKit/UIKit.h>

// Hook vào đối tượng quản lý ứng dụng của SpringBoard để ép báo ứng dụng của bạn hỗ trợ CarPlay
%hook SBApplication

- (BOOL)isCarPlaySupported {
    // Kiểm tra nếu là app của bạn thì trả về YES tuyệt đối
    if ([[self bundleIdentifier] isEqualToString:@"com.thanhtvsys.carplaykova3d"]) {
        return YES;
    }
    return %orig;
}

- (BOOL)isCarPlayAllowed {
    if ([[self bundleIdentifier] isEqualToString:@"com.thanhtvsys.carplaykova3d"]) {
        return YES;
    }
    return %orig;
}

%end

// Hook vào tầng cấu hình phiên CarPlay (CARSessionConfiguration hoặc các lớp tương đương tùy phiên bản iOS)
%hook CARSessionConfiguration

- (BOOL)isAllowedToRunAppWithBundleIdentifier:(NSString *)bundleID {
    if ([bundleID isEqualToString:@"com.thanhtvsys.carplaykova3d"]) {
        return YES;
    }
    return %orig;
}

%end

#!/bin/bash
set -e

echo "🚀 Bắt đầu quá trình build CarPlayKova3D và CarPlayHook..."

# --- BƯỚC 1: TỰ ĐỘNG TĂNG PHIÊN BẢN (VERSION) ---
CONTROL_FILE="pkg_staging/DEBIAN/control"
mkdir -p pkg_staging/DEBIAN

if [ -f "$CONTROL_FILE" ]; then
    CURRENT_VERSION=$(grep "Version:" "$CONTROL_FILE" | awk '{print $2}')
else
    CURRENT_VERSION="1.1.3"
fi

MAJOR_MINOR=$(echo "$CURRENT_VERSION" | awk -F. '{print $1"."$2}')
PATCH=$(echo "$CURRENT_VERSION" | awk -F. '{print $3}')
NEXT_PATCH=$((PATCH + 1))
AUTO_VERSION="${MAJOR_MINOR}.${NEXT_PATCH}"
echo "🔄 Phiên bản tự động tăng lên: $AUTO_VERSION"

# --- BƯỚC 2: BUILD ỨNG DỤNG XCODE ---
echo "📦 Đang build ứng dụng CarPlayKova3D..."
xcodebuild -project CarPlayKova3D.xcodeproj \
           -scheme CarPlayKova3D \
           -configuration Release \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO \
           -derivedDataPath build_output

# --- BƯỚC 3: BIÊN DỊCH TWEAK CARPLAYHOOK ---
echo "💉 Đang biên dịch Tweak CarPlayHook..."
cd CarPlayHook
make clean
make package
cd ..

# --- BƯỚC 4: CHUẨN BỊ CẤU TRÚC STAGING SẠCH CHO GÓI .DEB ---
PKG_DIR="pkg_staging"
rm -rf $PKG_DIR
mkdir -p $PKG_DIR/Applications
mkdir -p $PKG_DIR/Library/MobileSubstrate/DynamicLibraries
mkdir -p $PKG_DIR/DEBIAN

# Chỉ sao chép đúng file .app từ kết quả build Xcode
cp -R build_output/Build/Products/Release-iphoneos/CarPlayKova3D.app $PKG_DIR/Applications/

# Dọn dẹp sạch các tệp index rác nếu vô tình lọt vào thư mục .app
rm -f $PKG_DIR/Applications/CarPlayKova3D.app/Packages*
rm -f $PKG_DIR/Applications/CarPlayKova3D.app/Release*
rm -rf $PKG_DIR/Applications/CarPlayKova3D.app/_CodeSignature

# --- BƯỚC 5: TỰ ĐỘNG TÌM VÀ COPY FILE DYLIB CỦA TWEAK ---
DYLIB_PATH=$(find CarPlayHook/.theos/obj -name "CarPlayHook.dylib" | head -n 1)
if [ -z "$DYLIB_PATH" ]; then
    echo "❌ Lỗi: Không tìm thấy file CarPlayHook.dylib sau khi build!"
    exit 1
fi
echo "✅ Tìm thấy dylib tại: $DYLIB_PATH"

cp "$DYLIB_PATH" $PKG_DIR/Library/MobileSubstrate/DynamicLibraries/
cp CarPlayHook/CarPlayHook.plist $PKG_DIR/Library/MobileSubstrate/DynamicLibraries/

# --- BƯỚC 6: KÝ SỐ LDID VÀ GÁN ENTITLEMENTS CHUẨN XÁC ---
echo "🔐 Đang ký số ldid kèm tệp Entitlements cho ứng dụng..."
ENTITLEMENTS_PATH="CarPlayKova3D/CarPlayKova3D.entitlements"
APP_BINARY="$PKG_DIR/Applications/CarPlayKova3D.app/CarPlayKova3D"

if [ -f "$ENTITLEMENTS_PATH" ]; then
    ldid -S"$ENTITLEMENTS_PATH" "$APP_BINARY"
    echo "Đã gán Entitlements thành công cho ứng dụng CarPlay!"
else
    echo "❌ Lỗi: Không tìm thấy file entitlements tại $ENTITLEMENTS_PATH"
    exit 1
fi

ldid -S $PKG_DIR/Library/MobileSubstrate/DynamicLibraries/CarPlayHook.dylib

cat <<EOF > $CONTROL_FILE
Package: com.thanhtvsys.carplaykova3d
Name: CarPlayKova3D
Version: $AUTO_VERSION
Architecture: iphoneos-arm
Description: Ứng dụng CarPlay tích hợp Web Dashboard và Tweak Hook.
Maintainer: Thanhtvsys
Author: Thanhtvsys
Section: Applications
Depends: mobilesubstrate, firmware (>= 14.0)
EOF

# --- BƯỚC 7: ĐÓNG GÓI .DEB VÀ TẠO KHO LƯU TRỮ RA THƯ MỤC NGOÀI ---
mkdir -p debs
DEB_NAME="CarPlayKova3D_${AUTO_VERSION}_iphoneos-arm.deb"
dpkg-deb -b $PKG_DIR "$DEB_NAME"
mv "$DEB_NAME" debs/

echo "📦 Đang tạo Index Packages cho kho lưu trữ Sileo (ở thư mục gốc)..."
dpkg-scanpackages -m debs /dev/null > Packages
bzip2 -k -f Packages
gzip -k -f Packages

# --- BƯỚC 8: TỰ ĐỘNG ĐẨY LÊN GITHUB ---
echo "📤 Đang đồng bộ và đẩy toàn bộ mã nguồn lên GitHub..."
git add -A
git commit -m "Auto-build: Clean app bundle, update CarPlayKova3D with Entitlements and deb v$AUTO_VERSION" || echo "Không có thay đổi mới."
git push origin main

echo "🎉 Hoàn tất toàn bộ quy trình build sạch thành công xuất sắc!"

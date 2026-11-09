#!/bin/bash
set -e

echo "🚀 Bắt đầu quá trình build CarPlayKova3D và CarPlayHook..."

# --- BƯỚC 1: BUILD ỨNG DỤNG XCODE ---
echo "📦 Đang build ứng dụng CarPlayKova3D..."
xcodebuild -project CarPlayKova3D.xcodeproj \
           -scheme CarPlayKova3D \
           -configuration Release \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO \
           -derivedDataPath build_output

# --- BƯỚC 2: BIÊN DỊCH TWEAK CARPLAYHOOK ---
echo "💉 Đang biên dịch Tweak CarPlayHook..."
cd CarPlayHook
make clean
make package
cd ..

# --- BƯỚC 3: CHUẨN BỊ CẤU TRÚC STAGING CHO GÓI .DEB ---
PKG_DIR="pkg_staging"
rm -rf $PKG_DIR
mkdir -p $PKG_DIR/Applications
mkdir -p $PKG_DIR/Library/MobileSubstrate/DynamicLibraries
mkdir -p $PKG_DIR/DEBIAN

# Copy App sau khi build vào thư mục Applications
cp -R build_output/Build/Products/Release-iphoneos/CarPlayKova3D.app $PKG_DIR/Applications/

# --- BƯỚC 4: TỰ ĐỘNG TÌM VÀ COPY FILE DYLIB CỦA TWEAK ---
DYLIB_PATH=$(find CarPlayHook/.theos/obj -name "CarPlayHook.dylib" | head -n 1)
if [ -z "$DYLIB_PATH" ]; then
    echo "❌ Lỗi: Không tìm thấy file CarPlayHook.dylib sau khi build!"
    exit 1
fi
echo "✅ Tìm thấy dylib tại: $DYLIB_PATH"

cp "$DYLIB_PATH" $PKG_DIR/Library/MobileSubstrate/DynamicLibraries/
cp CarPlayHook/CarPlayHook.plist $PKG_DIR/Library/MobileSubstrate/DynamicLibraries/

# --- BƯỚC 5: KÝ SỐ LDID VÀ TẠO CONTROL ---
echo "🔐 Đang ký số ldid..."
ldid -S $PKG_DIR/Applications/CarPlayKova3D.app/CarPlayKova3D
ldid -S $PKG_DIR/Library/MobileSubstrate/DynamicLibraries/CarPlayHook.dylib

cat <<EOF > $PKG_DIR/DEBIAN/control
Package: com.thanhtvsys.carplaykova3d
Name: CarPlayKova3D
Version: 1.0.6
Architecture: iphoneos-arm
Description: Ứng dụng CarPlay tích hợp Web Dashboard và Tweak Hook.
Maintainer: Thanhtvsys
Author: Thanhtvsys
Section: Applications
Depends: mobilesubstrate, firmware (>= 14.0)
EOF

# --- BƯỚC 6: ĐÓNG GÓI .DEB VÀ TẠO INDEX CHO SILEO ---
mkdir -p debs
dpkg-deb -b $PKG_DIR CarPlayKova3D_AllInOne.deb
mv CarPlayKova3D_AllInOne.deb debs/

echo "📦 Đang tạo Index Packages cho kho lưu trữ Sileo..."
dpkg-scanpackages -m debs /dev/null > Packages
bzip2 -k -f Packages
gzip -k -f Packages

# --- BƯỚC 7: TỰ ĐỘNG ĐẨY LÊN GITHUB ---
echo "📤 Đang đồng bộ và đẩy toàn bộ mã nguồn lên GitHub..."
git add -A
git commit -m "Auto-build: Update CarPlayKova3D app, CarPlayHook source code and all-in-one deb packages" || echo "Không có thay đổi mới."
git push origin main

echo "🎉 Hoàn tất toàn bộ quy trình thành công xuất sắc!"

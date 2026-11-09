#!/bin/bash

# Thư mục gốc Repo Git & Sileo Repo
REPO_DIR="/Users/thanhtran/Desktop/Carplay/CarPlayKova3D"
cd "$REPO_DIR" || { echo "❌ Không tìm thấy thư mục dự án tại $REPO_DIR"; exit 1; }

VERSION_FILE="$REPO_DIR/version.txt"
PROJECT_NAME="CarPlayKova3D"
BUNDLE_ID="com.thanhtvsys.carplaykova3d"
GITHUB_REPO_URL="https://github.com/Thanhtvsys/carplay.git"
PAGES_URL="https://thanhtvsys.github.io/carplay/"

echo "🧹 Đang dọn dẹp các tệp rác ẩn và metadata của macOS..."
find . -type f \( -name "._*" -o -name ".DS_Store" \) -delete
xattr -cr . 2>/dev/null

echo "🚀 Bắt đầu làm sạch và biên dịch source code bằng xcodebuild (Bỏ qua Signing Check)..."

# 1. Build trực tiếp và vô hiệu hóa yêu cầu Provisioning Profile bằng cờ code-sign rỗng
xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
           -scheme "$PROJECT_NAME" \
           -sdk iphoneos \
           -configuration Release \
           -derivedDataPath "./DerivedData" \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO \
           clean build || { echo "❌ Lỗi biên dịch xcodebuild! Vui lòng kiểm tra lại mã nguồn."; exit 1; }

echo "✅ Biên dịch ứng dụng thành công!"

# 2. Quản lý phiên bản tự động tăng
if [ ! -f "$VERSION_FILE" ]; then
    CURRENT_VERSION="1.1.0"
    echo "$CURRENT_VERSION" > "$VERSION_FILE"
else
    CURRENT_VERSION=$(cat "$VERSION_FILE")
    IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"
    patch=$((patch + 1))
    NEW_VERSION="$major.$minor.$patch"
    echo "$NEW_VERSION" > "$VERSION_FILE"
    CURRENT_VERSION="$NEW_VERSION"
fi
echo "✨ Phiên bản hiện tại: $CURRENT_VERSION"

# 3. Đảm bảo thư mục debs nằm ở thư mục gốc
mkdir -p debs
touch debs/.gitkeep

# 4. Tự động tìm kiếm file .app bên trong DerivedData và đóng gói .deb
XCODE_APP=$(find ./DerivedData -name "${PROJECT_NAME}.app" -type d 2>/dev/null | head -n 1)

if [ -n "$XCODE_APP" ]; then
    echo "📦 Đã tìm thấy App tại: $XCODE_APP"
    echo "📦 Đang đóng gói app thành .deb..."
    
    PKG_DIR="debs/pkg_temp"
    rm -rf "$PKG_DIR"
    mkdir -p "$PKG_DIR/Applications"
    mkdir -p "$PKG_DIR/DEBIAN"
    
    cp -R "$XCODE_APP" "$PKG_DIR/Applications/${PROJECT_NAME}.app"
    
    # Xóa tệp rác phát sinh trong thư mục app trước khi ký ldid
    find "$PKG_DIR" -type f \( -name "._*" -o -name ".DS_Store" \) -delete
    
    # Ký số ldid chống văng app trên iOS 16 Jailbreak (Công cụ chính để chạy tweak/app jailbreak)
    BINARY_PATH="$PKG_DIR/Applications/${PROJECT_NAME}.app/${PROJECT_NAME}"
    if [ -f "$BINARY_PATH" ] && command -v ldid &> /dev/null; then
        ldid -S "$BINARY_PATH"
        echo "🔏 Đã ký số ldid thành công."
    else
        echo "⚠️ Cảnh báo: Chưa cài đặt ldid hoặc không tìm thấy binary."
    fi
    
    # Tạo tệp control
    cat <<EOF > "$PKG_DIR/DEBIAN/control"
Package: $BUNDLE_ID
Name: $PROJECT_NAME
Version: $CURRENT_VERSION
Architecture: iphoneos-arm
Maintainer: Thanhtvsys <thanhtvsys@gmail.com>
Author: Thanhtvsys
Section: Applications
Depends: mobilesubstrate, firmware (>= 14.0)
Description: Tích hợp Apple CarPlay cho CarPlayKova3D.
EOF

    # Tạo tệp postinst (auto-uicache)
    cat <<'EOF' > "$PKG_DIR/DEBIAN/postinst"
#!/bin/sh
if [ -x /usr/bin/uicache ]; then
    /usr/bin/uicache -p /Applications/CarPlayKova3D.app 2>/dev/null || /usr/bin/uicache --all 2>/dev/null
fi
EOF
    chmod 755 "$PKG_DIR/DEBIAN/postinst"

    # Tạo tệp prerm
    cat <<'EOF' > "$PKG_DIR/DEBIAN/prerm"
#!/bin/sh
if [ -x /usr/bin/uicache ]; then
    /usr/bin/uicache -u /Applications/CarPlayKova3D.app 2>/dev/null || /usr/bin/uicache --all 2>/dev/null
fi
EOF
    chmod 755 "$PKG_DIR/DEBIAN/prerm"
    
    DEB_NAME="${PROJECT_NAME}_${CURRENT_VERSION}_iphoneos-arm.deb"
    dpkg-deb -b "$PKG_DIR" "debs/$DEB_NAME"
    rm -rf "$PKG_DIR"
    echo "✅ Đã tạo gói cài đặt chuẩn: debs/$DEB_NAME"
else
    echo "❌ Không tìm thấy thư mục .app sau khi build!"
    exit 1
fi

# 5. Tạo file version.json và index.html tại đúng thư mục gốc Repo
cat <<EOF > "version.json"
{
  "project": "$PROJECT_NAME",
  "version": "$CURRENT_VERSION",
  "build_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "target_url": "$PAGES_URL"
}
EOF

cat <<EOF > "index.html"
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>CarPlayKova3D - Release Portal</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #000; color: #fff; text-align: center; padding-top: 100px; }
        h1 { color: #DB5304; }
        a { color: #DB5304; text-decoration: none; font-weight: bold; }
    </style>
</head>
<body>
    <h1>🚗 CarPlay Kova3D Release Hub (v$CURRENT_VERSION)</h1>
    <p>Hệ thống phân phối và quản lý phiên bản tự động cho CarPlayKova3D.</p>
    <p>Xem tệp cấu hình phiên bản mới nhất: <a href="version.json" target="_blank">version.json</a></p>
</body>
</html>
EOF

# 6. Tạo cấu trúc APT Repository cho Sileo tại thư mục gốc
touch Packages
dpkg-scanpackages debs /dev/null > Packages 2>/dev/null
gzip -9c Packages > Packages.gz

cat <<EOF > Release
Origin: CarPlayKova3D Repo
Label: CarPlayKova3D
Suite: stable
Version: $CURRENT_VERSION
Codename: ios
Architectures: iphoneos-arm iphoneos-arm64
Components: main
Description: Kho lưu trữ tweak CarPlayKova3D chính thức của Thanhtvsys
EOF

# 7. Đồng bộ tự động lên GitHub tại thư mục gốc Repo
echo "📦 Đang đẩy toàn bộ bản cập nhật lên GitHub (Thanhtvsys/carplay)..."

git init 2>/dev/null
git remote remove origin 2>/dev/null
git remote add origin "$GITHUB_REPO_URL"

git add -A
git commit -m "Auto-build & release v$CURRENT_VERSION via xcodebuild script"
git branch -M main

git pull origin main --allow-unrelated-histories --no-edit 2>/dev/null
git push -u origin main --force

echo "🎉 Hoàn tất! Đã biên dịch, đóng gói deb và đẩy lên GitHub thành công."
echo "🌐 GitHub Pages: $PAGES_URL"

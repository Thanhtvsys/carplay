#!/bin/bash

# Cấu hình dự án và đường dẫn GitHub repository của bạn
VERSION_FILE="version.txt"
PROJECT_NAME="CarPlayKova3D"
GITHUB_REPO_URL="https://github.com/Thanhtvsys/carplay.git"
PAGES_URL="https://thanhtvsys.github.io/carplay/"

echo "🚀 Bắt đầu quy trình tự động Build và Versioning cho $PROJECT_NAME..."

# 1. Kiểm tra và khởi tạo Git repository nếu chưa có
if [ ! -d ".git" ]; then
    echo "📦 Đang khởi tạo Git repository..."
    git init
    git remote add origin "$GITHUB_REPO_URL"
else
    # Đảm bảo remote URL luôn trỏ chính xác đến repo của bạn
    git remote set-url origin "$GITHUB_REPO_URL"
fi

# 2. Quản lý số phiên bản tự động bắt đầu từ 1.1.0
if [ ! -f "$VERSION_FILE" ]; then
    CURRENT_VERSION="1.1.0"
    echo "$CURRENT_VERSION" > "$VERSION_FILE"
    echo "📌 Khởi tạo phiên bản đầu tiên: $CURRENT_VERSION"
else
    CURRENT_VERSION=$(cat "$VERSION_FILE")
    echo "📌 Phiên bản hiện tại: $CURRENT_VERSION"
    
    # Tự động tăng patch version (Ví dụ: 1.1.0 -> 1.1.1)
    IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"
    patch=$((patch + 1))
    NEW_VERSION="$major.$minor.$patch"
    
    echo "$NEW_VERSION" > "$VERSION_FILE"
    CURRENT_VERSION="$NEW_VERSION"
    echo "✨ Đã nâng phiên bản mới lên: $CURRENT_VERSION"
fi

# 3. Sinh file metadata version.json để app có thể check update
JSON_OUTPUT="version.json"
cat <<EOF > "$JSON_OUTPUT"
{
  "project": "$PROJECT_NAME",
  "version": "$CURRENT_VERSION",
  "build_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "target_url": "$PAGES_URL"
}
EOF
echo "📄 Đã tự sinh tệp cấu hình: $JSON_OUTPUT"

# 4. Tiến hành Git Automation (Commit & Push lên GitHub)
echo "📦 Đang đồng bộ mã nguồn lên GitHub (Thanhtvsys/carplay)..."

git add .
git commit -m "Auto-build: Release version $CURRENT_VERSION for CarPlay Kova3D"

# Đẩy lên nhánh main (nếu báo lỗi branch, script sẽ tự chuyển sang master)
git branch -M main
git push -u origin main

echo "✅ Hoàn tất! Phiên bản v$CURRENT_VERSION đã được đẩy lên GitHub thành công."
echo "🌐 GitHub Repository: https://github.com/Thanhtvsys/carplay"
echo "🌐 GitHub Pages: $PAGES_URL"

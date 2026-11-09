#!/bin/bash

# Cố định thư mục làm việc chính xác trên máy của bạn
PROJECT_DIR="/Users/thanhtran/Desktop/Carplay/CarPlayKova3D"
cd "$PROJECT_DIR" || { echo "❌ Không tìm thấy thư mục dự án tại $PROJECT_DIR"; exit 1; }

# Cấu hình dự án và đường dẫn GitHub repository
VERSION_FILE="version.txt"
PROJECT_NAME="CarPlayKova3D"
GITHUB_REPO_URL="https://github.com/Thanhtvsys/carplay.git"
PAGES_URL="https://thanhtvsys.github.io/carplay/"

echo "🚀 Đang chạy tại thư mục: $(pwd)"
echo "🚀 Bắt đầu quy trình tự động Build, cập nhật phiên bản mới nhất và dọn dẹp file cũ..."

# 1. Dọn dẹp triệt để các tệp tạm, cache hoặc bản build cũ nếu có
rm -rf build/ DerivedData/ *.zip *.tar.gz 2>/dev/null
echo "🧹 Đã xóa bỏ các tệp build tạm và rác hệ thống cũ."

# 2. Quản lý phiên bản: Ghi đè phiên bản cũ, chỉ giữ lại version mới nhất
if [ ! -f "$VERSION_FILE" ]; then
    CURRENT_VERSION="1.1.0"
    echo "$CURRENT_VERSION" > "$VERSION_FILE"
    echo "📌 Khởi tạo phiên bản mới nhất: $CURRENT_VERSION"
else
    CURRENT_VERSION=$(cat "$VERSION_FILE")
    echo "📌 Phiên bản hiện tại: $CURRENT_VERSION"
    
    # Tự động tăng patch version lên 1 đơn vị
    IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"
    patch=$((patch + 1))
    NEW_VERSION="$major.$minor.$patch"
    
    # Ghi đè hoàn toàn vào file
    echo "$NEW_VERSION" > "$VERSION_FILE"
    CURRENT_VERSION="$NEW_VERSION"
    echo "✨ Đã cập nhật phiên bản mới nhất: $CURRENT_VERSION (Đã xóa bỏ thông tin phiên bản cũ)"
fi

# 3. Tạo file metadata version.json mới nhất (ghi đè file cũ)
JSON_OUTPUT="version.json"
cat <<EOF > "$JSON_OUTPUT"
{
  "project": "$PROJECT_NAME",
  "version": "$CURRENT_VERSION",
  "build_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "target_url": "$PAGES_URL"
}
EOF
echo "📄 Đã tạo tệp cấu hình JSON mới nhất: $JSON_OUTPUT"

# 4. Tiến hành Git Automation: Commit và ép đẩy bản mới nhất lên GitHub (Không lo lỗi xung đột)
echo "📦 Đang đồng bộ phiên bản mới nhất lên GitHub (Thanhtvsys/carplay)..."

git add .
git commit -m "Auto-build: Release latest version $CURRENT_VERSION for CarPlay Kova3D"
git branch -M main

# Tự động pull và force push để ưu tiên phiên bản mới nhất
git pull origin main --allow-unrelated-histories --no-edit 2>/dev/null
git push -u origin main --force

echo "✅ Hoàn tất! Chỉ có phiên bản mới nhất v$CURRENT_VERSION được lưu trữ và đẩy lên GitHub thành công."
echo "🌐 GitHub Repository: https://github.com/Thanhtvsys/carplay"
echo "🌐 GitHub Pages: $PAGES_URL"

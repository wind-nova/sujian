#!/usr/bin/env bash
# 素笺 SuJian · 云打包脚本
# 本仓库只提交"真正的资产": lib/ + assets/ + pubspec.yaml + tool/
# android/ 平台目录由 Flutter 在构建时现场生成，避免大段模板代码与机器相关的差异。
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> 1/5 生成 Android 平台脚手架"
flutter create --org com.sujian --project-name sujian --platforms=android .

echo "==> 2/5 恢复被模板覆盖的源文件"
git checkout -- lib pubspec.yaml 2>/dev/null || echo "    (非 git 环境，跳过)"

echo "==> 3/5 应用清单：应用名「素笺」+ 相册权限"
cp tool/android/AndroidManifest.xml android/app/src/main/AndroidManifest.xml

echo "==> 4/5 拉依赖"
flutter pub get

echo "==> 5/5 构建 APK"
flutter build apk --release --split-per-abi

echo
echo "产物："
ls -lh build/app/outputs/flutter-apk/*.apk || true

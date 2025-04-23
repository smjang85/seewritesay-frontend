#!/bin/bash

# 경로 상수
MAPPING_PATH="build/app/outputs/mapping/release/mapping.txt"
NATIVE_LIBS_DIR="build/app/intermediates/merged_native_libs/release/out/lib"
SYMBOLS_ZIP="symbols.zip"

# 1. 심볼 압축
if [ -d "$NATIVE_LIBS_DIR" ]; then
    zip -r "$SYMBOLS_ZIP" "$NATIVE_LIBS_DIR"
    echo "✅ 네이티브 심볼 압축 완료: $SYMBOLS_ZIP"
else
    echo "❗ 네이티브 심볼 경로가 존재하지 않음: $NATIVE_LIBS_DIR"
fi

# 2. 매핑 파일 확인
if [ -f "$MAPPING_PATH" ]; then
    echo "✅ mapping.txt 위치: $MAPPING_PATH"
else
    echo "❗ mapping.txt 파일 없음!"
fi

echo ""
echo "👉 위 파일들을 Google Play Console > 릴리스 관리 > 앱 버전 > ⋮ > 'ReTrace 매핑 파일', '디버그 심볼' 항목에서 업로드하세요."

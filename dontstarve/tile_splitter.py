#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
타일셋 이미지를 개별 타일로 분할하는 스크립트
tiles.png를 13x12 그리드로 나누어 개별 이미지로 저장
"""

from PIL import Image
import os

def split_tileset(image_path, horizontal_tiles=13, vertical_tiles=12, output_dir="tiles"):
    """
    타일셋 이미지를 개별 타일로 분할하여 저장
    
    @param image_path: 원본 이미지 파일 경로
    @param horizontal_tiles: 수평 타일 개수 (기본값: 13)
    @param vertical_tiles: 수직 타일 개수 (기본값: 12)
    @param output_dir: 출력 디렉터리 (기본값: "tiles")
    """
    try:
        # 이미지 로드
        image = Image.open(image_path)
        img_width, img_height = image.size
        
        print(f"원본 이미지 크기: {img_width} x {img_height}")
        
        # 각 타일의 크기 계산
        tile_width = img_width // horizontal_tiles
        tile_height = img_height // vertical_tiles
        
        print(f"타일 크기: {tile_width} x {tile_height}")
        print(f"타일 개수: {horizontal_tiles} x {vertical_tiles} = {horizontal_tiles * vertical_tiles}개")
        
        # 출력 디렉터리 생성
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
            print(f"출력 디렉터리 '{output_dir}' 생성됨")
        
        # 타일 번호 초기화
        tile_number = 1
        
        # 각 타일을 순차적으로 추출
        for row in range(vertical_tiles):
            for col in range(horizontal_tiles):
                # 타일 영역 계산
                left = col * tile_width
                top = row * tile_height
                right = left + tile_width
                bottom = top + tile_height
                
                # 타일 추출
                tile = image.crop((left, top, right, bottom))
                
                # 파일명 생성 (1, 2, 3, ...)
                filename = f"{tile_number}.png"
                filepath = os.path.join(output_dir, filename)
                
                # 타일 저장
                tile.save(filepath)
                
                print(f"타일 {tile_number} 저장됨: {filename} (위치: {col}, {row})")
                tile_number += 1
        
        print(f"\n✅ 모든 타일이 성공적으로 저장되었습니다!")
        print(f"총 {tile_number - 1}개의 타일이 '{output_dir}' 폴더에 저장됨")
        
    except FileNotFoundError:
        print(f"❌ 오류: '{image_path}' 파일을 찾을 수 없습니다.")
    except Exception as e:
        print(f"❌ 오류 발생: {str(e)}")

def main():
    """
    메인 실행 함수
    """
    # 이미지 파일 경로 설정
    image_path = "dontstarve/resorce/tile/tiles.png"
    
    # 타일셋 분할 실행
    split_tileset(
        image_path=image_path,
        horizontal_tiles=13,
        vertical_tiles=12,
        output_dir="split_tiles"
    )

if __name__ == "__main__":
    main()

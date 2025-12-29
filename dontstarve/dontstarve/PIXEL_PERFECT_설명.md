# 🎯 픽셀 퍼펙트 호버 시스템

## 개요
`obsticle.gd`에 구현된 픽셀 퍼펙트 호버 시스템은 3D 공간의 2D 스프라이트에서 **투명한 영역을 무시**하고 **실제 보이는 픽셀만** 감지하는 기술입니다.

## 🌟 핵심 기능

### 일반 충돌 vs 픽셀 퍼펙트
```
일반 충돌 감지:              픽셀 퍼펙트 감지:
┌─────────────┐            ┌─────────────┐
│ ░░░░░░░░░░░ │            │             │
│ ░░░🌳🌳░░░░ │            │   🌳🌳      │  ← 나무만 감지!
│ ░░🌳🌳🌳░░░ │            │  🌳🌳🌳     │
│ ░░░░🌳░░░░░ │            │    🌳       │
└─────────────┘            └─────────────┘
   전체 박스 감지              투명 영역 무시
```

## 🔧 작동 원리

### 1단계: 초기화 (_ready)
```gdscript
# 원본 색상 저장
original_modulate = sprite.modulate

# 텍스처 압축 해제 (픽셀 읽기 위해 필수!)
var image = thing.img.get_image()
if image.is_compressed():
    image.decompress()
uncompressed_image = image

# 충돌 박스를 텍스처 크기에 맞춤
collision_shape.shape.size = Vector3(sprite_size.x, sprite_size.y, 0.1)
```

**왜 압축 해제가 필요한가?**
- Godot는 메모리 절약을 위해 텍스처를 압축 저장
- 픽셀 단위로 읽으려면 반드시 압축을 풀어야 함
- `get_pixel(x, y)`로 개별 픽셀 데이터 접근 가능

### 2단계: 빌보드 회전 동기화 (_process)
```gdscript
# Sprite3D는 빌보드지만 CollisionShape3D는 자동으로 따라가지 않음
# 수동으로 카메라를 바라보게 회전시켜야 정확한 픽셀 감지 가능
collision_shape.look_at(camera_3d.global_position, Vector3.UP)
```

**왜 회전이 필요한가?**
```
카메라가 이동하면:
  
  👁️ 카메라          👁️ 카메라
   ↓                  ↘
  [🌳]      →        [🌳]
  스프라이트          스프라이트도 회전
                     충돌 박스도 회전 필요!
```

### 3단계: 레이캐스트 발사 (check_pixel_perfect_hover)
```gdscript
# 마우스 위치에서 3D 공간으로 광선 발사
var ray_origin = camera_3d.project_ray_origin(mouse_pos)
var ray_direction = camera_3d.project_ray_normal(mouse_pos)

# 레이캐스트 실행
var result = space_state.intersect_ray(query)

# 이 오브젝트와 충돌했는지 확인
if result and result.collider == area_3d:
    # 충돌 지점의 픽셀이 투명한지 확인
    if is_pixel_opaque_at_position(result.position):
        # 호버 효과 적용!
```

**레이캐스트 시각화:**
```
     카메라
       👁️
        |
        | 광선 (Ray)
        ↓
    [🌳 나무]
     충돌 지점
```

### 4단계: 픽셀 투명도 확인 (is_pixel_opaque_at_position)

이게 가장 복잡하고 중요한 부분입니다!

```gdscript
# 1. 월드 좌표 → 로컬 좌표
var local_pos = collision_shape.to_local(world_position)

# 2. 로컬 좌표 → UV 좌표 (0~1 범위)
var uv_x = (local_pos.x / sprite_size.x) + 0.5
var uv_y = ((local_pos.y - offset_world_y) / sprite_size.y) + 0.5
uv_y = 1.0 - uv_y  # Y축 반전

# 3. UV 좌표 → 픽셀 좌표
var pixel_x = int(uv_x * image_width)
var pixel_y = int(uv_y * image_height)

# 4. 픽셀의 알파값 확인
var pixel_color = uncompressed_image.get_pixel(pixel_x, pixel_y)
return pixel_color.a > 0.1  # 알파가 0.1보다 크면 불투명
```

**좌표 변환 과정:**
```
1. 월드 좌표 (3D 공간의 실제 위치)
   (x: 5.2, y: 3.1, z: 1.0)
          ↓ to_local()
          
2. 로컬 좌표 (오브젝트 기준 상대 위치)
   (x: 0.3, y: -0.2, z: 0.0)
          ↓ 정규화 + 0.5
          
3. UV 좌표 (0~1 범위)
   (u: 0.8, v: 0.3)
          ↓ × 이미지 크기
          
4. 픽셀 좌표 (실제 픽셀 인덱스)
   (x: 102, y: 38)
          ↓ get_pixel()
          
5. 픽셀 색상
   (r: 0.2, g: 0.8, b: 0.1, a: 1.0)
   알파 > 0.1 → 불투명! ✅
```

## 🎮 사용 방법

### 디버그 모드 활성화
```gdscript
# obsticle.gd에서
@export var debug_mode: bool = true  # true로 설정

# 실행하면 콘솔에 상세 로그 출력:
# ✅ 픽셀 퍼펙트 초기화 완료: 나무 (크기: (64, 64))
# ✅ 충돌 박스 크기 설정: (0.64, 0.64, 0.1)
# 🎯 레이캐스트 충돌: Area3D
# 🔍 픽셀 체크 시작
#   월드 좌표: (5.2, 3.1, 1.0)
#   로컬 좌표: (0.3, -0.2, 0.0)
#   UV 좌표: (0.8, 0.3)
#   픽셀 좌표: (51, 19)
#   알파값: 0.95 | 결과: ✅ 불투명
# ✨ 호버 진입: 나무
```

### 호버 색상 변경
```gdscript
# obsticle.gd에서
var hover_modulate: Color = Color(1.2, 1.2, 1.2, 1.0)  # 밝게
# 또는
var hover_modulate: Color = Color(1.0, 0.5, 0.5, 1.0)  # 빨갛게
```

## 📊 성능 최적화

### 현재 구현된 최적화
1. **텍스처 압축 해제는 1회만** - `_ready()`에서 한 번만 실행
2. **빌보드 회전은 매 프레임** - 필수적이므로 최적화 불가
3. **레이캐스트는 매 프레임** - 정확한 호버 감지를 위해 필요

### 추가 최적화 가능
```gdscript
# 쓰로틀링 적용 (0.1초마다 체크)
var hover_check_timer: float = 0.0
const HOVER_CHECK_INTERVAL: float = 0.1

func _process(_delta):
    hover_check_timer += _delta
    if hover_check_timer >= HOVER_CHECK_INTERVAL:
        hover_check_timer = 0.0
        check_pixel_perfect_hover()
```

## 🌐 응용 가능성

### 1. 정확한 클릭 감지
```gdscript
func _input(event):
    if event is InputEventMouseButton and event.pressed:
        if is_hovered:  # 픽셀 퍼펙트로 확인된 호버 상태
            print("정확한 클릭!")
```

### 2. 복잡한 형태의 UI 버튼
- 원형, 별 모양 등 불규칙한 버튼
- 투명 영역이 많은 아이콘

### 3. 3D 페인팅 시스템
```gdscript
# 클릭한 픽셀의 색상 변경
if is_hovered:
    var pixel_pos = get_pixel_position_from_world(collision_point)
    uncompressed_image.set_pixel(pixel_pos.x, pixel_pos.y, Color.RED)
    texture.update(uncompressed_image)
```

### 4. 텍스처 기반 데이터 맵
```gdscript
# 텍스처의 색상 채널을 데이터로 활용
var pixel_color = uncompressed_image.get_pixel(x, y)
if pixel_color.r > 0.5:
    print("이 영역은 레벨 1")
elif pixel_color.g > 0.5:
    print("이 영역은 레벨 2")
```

## 🔍 트러블슈팅

### 문제: 호버가 작동하지 않음
- `Area3D`의 `collision_layer`가 제대로 설정되었는지 확인
- `input_ray_pickable = true` 설정 확인
- 디버그 모드로 로그 확인

### 문제: 잘못된 위치에서 호버 감지
- `sprite.offset` 값 확인
- `pixel_size` 값 확인
- UV 좌표 계산 로직 확인

### 문제: 성능 저하
- 쓰로틀링 적용 (0.1초마다 체크)
- 거리 기반 렌더링 활용 (`render_distance`)

## 📝 핵심 포인트 정리

1. **압축 해제**: 픽셀 읽기 위해 필수
2. **빌보드 동기화**: 충돌 박스도 카메라를 바라봐야 함
3. **레이캐스트**: 마우스 → 3D 공간 광선 발사
4. **좌표 변환**: 월드 → 로컬 → UV → 픽셀
5. **알파 체크**: 투명도로 실제 픽셀 판별

---

이 시스템을 사용하면 나무의 투명한 부분을 클릭해도 반응하지 않고, 실제 나무 부분만 정확하게 감지할 수 있습니다! 🎉
































































# 알바 시스템 - 리소스 기반 구조

## 📋 개요

알바 시스템이 **리소스 기반**으로 리팩토링되었습니다. 이제 `alba.tscn` 하나만 사용하고, 알바 데이터는 `.tres` 리소스 파일로 관리됩니다.

## 🎯 주요 변경사항

### 이전 시스템
- ❌ 알바마다 별도의 `.tscn` 파일 필요 (`alba.tscn`, `alba2.tscn`, ...)
- ❌ 코드 내에 하드코딩된 프리셋 값
- ❌ 유지보수가 어렵고 확장성 떨어짐

### 새로운 시스템
- ✅ `alba.tscn` 하나만 사용
- ✅ 알바 데이터는 `.tres` 리소스 파일로 관리
- ✅ 에디터에서 쉽게 수정 가능
- ✅ 새로운 알바 추가가 간편함

## 📁 파일 구조

```
res://
├── alba_data.gd          # AlbaData 리소스 클래스
├── alba.gd               # 알바 노드 스크립트 (리소스 사용)
├── alba.tscn             # 알바 씬 (모든 알바에서 공통 사용)
├── alba_buy.gd           # 알바 구매 시스템 (리소스 사용)
├── alba_buy.tscn         # 알바 구매 노드
│
├── alba_data_basic.tres  # 기본 알바 데이터 (600원, 25/초)
├── alba_data_1.tres      # 중급 알바 데이터 (2000원, 50/초)
└── alba_data_2.tres      # 고급 알바 데이터 (4000원, 400/초)
```

## 🔧 AlbaData 리소스 구조

```gdscript
class_name AlbaData
extends Resource

@export var alba_name: String = "알바"              # 알바 이름
@export var initial_price: int = 600               # 처음 구매 가격
@export var initial_income: int = 25                # 처음 샀을 때 초당 돈
@export var upgrade_costs: Array[int] = [...]       # 업그레이드 비용 배열
@export var upgrade_incomes: Array[int] = [...]     # 업그레이드 후 수입 배열
@export var alba_texture: Texture2D                 # 알바 이미지
@export var pet_scale: Vector2 = Vector2(1, 1)      # 펫 크기
@export var pet_offset: Vector2 = Vector2(-40, -10) # 펫 오프셋
@export var particle_color: Color = Color(...)      # 파티클 색상
```

## 📝 사용 방법

### 1️⃣ 새로운 알바 데이터 만들기

1. Godot 에디터에서 **FileSystem** 탭 우클릭
2. **New Resource...** 선택
3. `AlbaData` 검색 후 선택
4. 파일명 입력 (예: `alba_data_premium.tres`)
5. Inspector에서 값 설정:
   - **Alba Name**: "프리미엄 알바"
   - **Initial Price**: 10000
   - **Initial Income**: 1000
   - **Upgrade Costs**: [10000, 15000, 20000]
   - **Upgrade Incomes**: [1500, 2000, 3000]
   - **Alba Texture**: 이미지 드래그 앤 드롭
   - **Particle Color**: 원하는 색상 선택

### 2️⃣ 알바 구매 노드 설정하기

1. `alba_buy.tscn` 인스턴스 생성 (또는 복제)
2. Inspector에서:
   - **Alba Data**: 만든 `.tres` 파일 드래그 앤 드롭
3. 씬에 배치
4. 완료! 🎉

### 3️⃣ 직접 alba.tscn 인스턴스 배치하기

이미 게임 시작 시 알바가 고용된 상태로 시작하려면:

1. `alba.tscn` 인스턴스를 씬에 추가
2. Inspector에서:
   - **Alba Data**: `.tres` 파일 선택
3. 위치 조정 후 저장

## 📊 예시 알바 데이터

### 기본 알바 (`alba_data_basic.tres`)
- 가격: 💎600
- 수입: 💎25/초
- 업그레이드: 1000 → 2000 → 4000
- 수입 증가: 50 → 100 → 150

### 중급 알바 (`alba_data_1.tres`)
- 가격: 💎2,000
- 수입: 💎50/초
- 업그레이드: 2000 → 3000 → 4000
- 수입 증가: 120 → 200 → 350

### 고급 알바 (`alba_data_2.tres`)
- 가격: 💎4,000
- 수입: 💎400/초
- 업그레이드: 5000 → 6000
- 수입 증가: 600 → 800

## 🎨 커스터마이징 팁

### 알바 이미지 변경
```
Alba Data 리소스의 Alba Texture에 이미지 드래그 앤 드롭
```

### 파티클 색상 변경
```
Particle Color 속성에서 RGB 값 조정:
- 기본 알바: 파란색 (0.3, 0.8, 1.0)
- 중급 알바: 청록색 (0.3, 1.0, 0.8)
- 고급 알바: 핑크색 (1.0, 0.3, 0.8)
```

### 업그레이드 단계 추가
```gdscript
upgrade_costs = [1000, 2000, 3000, 5000, 10000]  # 5단계까지
upgrade_incomes = [50, 100, 200, 400, 800]
```

## ⚠️ 주의사항

1. **Alba Data는 필수**: `alba.tscn`과 `alba_buy.tscn` 모두 AlbaData 리소스가 필요합니다
2. **배열 크기 일치**: `upgrade_costs`와 `upgrade_incomes`의 크기는 같아야 합니다
3. **텍스처 선택 사항**: Alba Texture를 null로 두면 기본 스프라이트 사용

## 🔄 기존 프로젝트 마이그레이션

기존에 `alba2.tscn`, `alba_buy2.tscn` 등을 사용했다면:

1. 각 알바의 설정값을 확인
2. 해당 값으로 `.tres` 리소스 생성
3. 씬의 `alba_buy` 노드에 리소스 연결
4. 기존 `.tscn` 파일 삭제 가능

## 🚀 장점

1. **확장성**: 새 알바 추가 시 `.tres` 파일만 생성
2. **유지보수**: 밸런스 조정이 에디터에서 간편
3. **재사용성**: `alba.tscn` 하나로 모든 알바 표현
4. **직관성**: Inspector에서 모든 값 확인 가능
5. **버전 관리**: `.tres` 파일은 텍스트 형식이라 Git에서 merge 용이

## 📚 관련 파일

- `alba_data.gd` - 리소스 클래스 정의
- `alba.gd` - 알바 노드 로직
- `alba_buy.gd` - 구매 시스템 로직
- `globals.gd` - 전역 변수 (money_per_second 등)


# 알바 시스템 리팩토링 완료 ✅

## 변경 사항 요약

### 📦 새로 생성된 파일
1. **alba_data.gd** - AlbaData 리소스 클래스
   - 알바의 모든 정보를 담는 리소스
   - 처음 구매가격, 초당 돈, 업그레이드 비용/수입, 이미지 등

2. **alba_data_basic.tres** - 기본 알바 데이터
   - 가격: 600원, 수입: 25/초
   
3. **alba_data_1.tres** - 중급 알바 데이터
   - 가격: 2,000원, 수입: 50/초
   
4. **alba_data_2.tres** - 고급 알바 데이터
   - 가격: 4,000원, 수입: 400/초

5. **ALBA_SYSTEM_README.md** - 사용 가이드
   - 새로운 시스템 사용법 및 예시

### 🔧 수정된 파일
1. **alba.gd**
   - `@export var alba_data: AlbaData` 추가
   - `load_from_resource()` 함수로 리소스 데이터 로드
   - 프리셋 시스템 제거 (apply_alba_preset, _get_alba_texture 삭제)
   - 알바 이름 표시 개선

2. **alba_buy.gd**
   - `@export var alba_data: AlbaData` 추가
   - 프리셋 시스템 완전 제거
   - 리소스에서 직접 가격/수입 정보 가져오기
   - `apply_preset_to_alba()` 함수 삭제

### 🗑️ 삭제된 파일
- **alba2.tscn** - 더 이상 필요없음 (alba.tscn 하나로 통일)
- **alba_buy2.tscn** - 더 이상 필요없음

## 시스템 구조

### 이전 (프리셋 기반)
```
alba.tscn (프리셋: custom/alba1/alba2)
alba2.tscn (하드코딩된 값)
alba_buy.gd (프리셋 분기 처리)
```

### 현재 (리소스 기반)
```
alba_data.gd (리소스 클래스)
  ↓
alba_data_*.tres (데이터 파일들)
  ↓
alba.tscn (리소스 적용)
alba_buy.tscn (리소스 전달)
```

## 사용 예시

### 씬 설정
```
alba_buy 노드:
  └─ Alba Data: alba_data_1.tres 드래그 앤 드롭
```

### 새 알바 추가
1. `alba_data_premium.tres` 생성
2. Inspector에서 값 설정
3. `alba_buy` 노드에 연결
4. 완료! 🎉

## 장점

✅ **확장성**: 새 알바는 `.tres` 파일만 생성
✅ **유지보수**: 에디터에서 직접 수정 가능
✅ **재사용성**: `alba.tscn` 하나로 모든 알바 표현
✅ **직관성**: Inspector에서 모든 값 확인
✅ **Git 친화적**: `.tres`는 텍스트 파일

## 테스트 필요 항목

1. [ ] 기본 알바 구매 및 배치
2. [ ] 알바 업그레이드 시스템
3. [ ] 알바 펫 추적 시스템
4. [ ] 구매 가능 시각 피드백
5. [ ] 여러 알바 동시 고용

## 다음 단계

1. Godot 에디터에서 `alba.tscn` 열기
2. 루트 노드 선택 → Inspector에서 `Alba Data` 설정
3. `alba_buy.tscn` 인스턴스들의 `Alba Data` 설정
4. 게임 실행 및 테스트


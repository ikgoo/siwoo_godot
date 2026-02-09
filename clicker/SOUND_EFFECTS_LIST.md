# 🎵 게임 효과음 전체 목록

> **프로젝트**: Mine Clicker (siwoo_godot/clicker)  
> **작성일**: 2026-02-08  
> **현재 보유 사운드**: `normal_rock.mp3` (일반 채굴), `x2_sound.mp3` (크리티컬/잭팟)

---

## 📋 목차

1. [채굴 시스템 (핵심 루프)](#1-채굴-시스템-핵심-루프)
2. [캐릭터 이동/액션](#2-캐릭터-이동액션)
3. [설치 시스템 (빌드 모드)](#3-설치-시스템-빌드-모드)
4. [업그레이드 시스템](#4-업그레이드-시스템)
5. [경제/거래 시스템](#5-경제거래-시스템)
6. [아이템 수집](#6-아이템-수집)
7. [요정 시스템](#7-요정-시스템)
8. [벽/문 시스템](#8-벽문-시스템)
9. [피버/텔레포트 시스템](#9-피버텔레포트-시스템)
10. [티어 업 시스템](#10-티어-업-시스템)
11. [UI/메뉴](#11-ui메뉴)
12. [튜토리얼 시스템](#12-튜토리얼-시스템)
13. [로비/씬 전환](#13-로비씬-전환)
14. [Auto Scene (봉고캣 클리커)](#14-auto-scene-봉고캣-클리커)
15. [BGM (배경음악)](#15-bgm-배경음악)
16. [우선순위 정리](#16-우선순위-정리)
17. [구현 가이드](#17-구현-가이드)

---

## 1. 채굴 시스템 (핵심 루프)

| # | 파일명 | 트리거 위치 | 상태 | 설명 |
|---|--------|------------|------|------|
| 1 | `sfx_rock_hit` | `rock.gd` → `complete_mining()` | ✅ 있음 (`normal_rock.mp3`) | F키 게이지 완충 → 돌 채굴 시 일반 타격음 |
| 2 | `sfx_rock_critical` | `rock.gd` → `spawn_floating_text_critical()` | ✅ 있음 (`x2_sound.mp3`) | x2 크리티컬 보너스 히트 |
| 3 | `sfx_rock_jackpot` | `rock.gd` → `spawn_floating_text_jackpot()` | ⚠️ x2와 동일 | x3 잭팟! 더 임팩트 있는 별도 소리 필요 |
| 4 | `sfx_tile_hit` | `breakable_tile.gd` → `mine_nearest_tile()` | ❌ 없음 | 벽 타일 좌클릭 타격 (HP 감소 시마다 재생) |
| 5 | `sfx_tile_break` | `breakable_tile.gd` → `break_tile()` | ⚠️ 노드만 존재 | 벽 타일 완전 파괴 시 부서지는 소리 |
| 6 | `sfx_charge_tick` | `character.gd` → `add_charge()` | ❌ 없음 | F키로 게이지 한 칸 올릴 때 짧은 "딸깍" |
| 7 | `sfx_charge_full` | `character.gd` → `release_charge()` | ❌ 없음 | 게이지 100% 완충 시 "팅!" 효과음 |
| 8 | `sfx_pickaxe_swing` | `character.gd` → `start_pickaxe_animation()` | ❌ 없음 | 곡괭이 휘두르는 "쉭" 바람 소리 |

### 상세 설명

- **`sfx_rock_hit`**: `rock.gd`의 오디오 풀링 시스템(`normal_sound_pool`)에서 재생. 채굴 빈도가 높으므로 풀 크기 5 유지.
- **`sfx_rock_jackpot`**: 현재 `good_sound_pool`에서 x2/x3 모두 같은 소리 사용. x3 전용 사운드를 별도로 만들면 잭팟의 특별함 강조 가능.
- **`sfx_charge_tick`**: 연타 시 겹쳐 재생됨. 매우 짧은 소리(0.05~0.1초) 권장. `pitch_scale`을 게이지 진행도에 비례하여 올리면 긴장감 증대.
- **`sfx_charge_full`**: `release_charge()` 호출 시 1회 재생. `sfx_pickaxe_swing`과 동시에 재생되어도 자연스럽도록 주파수 대역을 다르게.

---

## 2. 캐릭터 이동/액션

| # | 파일명 | 트리거 위치 | 상태 | 설명 |
|---|--------|------------|------|------|
| 9 | `sfx_footstep` | `character.gd` → 걷기 상태 (State.WALKING) | ❌ 없음 | 걷기 발소리 (애니메이션 프레임 동기화 권장) |
| 10 | `sfx_run_footstep` | `character.gd` → Shift 달리기 | ❌ 없음 | 빠른 발소리 (달리기 전용, 선택적) |
| 11 | `sfx_jump` | `character.gd` → `velocity.y = JUMP_VELOCITY` | ❌ 없음 | 점프 시작 "파닥" |
| 12 | `sfx_land` | `character.gd` → `spawn_landing_particles()` | ❌ 없음 | 착지 "쿵" (파티클과 동시 재생) |
| 13 | `sfx_platform_pass` | `character.gd` → S+Space 플랫폼 통과 | ❌ 없음 | 아래로 내려갈 때 "슝" (선택적) |

### 상세 설명

- **`sfx_footstep`**: `AnimationPlayer`의 walk 애니메이션에 Audio Track으로 삽입하면 프레임 동기화가 자연스러움. 2~3개 변형(variation) 랜덤 재생 권장.
- **`sfx_land`**: `spawn_landing_particles()` 내부에서 파티클 생성과 동시에 재생. 높은 곳에서 떨어질수록 볼륨을 키우면 좋음(낙하 속도 `velocity.y` 기반).
- **`sfx_run_footstep`**: 걷기와 다른 소리가 필요 없다면 `sfx_footstep`의 재생 간격만 줄여서 사용 가능.

---

## 3. 설치 시스템 (빌드 모드)

| # | 파일명 | 트리거 위치 | 상태 | 설명 |
|---|--------|------------|------|------|
| 14 | `sfx_torch_place` | `character.gd` → `place_torch()` | ❌ 없음 | 횃불 설치 "탁" + 불 붙는 소리 |
| 15 | `sfx_platform_place` | `character.gd` → `place_platform()` | ❌ 없음 | 플랫폼 설치 "딱" (나무/돌 느낌) |
| 16 | `sfx_build_mode_toggle` | `character.gd` → 2번/3번 키 토글 | ❌ 없음 | 빌드 모드 전환 "딸깍" |
| 17 | `sfx_build_fail` | `character.gd` → 설치 불가 판정 시 | ❌ 없음 | 설치 실패 "뿍" (거리 초과, 중복 등) |

### 상세 설명

- **`sfx_torch_place`**: 횃불 설치 성공 시 `place_torch()` 함수의 `"✅ 횃불 설치 완료"` 로그 위치에서 재생.
- **`sfx_build_fail`**: 거리 초과(`distance > max_place_distance`), 타일 중복(`_is_position_inside_any_tile`), 횃불 중복(`_has_torch_at_tile`) 등 모든 실패 경우에 재생.

---

## 4. 업그레이드 시스템

| # | 파일명 | 트리거 위치 | 상태 | 설명 |
|---|--------|------------|------|------|
| 18 | `sfx_upgrade_open` | `upgrade.gd` → `_open_upgrade_menu()` | ❌ 없음 | NPC 대화 메뉴 열기 |
| 19 | `sfx_upgrade_buy` | `upgrade_menu.gd` → 업그레이드 구매 성공 | ❌ 없음 | 업그레이드 구매 "챠링!" |
| 20 | `sfx_upgrade_fail` | `upgrade_menu.gd` → 돈 부족 시 | ❌ 없음 | 구매 실패 "뿔뿔" (비프음) |
| 21 | `sfx_upgrade_max` | `upgrade_menu.gd` → MAX 레벨 도달 | ❌ 없음 | 최대 레벨 달성 "짜잔!" (선택적) |
| 22 | `sfx_upgrade_anim` | `upgrade.gd` → `play_upgrade_animation()` | ❌ 없음 | NPC 카메라 줌인 + 모션 연출 효과음 |
| 23 | `sfx_menu_close` | `upgrade_menu.gd` → 메뉴 닫기 | ❌ 없음 | 메뉴 닫기 "슝" |

### 상세 설명

- **`sfx_upgrade_buy`**: `upgrade_menu.gd`에서 `upgrade_purchased` 시그널 emit 시점에 재생.
- **`sfx_upgrade_anim`**: `play_upgrade_animation()`의 카메라 줌인(0.5초) → 대기(1초) → motion 애니메이션(2초) 시퀀스에 맞춰 여러 소리를 순차 재생할 수 있음:
  - 줌인 시작: "우웅" (확대 효과음)
  - motion 시작: "짠!" (NPC 액션 효과음)
  - 줌아웃: "슉" (축소 효과음)

---

## 5. 경제/거래 시스템

| # | 파일명 | 트리거 위치 | 상태 | 설명 |
|---|--------|------------|------|------|
| 24 | `sfx_money_gain` | `Globals` → `money` 증가 시 | ❌ 없음 | 돈 획득 "쨘" (코인 소리, 선택적 — 빈번함 주의) |
| 25 | `sfx_alba_buy` | `alba_buy.gd` → `purchase_alba()` 성공 | ❌ 없음 | 알바 구매 "까-칭!" |
| 26 | `sfx_alba_upgrade` | `alba.gd` → `upgrade_alba()` 성공 | ❌ 없음 | 알바 강화 성공 |
| 27 | `sfx_alba_fail` | `alba.gd` / `alba_buy.gd` → 돈 부족 시 | ❌ 없음 | 알바 구매/강화 실패 |

### 상세 설명

- **`sfx_money_gain`**: `Globals.money` setter에서 `money_changed` 시그널 emit 시 재생. **주의**: 채굴 빈도가 매우 높으므로 매번 재생하면 피로감 유발. 일정 금액 이상 변동 시에만 재생하거나, 아예 생략하고 채굴음으로 대체 권장.
- **`sfx_alba_buy`**: `alba_buy.gd` → `purchase_alba()` 성공 시 `is_purchased = true` 직후에 재생.

---

## 6. 아이템 수집

| # | 파일명 | 트리거 위치 | 상태 | 설명 |
|---|--------|------------|------|------|
| 28 | `sfx_cave_item_collect` | `cave_item.gd` → `_on_body_entered()` | ❌ 없음 | 동굴 아이템 수집 "반짝!" (업그레이드 해금) |
| 29 | `sfx_fairy_item_collect` | `fairy_item.gd` → `_collect()` | ❌ 없음 | 요정 능력 아이템 획득 "빛나는 차임벨" |
| 30 | `sfx_upgrade_unlock` | `Globals` → `upgrade_type_unlocked` 시그널 | ❌ 없음 | 새 업그레이드 타입 해금 알림 "팡파레" |

### 상세 설명

- **`sfx_cave_item_collect`**: 플레이어가 `Area2D`에 닿는 순간 자동 수집. `_play_collect_animation()` 시작 시 재생. 업그레이드가 해금되는 중요 이벤트이므로 인상적인 소리 필요.
- **`sfx_fairy_item_collect`**: F키를 눌러 획득하므로 유저 의지에 의한 수집. `cave_item`과 비슷하지만 약간 다른 톤(요정 테마) 권장.
- **`sfx_upgrade_unlock`**: `cave_item_collect` 직후 연속 재생. 약간의 딜레이(0.3초) 후 재생하면 "수집" → "해금" 2단계 피드백.

---

## 7. 요정 시스템

| # | 파일명 | 트리거 위치 | 상태 | 설명 |
|---|--------|------------|------|------|
| 31 | `sfx_fairy_warp` | `fairy.gd` → `start_warp()` / `end_warp()` | ❌ 없음 | 요정 순간이동 "슈웅" |
| 32 | `sfx_fairy_mine` | `fairy.gd` → `start_mining()` (J키) | ❌ 없음 | 요정 곡괭이 채굴 짧은 "틱" |
| 33 | `sfx_fairy_appear` | `tutorial_manager.gd` → `spawn_fairy()` | ❌ 없음 | 요정 첫 등장 "반짝!" (선택적) |

### 상세 설명

- **`sfx_fairy_warp`**: `warp_distance`(150px) 이상 떨어지거나 `stuck_warp_time`(2초) 이상 벽에 막히면 발동. `start_warp()` 시 1회, `end_warp()` 시 1회 재생(출발/도착 각각).
- **`sfx_fairy_mine`**: J키 채굴 시 `player.add_charge()`와 동시에 재생. 플레이어 채굴음보다 가볍고 짧은 소리.

---

## 8. 벽/문 시스템

| # | 파일명 | 트리거 위치 | 상태 | 설명 |
|---|--------|------------|------|------|
| 34 | `sfx_wall_vibrate` | `wall.gd` → `vibration()` | ❌ 없음 | 벽 진동 "우우웅" (열리기 직전 0.8초) |
| 35 | `sfx_wall_open` | `wall.gd` → `open_wall()` 애니메이션 | ❌ 없음 | 문 열리는 "쿠쿠쿠궁" (거대한 돌문) |

### 상세 설명

- **`sfx_wall_vibrate`**: `vibration(0.5)` → `0.8초 대기` → `vib_end()` 시퀀스. 진동 시작과 동시에 재생, 0.8초 길이의 럼블링 사운드.
- **`sfx_wall_open`**: `animation_player.play("open")` 직후 재생. 카메라가 벽에 줌인된 상태이므로 임팩트 있는 소리 필요. `open` 애니메이션 길이에 맞춤.

---

## 9. 피버/텔레포트 시스템

| # | 파일명 | 트리거 위치 | 상태 | 설명 |
|---|--------|------------|------|------|
| 36 | `sfx_fever_start` | `goal_area.gd` → `activate_fever()` | ❌ 없음 | 피버 모드 발동 "파워업!" |
| 37 | `sfx_fever_end` | `goal_area.gd` → `_on_fever_timeout()` | ❌ 없음 | 피버 모드 종료 "파워다운" |
| 38 | `sfx_teleport` | `goal_area.gd` → `teleport_character()` | ❌ 없음 | 텔레포트 "슈우웅" |

### 상세 설명

- **`sfx_fever_start`**: 피버 배율 2배 적용 시작 시 재생. 10초 지속 동안 BGM 변경 또는 필터 효과를 추가하면 더 효과적.
- **`sfx_teleport`**: `spawn_teleport_effect()` 두 번 호출됨 (출발점 + 도착점). 출발/도착 각각 다른 소리 또는 같은 소리 2번.

---

## 10. 티어 업 시스템

| # | 파일명 | 트리거 위치 | 상태 | 설명 |
|---|--------|------------|------|------|
| 39 | `sfx_tier_up` | `Globals` → `tier_up` 시그널 | ❌ 없음 | 채굴 티어 상승 "레벨업!" 팡파레 |

### 상세 설명

- **`sfx_tier_up`**: `Globals.tier_up` 시그널 발생 시 재생. 게임 진행에서 매우 중요한 이정표이므로 2~3초 길이의 화려한 팡파레 사운드 권장. 벽이 열리는 연출(`wall.gd`)과 연계될 수 있음.

---

## 11. UI/메뉴

| # | 파일명 | 트리거 위치 | 상태 | 설명 |
|---|--------|------------|------|------|
| 40 | `sfx_button_hover` | 모든 Button → `mouse_entered` | ❌ 없음 | 버튼 호버 "톡" (매우 가벼운 소리) |
| 41 | `sfx_button_click` | 모든 Button → `pressed` | ❌ 없음 | 버튼 클릭 "딸깍" |
| 42 | `sfx_esc_menu_open` | `esc_menu.gd` → `open_menu()` | ❌ 없음 | ESC 메뉴 열기 |
| 43 | `sfx_esc_menu_close` | `esc_menu.gd` → `close_menu()` | ❌ 없음 | ESC 메뉴 닫기 |
| 44 | `sfx_shop_open` | `shop_menu.gd` → 상점 열기 | ❌ 없음 | 스킨 상점 열기 |
| 45 | `sfx_skin_buy` | `shop_menu.gd` → 스킨 구매 | ❌ 없음 | 스킨 구매 성공 |
| 46 | `sfx_skin_equip` | `shop_menu.gd` → 스킨 장착 | ❌ 없음 | 스킨 장착 "착!" |
| 47 | `sfx_setting_change` | `setting.gd` → 볼륨/언어 변경 | ❌ 없음 | 설정 슬라이더 조절 "틱" |

### 상세 설명

- **`sfx_button_hover` / `sfx_button_click`**: 글로벌 UI 테마로 일괄 적용 가능. Godot의 `Theme` 리소스에서 `AudioStream`을 설정하거나, 커스텀 `BaseButton` 스크립트를 만들어 모든 버튼에 적용.
- **`sfx_esc_menu_open` / `sfx_esc_menu_close`**: `get_tree().paused = true/false` 전환과 함께 재생. `process_mode = PROCESS_MODE_ALWAYS` 설정 필수.

---

## 12. 튜토리얼 시스템

| # | 파일명 | 트리거 위치 | 상태 | 설명 |
|---|--------|------------|------|------|
| 48 | `sfx_dialogue_typing` | `dialogue_box.gd` → `type_next_character()` | ❌ 없음 | 타이핑 효과음 "따따따" (글자마다) |
| 49 | `sfx_dialogue_next` | `dialogue_box.gd` → `next_dialogue()` | ❌ 없음 | 다음 대사로 넘기기 "톡" |
| 50 | `sfx_dialogue_complete` | `dialogue_box.gd` → `end_dialogue()` | ❌ 없음 | 대화 완료 시 닫힘 효과음 |
| 51 | `sfx_tutorial_complete` | `tutorial_manager.gd` → `finish_tutorial()` | ❌ 없음 | 튜토리얼 완료 팡파레 |
| 52 | `sfx_tutorial_popup` | `tutorial_popup.gd` → 팝업 표시 | ❌ 없음 | 튜토리얼 팝업 등장 |

### 상세 설명

- **`sfx_dialogue_typing`**: `type_next_character()`에서 글자 1개당 1회 재생. `typing_speed`가 0.05초이므로 초당 20회 재생됨. 매우 짧은 소리(0.02~0.05초) 또는 2~3글자마다 1회 재생하는 것이 자연스러움.
- **`sfx_tutorial_complete`**: 튜토리얼의 최종 완료 시점. `sfx_tier_up`과 비슷한 레벨의 화려한 사운드.

---

## 13. 로비/씬 전환

| # | 파일명 | 트리거 위치 | 상태 | 설명 |
|---|--------|------------|------|------|
| 53 | `sfx_lobby_start` | `lobby.gd` → 아무 키 입력 | ❌ 없음 | "Press Any Key" 후 게임 시작 전환음 |
| 54 | `sfx_scene_transition` | 씬 전환 시 (`change_scene_to_file`) | ❌ 없음 | 씬 전환 페이드 효과음 |

### 상세 설명

- **`sfx_lobby_start`**: `_on_start_button_up()` → `animation_player.play("close")` 시점에 재생. "close" 애니메이션 길이에 맞춤.
- **`sfx_scene_transition`**: `lobby` → `main`, `main` → `auto_scene`, `auto_scene` → `lobby` 모든 전환에 공통 사용 가능.

---

## 14. Auto Scene (봉고캣 클리커)

| # | 파일명 | 트리거 위치 | 상태 | 설명 |
|---|--------|------------|------|------|
| 55 | `sfx_auto_click` | `auto_scene.gd` → `_on_click()` | ❌ 없음 | 클릭 시 "톡톡" (봉고캣 드럼 소리) |
| 56 | `sfx_auto_coin` | `auto_scene.gd` → `auto_money` 증가 | ❌ 없음 | 코인 획득 "찰랑" (선택적) |

### 상세 설명

- **`sfx_auto_click`**: 키보드/마우스 모든 입력에서 `_on_click()` 호출 시 재생. 봉고캣 테마에 맞게 타악기(봉고 드럼) 소리 권장. 2~3개 변형(variation) 랜덤 재생.
- **`sfx_auto_coin`**: `_on_click()`과 동시 재생 시 소리가 겹침. `sfx_auto_click`에 코인 느낌을 합치거나, `sfx_auto_coin`은 생략 가능.

---

## 15. BGM (배경음악)

| # | 파일명 | 사용 씬 | 상태 | 설명 |
|---|--------|--------|------|------|
| 57 | `bgm_lobby` | `lobby.tscn` | ❌ 없음 | 로비 배경음악 (잔잔한 피아노/어쿠스틱) |
| 58 | `bgm_main` | `main.tscn` | ❌ 없음 | 메인 게임 BGM (광산/모험 느낌) |
| 59 | `bgm_cave` | 동굴 진입 시 | ❌ 없음 | 동굴 내부 배경음 (환경음/어두운 분위기, 선택적) |
| 60 | `bgm_auto` | `auto_scene.tscn` | ❌ 없음 | 오토씬 BGM (가볍고 귀여운 루프) |
| 61 | `bgm_fever` | 피버 모드 활성 시 | ❌ 없음 | 피버 모드 전용 BGM (빠르고 신나는, 선택적) |

### 상세 설명

- **`bgm_main`**: 게임의 대부분을 차지하므로 루프 포인트가 자연스러워야 함. `.ogg` 포맷으로 루프 설정 권장.
- **`bgm_cave`**: `bgm_main`과 크로스페이드로 전환하거나, 환경음(물방울, 바람)을 오버레이하는 방식도 가능.
- **`bgm_fever`**: 10초 지속이므로 짧은 루프. `bgm_main` 위에 오버레이로 재생하거나 완전 교체.

---

## 16. 우선순위 정리

### 🔴 필수 (핵심 게임 루프에 직결)

| 우선순위 | 효과음 | 번호 |
|---------|--------|------|
| ★★★ | `sfx_charge_tick` — 게이지 한 칸 올리기 | #6 |
| ★★★ | `sfx_charge_full` — 게이지 완충 | #7 |
| ★★★ | `sfx_tile_hit` — 벽 타일 타격 | #4 |
| ★★★ | `sfx_tile_break` — 벽 타일 파괴 | #5 |
| ★★★ | `sfx_pickaxe_swing` — 곡괭이 스윙 | #8 |
| ★★★ | `sfx_rock_jackpot` — x3 잭팟 (별도 소리) | #3 |

### 🟠 높음 (유저 피드백/만족도)

| 우선순위 | 효과음 | 번호 |
|---------|--------|------|
| ★★☆ | `sfx_jump` — 점프 | #11 |
| ★★☆ | `sfx_land` — 착지 | #12 |
| ★★☆ | `sfx_upgrade_buy` — 업그레이드 구매 | #19 |
| ★★☆ | `sfx_cave_item_collect` — 동굴 아이템 수집 | #28 |
| ★★☆ | `sfx_wall_open` — 벽 열림 | #35 |
| ★★☆ | `sfx_tier_up` — 티어 상승 | #39 |
| ★★☆ | `sfx_dialogue_typing` — 대화 타이핑 | #48 |
| ★★☆ | `bgm_main` — 메인 BGM | #58 |

### 🟡 중간 (게임 분위기 강화)

| 우선순위 | 효과음 | 번호 |
|---------|--------|------|
| ★☆☆ | `bgm_lobby` — 로비 BGM | #57 |
| ★☆☆ | `sfx_torch_place` — 횃불 설치 | #14 |
| ★☆☆ | `sfx_fever_start` — 피버 시작 | #36 |
| ★☆☆ | `sfx_teleport` — 텔레포트 | #38 |
| ★☆☆ | `sfx_button_click` — 버튼 클릭 | #41 |
| ★☆☆ | `sfx_auto_click` — 오토씬 클릭 | #55 |
| ★☆☆ | `sfx_alba_buy` — 알바 구매 | #25 |
| ★☆☆ | `sfx_fairy_item_collect` — 요정 아이템 | #29 |
| ★☆☆ | `sfx_tutorial_complete` — 튜토리얼 완료 | #51 |
| ★☆☆ | `sfx_lobby_start` — 로비 시작 | #53 |

### 🟢 낮음 (폴리시/디테일)

| 우선순위 | 효과음 | 번호 |
|---------|--------|------|
| ☆☆☆ | `sfx_footstep` — 발소리 | #9 |
| ☆☆☆ | `sfx_fairy_warp` — 요정 워프 | #31 |
| ☆☆☆ | `sfx_fairy_mine` — 요정 채굴 | #32 |
| ☆☆☆ | `sfx_button_hover` — 버튼 호버 | #40 |
| ☆☆☆ | `sfx_setting_change` — 설정 변경 | #47 |
| ☆☆☆ | `sfx_platform_pass` — 플랫폼 통과 | #13 |
| ☆☆☆ | `sfx_build_mode_toggle` — 빌드 모드 전환 | #16 |
| ☆☆☆ | `sfx_wall_vibrate` — 벽 진동 | #34 |
| ☆☆☆ | `sfx_fairy_appear` — 요정 등장 | #33 |

---

## 17. 구현 가이드

### 오디오 버스 구조

프로젝트의 `setting.gd`에서 이미 3개 버스를 관리 중:

```
Master (마스터)
├── BGM (배경음악)
└── SFX (효과음)
```

- 모든 SFX는 `bus = "SFX"`로 설정
- 모든 BGM은 `bus = "BGM"`으로 설정
- `Globals.master_volume`, `Globals.bgm_volume`, `Globals.sfx_volume`이 각각 제어

### 오디오 풀링 패턴 (기존 구현 참조)

`rock.gd`에 이미 구현된 오디오 풀링 패턴:

```gdscript
# 풀 초기화 (rock.gd 참조)
var sound_pool: Array[AudioStreamPlayer] = []
const AUDIO_POOL_SIZE: int = 5

func _init_audio_pool():
	for i in range(AUDIO_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.stream = preload("res://sounds/sfx_example.wav")
		player.bus = "SFX"
		add_child(player)
		sound_pool.append(player)

func _play_from_pool(pool: Array[AudioStreamPlayer]):
	for player in pool:
		if not player.playing:
			player.play()
			return
	if pool.size() > 0:
		pool[0].play()
```

**풀링이 필요한 효과음** (빈번하게 재생):
- `sfx_charge_tick` (#6) — 연타 시 초당 10회 이상
- `sfx_tile_hit` (#4) — 홀드 클릭으로 연속 재생
- `sfx_footstep` (#9) — 걷기 중 지속 재생
- `sfx_dialogue_typing` (#48) — 초당 20회
- `sfx_auto_click` (#55) — 연타 가능

### 피치 랜디마이즈

반복 효과음의 자연스러움을 위해:

```gdscript
func play_with_random_pitch(player: AudioStreamPlayer):
	player.pitch_scale = randf_range(0.9, 1.1)
	player.play()
```

**적용 권장 대상**: `sfx_footstep`, `sfx_charge_tick`, `sfx_tile_hit`, `sfx_auto_click`

### 파일 포맷 권장

| 용도 | 포맷 | 이유 |
|------|------|------|
| 짧은 SFX (< 1초) | `.wav` | 지연 없음, 빠른 재생 |
| 긴 SFX (> 1초) | `.ogg` | 파일 크기 절약 |
| BGM (루프) | `.ogg` | 루프 포인트 설정 가능 |
| ~~MP3~~ | 비권장 | Godot에서 루프 제한, 디코딩 지연 |

### 권장 폴더 구조

```
res://sounds/
├── sfx/
│   ├── mining/          # 채굴 관련
│   │   ├── sfx_rock_hit.wav
│   │   ├── sfx_rock_critical.wav
│   │   ├── sfx_rock_jackpot.wav
│   │   ├── sfx_tile_hit.wav
│   │   ├── sfx_tile_break.wav
│   │   ├── sfx_charge_tick.wav
│   │   ├── sfx_charge_full.wav
│   │   └── sfx_pickaxe_swing.wav
│   ├── character/       # 캐릭터 관련
│   │   ├── sfx_footstep_01.wav
│   │   ├── sfx_footstep_02.wav
│   │   ├── sfx_jump.wav
│   │   └── sfx_land.wav
│   ├── build/           # 설치 관련
│   │   ├── sfx_torch_place.wav
│   │   ├── sfx_platform_place.wav
│   │   └── sfx_build_fail.wav
│   ├── ui/              # UI 관련
│   │   ├── sfx_button_hover.wav
│   │   ├── sfx_button_click.wav
│   │   ├── sfx_menu_open.wav
│   │   └── sfx_menu_close.wav
│   ├── upgrade/         # 업그레이드 관련
│   │   ├── sfx_upgrade_buy.wav
│   │   ├── sfx_upgrade_fail.wav
│   │   └── sfx_upgrade_max.wav
│   ├── item/            # 아이템 수집
│   │   ├── sfx_cave_item_collect.wav
│   │   ├── sfx_fairy_item_collect.wav
│   │   └── sfx_upgrade_unlock.wav
│   ├── fairy/           # 요정 관련
│   │   ├── sfx_fairy_warp.wav
│   │   └── sfx_fairy_mine.wav
│   ├── world/           # 월드 이벤트
│   │   ├── sfx_wall_vibrate.ogg
│   │   ├── sfx_wall_open.ogg
│   │   ├── sfx_fever_start.wav
│   │   ├── sfx_fever_end.wav
│   │   ├── sfx_teleport.wav
│   │   └── sfx_tier_up.ogg
│   ├── dialogue/        # 대화/튜토리얼
│   │   ├── sfx_dialogue_typing.wav
│   │   ├── sfx_dialogue_next.wav
│   │   └── sfx_tutorial_complete.ogg
│   └── auto/            # 오토씬
│       ├── sfx_auto_click_01.wav
│       └── sfx_auto_click_02.wav
└── bgm/
	├── bgm_lobby.ogg
	├── bgm_main.ogg
	├── bgm_cave.ogg
	├── bgm_auto.ogg
	└── bgm_fever.ogg
```

---

## 📊 전체 요약

| 카테고리 | 효과음 수 | 필수 | 높음 | 중간 | 낮음 |
|---------|----------|------|------|------|------|
| 채굴 시스템 | 8 | 6 | - | - | 2 |
| 캐릭터 이동 | 5 | - | 2 | - | 3 |
| 설치 시스템 | 4 | - | - | 1 | 3 |
| 업그레이드 | 6 | - | 1 | - | 5 |
| 경제/거래 | 4 | - | - | 1 | 3 |
| 아이템 수집 | 3 | - | 1 | 2 | - |
| 요정 | 3 | - | - | - | 3 |
| 벽/문 | 2 | - | 1 | - | 1 |
| 피버/텔레포트 | 3 | - | - | 2 | 1 |
| 티어 업 | 1 | - | 1 | - | - |
| UI/메뉴 | 8 | - | - | 1 | 7 |
| 튜토리얼 | 5 | - | 1 | 1 | 3 |
| 로비/씬 전환 | 2 | - | - | 1 | 1 |
| Auto Scene | 2 | - | - | 1 | 1 |
| **SFX 소계** | **56** | **6** | **7** | **10** | **33** |
| BGM | 5 | - | 1 | 1 | 3 |
| **총합** | **61** | **6** | **8** | **11** | **36** |

> ✅ 이미 존재: 2개 (`normal_rock.mp3`, `x2_sound.mp3`)  
> ❌ 추가 필요: 최대 59개 (우선순위에 따라 단계적 추가 권장)

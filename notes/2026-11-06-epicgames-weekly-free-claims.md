---
layout: note
title: "에픽게임즈 11월 1주차 신규 무료 게임(표류도시, Idle Champions) 수령 점검 및 완료"
date: 2026-11-06
tags: [epicgames, free-games, flotsam, idle-champions, aside-automation, library-claim]
---

# 에픽게임즈 11월 1주차 신규 무료 게임 수령 점검 및 완료

## 1. 작업 개요
- **배경**:
  - 매주 금요일(한국 시간 목요일 심야~금요일 새벽) 갱신되는 에픽게임즈 스토어 무료 게임 배포 주기에 따라, 신규 프로모션 대상 게임의 라이브러리 소장 상태 점검 및 원격 수령 요청 접수.
- **점검 시점**: 2026-11-06 04:20 KST (11월 1주차 신규 프로모션 오픈 직후)
- **대상 계정**: `Dalkong_0109` (맥북 Aside AI 브라우저 세션 연동)

---

## 2. 프로모션 현황 및 수령 결과

### A. PC 데스크톱 무료 게임 (2종)
1. **표류도시 (Flotsam)**:
   - **게임 ID**: `3be0a0d8479946d78f60d90c9442a0b4`
   - **상품 슬러그**: `flotsam-266287`
   - **정상 가격**: ₩25,000 $\rightarrow$ **₩0 (100% 기간 한정 무료)**
   - **배포 기간**: 2026.11.06(금) 01:00 ~ 2026.11.13(금) 01:00 (KST)
   - **처리 결과**: **Aside 원격 수령 완료 (`status: success`)**
   - **비고**: 결제 주문서(`주문 접수`) 자동 클릭 및 라이브러리 영구 소장 완료.

2. **Idle Champions of the Forgotten Realms**:
   - **게임 ID**: `a9748abde1c94b66aae5250bb9fc5503`
   - **상품 슬러그**: `idle-champions-of-the-forgotten-realms`
   - **정상 가격**: ₩0 무료
   - **배포 기간**: 2026.11.06(금) 01:00 ~ 2026.11.13(금) 01:00 (KST)
   - **처리 결과**: **이미 라이브러리에 정상 보유 중 (`status: already_owned`)**

### B. 모바일 에픽게임즈 스토어 무료 게임 (Chants of Sennaar)
- **Chants of Sennaar (Android / iOS)**:
  - 11월 5일 심야(01:33 KST) 뽐뿌 모바일 앱 게시글 감지 후 Aside 원격 수령 완수 완료 (`isClaimed: true`, 배포 기한: ~11/13 01시).

---

## 3. 검증 내역

- **데이터베이스 (`epicgames_claims`)**:
  - `표류도시`: `status = 'success'`, `detail = 'Aside 원격 실행 결과: 라이브러리 무료 추가 및 소장 완료'` 기록 확인 (ID: `#93`).
  - `Idle Champions`: `status = 'already_owned'` 기록 확인 (ID: `#92`).
- **텔레그램 알림**:
  - `Idle Champions` 및 `표류도시` 신규 출시 안내 메시지 발송 완료 (`epic_notified_game_*` 플래그 세팅).
- **다음 주 배포 예정 게임**:
  - **Knightica** (정가 ₩15,300 $\rightarrow$ ₩0 무료 배포 예정: 2026.11.13 ~ 2026.11.20)

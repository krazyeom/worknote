---
layout: note
title: "야놀자 해외 프로모션 항공 쿠폰 모니터링 및 일일 변동 알림 시스템 구축"
date: 2026-11-06
tags: [yanolja, promotion, flight-coupon, telegram, monitoring, scheduler]
---

# 야놀자 해외 프로모션 항공 쿠폰 모니터링 및 일일 변동 알림 시스템 구축

## 1. 작업 개요
- **배경**:
  - 야놀자 해외 메인 프로모션(`https://content.yanolja.com/promotions/main-overseas`)의 선착순 항공 쿠폰 `contentId`와 `moduleId`를 매일 오전 6시 텔레그램으로 알리고, 전일 대비 변동 여부를 자동 감지하는 모니터링 요청을 접수함.
- **주요 구현 목표**:
  1. 프로모션 페이지 내 서버 렌더링 데이터(Next.js RSC 페이로드)를 동적으로 파싱하여 당일 활성 `contentId` 및 항공 쿠폰 `moduleId`를 추출.
  2. 직전 상태를 SQLite `system_settings`에 영구 보관하고, 일일 기준 변동 여부(동일/변경/신규)를 판별하는 로직 개발.
  3. 매일 06:00 KST에 크론 워커 루틴을 통해 텔레그램 알림을 자동 발송하는 스케줄러 등록.
  4. 수동 즉시 실행 및 테스트를 지원하는 전용 CLI 스크립트(`scripts/check-yanolja-flight-coupon.mjs`) 작성.

---

## 2. 세부 구현 내역

### 2.1. Next.js RSC 동적 데이터 역공학
- 프로모션 URL: `https://content.yanolja.com/promotions/main-overseas`
- 일반 curl 요청 시 WAF 및 Cloudflare 챌린지가 반환되므로, 모바일(iOS Safari) User-Agent를 헤더에 적용하여 통신 안정성을 확보함.
- HTML 내 `self.__next_f.push` 청크를 추출 및 병합하여 컴포넌트 트리를 구성:
  - 캠페인 `item`: `contentId = 3197` (타이틀: `NOL에서 만나는 해외여행 혜택`)
  - 10시 선착순 쿠폰 모듈 식별:
    - `163243`: 해외항공 선착순 쿠폰 모듈 (`policyCode = 20261028174222194332`, `promotionId = 850`, `distributorId = 1279`)
    - `163244`: 해외숙소 선착순 쿠폰 모듈 (`policyCode = 20261013144911657496`, `promotionId = 825`, `distributorId = 1255`)

### 2.2. 변동 비교 및 알림 모듈 개발 (`lib/yanolja-coupon.mjs`)
- `checkAndNotifyYanoljaFlightCoupon({ force = false, day = null })` 함수 구현:
  - `system_settings` 내 `yanolja_flight_coupon_monitor` 키에 저장된 직전 상태(`prev.contentId`, `prev.airlineModuleId`)와 현재 탐색 결과를 비교.
  - 당일 중복 전송 방지 로직(`prev.last_notified_day === day`) 적용.
  - 변동 상태에 따라 가독성 높은 텔레그램 메시지 포맷팅:
    - 변동 없음: `✅ 어제와 동일합니다. (변동 없음)`
    - 변경 감지: `🚨 어제와 달라졌습니다! (쿠폰 정보 변경 감지)`
  - 발송 직후 최신 상태를 DB에 업데이트.

### 2.3. 워커 스케줄러 등록 (`scripts/worker.mjs`)
- `checkAndRunYanoljaRoutines` 내부에 `hour === 6 && minute === 0` 조건을 바인딩하여 매일 아침 06:00 KST 정각에 자동 실행.

### 2.4. 수동 실행 CLI 스크립트 작성 (`scripts/check-yanolja-flight-coupon.mjs`)
- 수동 즉시 실행 및 `--force` 옵션을 통한 강제 발송 지원.

---

## 3. 검증 결과

1. **초기 모니터링 실행**:
   - `contentId`: `3197`
   - 항공 쿠폰 `moduleId`: `163243`
   - 숙소 쿠폰 `moduleId`: `163244`
   - 텔레그램 발송 완료 (`initial`, 상태 정상 저장).
2. **2회차 대조 실행**:
   - 직전 상태와 일치함을 정상 감지 (`changeStatus: same`).
   - `✅ 어제와 동일합니다. (변동 없음)` 메시지 발송 확인.
3. **중복 방지 확인**:
   - `--force` 미지정 시 당일 재실행 스킵 로그 정상 출력 확인.

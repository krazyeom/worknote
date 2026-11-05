---
layout: note
title: "롯데백화점 잠실점 매장 QR F&B 5천원 할인권 역공학 및 전 계정 일괄 발급"
date: 2026-11-05
tags: [lottedpt, coupon, qr-code, fnb, jamsil, automation, fastpass]
---

# 롯데백화점 잠실점 매장 QR F&B 5천원 할인권 역공학 및 전 계정 일괄 발급

## 1. 작업 개요
- **배경**:
  - `https://m.lotteshopping.com/qrcode/selectQr/QIM00000000000000749` 매장 QR 코드 기반의 잠실점 F&B 5,000원 할인 쿠폰을 전체 계정에 일회성으로 일괄 발급 요청 접수.
- **핵심 목표**:
  1. QR 엔드포인트의 리다이렉트 스크립트 및 쿠폰 게이트 식별자 구조 분석.
  2. 실제 발급 대상 쿠폰 번호(`CPM00000000000140625`), 행사 코드(`9220101664141`), 대상 지점(잠실점 `0002`) 도출.
  3. `lib/lottedpt-coupon.mjs` 내 스페셜 쿠폰북 등록 및 쿠폰함 조회 지점 파라미터 보강.
  4. 전 계정 일괄 발급 CLI 스크립트(`scripts/download-lottedpt-jamsil-fnb-5000.mjs`) 작성 및 실행.
  5. 활성 10대 계정(SW, SJ, 셜리, 도도1, 도도2, 찌은누나, DY, 지은맘, 봄곰, 찌은아빠) 전원에 대해 발급 성공 및 잠실점 쿠폰함 보유 검증.
  6. 격리 계정(`도도1`, `도도2`, `찌은누나`, `지은맘`, `봄곰`, `찌은아빠`)의 `skip_daily: 1` 설정은 그대로 유지하여 일일 상시 루틴 격리 유지.

---

## 2. 게이트 및 이벤트 구조 역공학

1. **QR 엔드포인트 분석**:
   - `/qrcode/selectQr/QIM00000000000000749` 호출 시 HTML 내 스크립트에서 `location.href`로 `intent://m.lotteshopping.com/cpn/gate/bfd509e052d27086/C10908` 리다이렉트를 수행.
2. **쿠폰 게이트 스크립트 해독**:
   - 게이트 HTML에서 `lddi.Gate.goApp('C00902', 'bfd509e052d27086', 'C10908')`를 호출.
   - `lddi.module.js` 역공학 분석을 통해 `C00902`가 `/cpn/cpnDetail?cpnInfoNo=`임을 확인하여 실제 상세 페이지 `/cpn/cpnDetail?cpnInfoNo=bfd509e052d27086`로 연결.
3. **쿠폰 사양 도출**:
   - **쿠폰 번호**: `CPM00000000000140625`
   - **행사 코드**: `9220101664141`
   - **혜택**: 백화점 잠실점 F&B 1만원 이상 구매 시 5,000원 즉시 할인 (10.29 ~ 11.18)
   - **대상 지점**: 잠실점 (`0002`)

---

## 3. 주요 구현 및 변경 내역

1. **`lib/lottedpt-coupon.mjs` 보강**:
   - `SPECIAL_COUPON_BOOKS`에 `jamsil_fnb_5000_2026` 항목 등록.
   - `getMyDownloadedCoupons(session, storeCode = '0001')`가 지점 코드를 전달받아 헤더의 `cstrCd`와 `selCstrCd`에 반영하도록 개선.
   - 쿠폰 파싱 시 `data-cpn-no` 속성을 함께 수집하도록 정규식 확장.
2. **`scripts/download-lottedpt-jamsil-fnb-5000.mjs` CLI 스크립트 작성**:
   - 세션 자동 검증/갱신 후 잠실점 쿠폰 발급 및 쿠폰함 검증까지 자동 일괄 수행.
3. **기술 가이드 문서 작성**:
   - `docs/lottedpt-jamsil-fnb-qr-coupon-guide.md` 신규 작성.

---

## 4. 검증 결과

등록된 롯데백화점 활성 10개 계정 전원에 대해 발급 성공 및 내 쿠폰함 보관을 확인했습니다.

| 계정 라벨 | 로그인 ID | 회원명 | 회원 등급 | 발급 결과 | 잠실점 쿠폰함 검증 | 자동화 정책 |
|---|---|---|---|---|---|---|
| **SW** | krazyeom | 염성욱 | AVENUEL PURPLE | 성공 (0000, OK) | 정상 보유 확인 | 상시 대상 |
| **SJ** | mikako13 | 박수지 | PRE-GREEN | 성공 (0000, OK) | 정상 보유 확인 | 상시 대상 |
| **셜리** | 10632kuk | 김진택 | AVENUEL ORANGE | 성공 (0000, OK) | 정상 보유 확인 | 상시 대상 |
| **도도1** | ogounii | 이현지 | AVENUEL ORANGE | 성공 (0000, OK) | 정상 보유 확인 | `skip_daily: 1` (격리 유지) |
| **도도2** | ogouniii | 이인희 | AVENUEL ORANGE | 성공 (0000, OK) | 정상 보유 확인 | `skip_daily: 1` (격리 유지) |
| **찌은누나** | zerocool-je | 박지은 | PRE-GREEN | 성공 (0000, OK) | 정상 보유 확인 | `skip_daily: 1` (격리 유지) |
| **DY** | dalkong0109 | 염다윤 | Members | 성공 (0000, OK) | 정상 보유 확인 | 상시 대상 |
| **지은맘** | lkh7270 | 이광희 | Members | 성공 (0000, OK) | 정상 보유 확인 | `skip_daily: 1` (격리 유지) |
| **봄곰** | whitebearsunny@hanmail.net | 이지선 | Members | 성공 (0000, OK) | 정상 보유 확인 | `skip_daily: 1` (격리 유지) |
| **찌은아빠** | pjl1206 | 박종락 | Members | 성공 (0000, OK) | 정상 보유 확인 | `skip_daily: 1` (격리 유지) |

---
layout: note
title: "야놀자 선착순 쿠폰 세션 만료 원인 규명 및 6시간 Keep-Alive·09:50 사전 진단 시스템 구축"
date: 2026-11-03
tags: [yanolja, attendance-check, session-management, keep-alive, aside, automation]
---

# 야놀자 선착순 쿠폰 세션 만료 원인 규명 및 6시간 Keep-Alive·09:50 사전 진단 시스템 구축

## 1. 작업 개요
- **배경**: 매일 오전 10시 정각 야놀자 선착순 항공권 쿠폰 100ms 정밀 스나이퍼 실행 시, `🔒 로그인 세션 만료 (HTTP 401, NOT_EXIST_MEMBER)`로 실패하는 현상 발생.
- **핵심 목표**: 세션 만료의 기술적 원인을 규명하고, 세션을 장기 유지(Keep-Alive)하는 자동화 파이프라인 및 선착순 10분 전(09:50) 사전 진단·자가치유(Pre-flight Self-Healing) 시스템을 구축.

---

## 2. 세션 만료 원인 분석
1. **야놀자 세션의 7일 수명 제한 (Server-side TTL Expiration)**:
   - 야놀자 세션 쿠키(`yanolja_sid`)는 클라이언트 브라우저 유효기간과 무관하게, 야놀자 서버 측 세션 저장소에서 활동 트래픽이 없거나 발급 후 약 7일이 경과하면 무효화 처리됩니다.
   - 기존 보관 세션의 추출 시점은 10월 27일 22:38 UTC로, 오늘(11월 3일) 기준 정확히 7일이 경과하여 자연 만료되었습니다.
2. **사전 진단 부재**:
   - 기존에는 10:00:00 스나이퍼 발사 순간(40회 버스트)에 비로소 만료를 확인했기 때문에, 사용자가 사전에 인지하고 재로그인할 시간적 여유가 없었습니다.

---

## 3. 주요 구현 및 수정 내역

1. **6시간 주기 Keep-Alive 하트비트 엔진 ([`lib/yanolja-coupon.mjs`](file:///home/krazyeom/dev/attendanceCheck/lib/yanolja-coupon.mjs))**:
   - `keepAliveYanoljaSessions()`를 구현하여 03:30, 09:30, 15:30, 21:30에 가벼운 혜택 조회 핑을 전송, 유휴 만료를 방지하고 세션 수명을 슬라이딩 연장.
   - 핑 실패 시 원격 맥북 Aside 실 브라우저(`syncYanoljaFromAside`)를 통한 자동 복구 시도.

2. **09:50 KST 선착순 10분 전 사전 세션 진단 및 자가치유 (Pre-flight Check)**:
   - 매일 오전 09:50에 등록 계정의 유효성을 전수 검사.
   - 세션 만료 시 1차로 맥북 Aside 브라우저에서 최신 쿠키를 자동 동기화.
   - 만약 브라우저도 미로그인 상태인 경우 09:50에 **텔레그램 긴급 알림 발송** 및 맥북 화면에 Aside 로그인 창(`openYanoljaLoginOnAside`)을 활성화하여 10분 동안 재로그인할 수 있도록 유도.

3. **관리자 UI 및 원클릭 Aside 연동 ([`app/admin/yanolja-coupon/page.js`](file:///home/krazyeom/dev/attendanceCheck/app/admin/yanolja-coupon/page.js), [`app/api/admin/yanolja-coupon/route.js`](file:///home/krazyeom/dev/attendanceCheck/app/api/admin/yanolja-coupon/route.js))**:
   - 상단 툴바에 `[🖥️ Aside 로그인창 열기]` 버튼 추가.
   - 계정 카드별 `[🔍 세션 검증]` 버튼 및 최근 검증 시각 표시.
   - `route.js`의 `action === 'sync_from_aside'`를 모듈화된 함수로 통합.

---

## 4. 검증 결과
1. **Keep-Alive 하트비트 단위 검증**:
   - `keepAliveYanoljaSessions()` 실행 시 만료 상태를 정확히 인지하고 Aside 자동 동기화로 이어지는 폴백 체인 검증 완료.
2. **프로덕션 빌드 및 배포**:
   - Next.js 16.4.3 프로덕션 빌드 완료 (`exit code 0`).
   - PM2 데몬(`attendance-check`, `attendance-check-worker`) 무중단 재기동 완료.

---

## 5. 보안 검증 (Security Zero-Leak)
* 세션 토큰 및 쿠키 문자열은 AES-256-GCM으로 암호화 보관되며 로그나 외부 통신에 노출되지 않도록 처리했습니다.

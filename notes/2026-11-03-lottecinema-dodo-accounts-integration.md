---
layout: note
title: "롯데시네마 무비싸다구 도도1, 도도2 (ogounii, ogouniii) 계정 등록 및 자동 응모 연동"
date: 2026-11-03
tags: [lottecinema, movie-ssadagu, dodo-accounts, lpoint-sso, sniper-automation]
---

# 롯데시네마 무비싸다구 도도1, 도도2 (ogounii, ogouniii) 계정 등록 및 자동 응모 연동

## 1. 작업 개요
- **배경**:
  - 롯데백화점에 등록한 신규 L.POINT 계정 `도도1`(`ogounii`)과 `도도2`(`ogouniii`)를 롯데시네마 무비싸다구 선착순 쿠폰 응모에도 참여하도록 추가 요청 접수.
- **주요 목표**:
  1. 도도1, 도도2 계정의 L.POINT 인증 및 롯데시네마 웹 SSO 세션 발급 검증.
  2. 롯데시네마 계정(`site='lottecinema'`)으로 DB 적재 및 고유 디바이스 UUID 매핑.
  3. 백그라운드 워커(`scripts/worker.mjs`) 무비싸다구 오픈 스케줄러 자동 편입.
  4. 프론트엔드 관리자 UI([`/lottecinema`](file:///home/krazyeom/dev/attendanceCheck/app/lottecinema/page.js)) 계정 표출 및 즉시 스나이핑 지원.

---

## 2. 인증 검증 및 DB 적재

1. **L.POINT SSO 및 롯데시네마 세션 발급 검증 ([`lib/lottecinema.mjs`](file:///home/krazyeom/dev/attendanceCheck/lib/lottecinema.mjs))**:
   - `ogounii` (도도1, 이현지님):
     - L.POINT 인증 성공 및 `MemberNoOn` 고유키 발급 완료.
   - `ogouniii` (도도2, 이인희님):
     - L.POINT 인증 성공 및 `MemberNoOn` 고유키 발급 완료.
2. **후보군 소스 확장 ([`app/api/app/route.js`](file:///home/krazyeom/dev/attendanceCheck/app/api/app/route.js))**:
   - `getLotteCinemaCandidates` 쿼리의 사이트 조건에 `lottedpt`를 추가하여 백화점 계정도 롯데시네마 연동 후보로 원활히 연계되도록 개선.
3. **`accounts` 테이블 등록**:
   - 도도1: ID #823 (`login_id: 'ogounii'`, `label: '도도1'`, `site: 'lottecinema'`, `enabled: 1`)
   - 도도2: ID #824 (`login_id: 'ogouniii'`, `label: '도도2'`, `site: 'lottecinema'`, `enabled: 1`)
   - 전체 롯데시네마 활성 계정 수: 기존 15개 → 총 17개로 확장.

---

## 3. 스나이퍼 파이프라인 자동 연동

1. **워커 자동 스케줄러 ([`scripts/worker.mjs`](file:///home/krazyeom/dev/attendanceCheck/scripts/worker.mjs))**:
   - 무비싸다구 오픈 감지 시 `SELECT * FROM accounts WHERE site='lottecinema' AND enabled=1`을 조회하므로, 별도 조작 없이 도도1, 도도2가 오픈 65초 전 사전 로그인 및 오픈 1초 전 버스트 스나이핑에 자동 참여.
2. **오늘 오픈 일정**:
   - 2026-11-03 16:00:00 (오후 4시): `수능, 출제의 비밀` 무비싸다구 오픈 대기열에 자동 포함.
3. **관리자 화면 ([`/lottecinema`](file:///home/krazyeom/dev/attendanceCheck/app/lottecinema/page.js))**:
   - 전 계정 목록에 도도1, 도도2 계정 카드 실시간 표출 및 개별 수동 호출 지원.

---

## 4. 빌드 및 배포
- Next.js 16.4.3 빌드 성공 (`npm run build`).
- PM2 프로세스 무중단 재기동 (`pm2 restart attendance-check attendance-check-worker`).
- 기술 가이드([`docs/lottecinema-technical-guide.md`](file:///home/krazyeom/dev/attendanceCheck/docs/lottecinema-technical-guide.md)) 및 작업 일지 반영 완료.

---
layout: note
title: "포켓CU 달콤연구소 하루 3번 (11시, 13시, 16시) 선착순 1,000명 쿠폰 정밀 스나이퍼 구축"
date: 2026-11-03
tags: [pocketcu, sweetbox, first-come, coupon-sniper, sso-handshake, burst, automation]
---

# 포켓CU 달콤연구소 하루 3번 (11시, 13시, 16시) 선착순 1,000명 쿠폰 정밀 스나이퍼 구축

## 1. 작업 개요
- **배경**:
  - `https://www.pocketcu.co.kr/deepLink/checkAppInstall?viewType=1&viewUrl=/event/eventView/9005261011617?utm_source=sweetbox&utm_medium=share`
  - 포켓CU 달콤연구소 프로모션(2026.11.01 ~ 2026.11.30)에서 매일 11시, 13시, 16시에 회차별 선착순 1,000명 쿠폰 발급 이벤트 진행.
  - 기존 14시 선착순 스나이퍼 구조를 계승하여 백그라운드 워커 자동 격발 및 관리자 수동 제어가 가능한 고신뢰성 스나이핑 파이프라인 구축 요청.
- **주요 목표**:
  1. 이벤트 페이지 및 API 역공학을 거쳐 회차별 파라미터(`step: 1, 2, 3`), 실시간 마감 플래그(`step: 0`) 규명.
  2. 웹뷰 SSO 핸드셰이크(`/login?referer_url=...` with Bearer Uniauth) 수립으로 세션 오류(`resp_cd: '09'/'93'`) 원천 차단.
  3. BGF WAF 차단 방지를 위한 계정별 프록시 노드 분리(`pickNextFarmNode`).
  4. T-1.5s 선제 타격 정밀 버스트 스케줄링 및 당첨/마감 감지 시 자동 조기 종료.
  5. 백그라운드 워커 자동 스케줄러(10:58, 12:58, 15:58) 및 텔레그램 실시간 알림 연동.
  6. 관리자 UI 제어 콘솔(회차 선택, 실시간 마감 조회 뱃지, 즉시 호출) 구축.

---

## 2. 이벤트 구조 및 API 역공학

1. **이벤트 프로필**:
   - 이벤트 코드: `evtCd: 9005261011617` (포켓CU 달콤연구소)
   - 기간: 2026년 11월 1일 ~ 2026년 11월 30일
2. **회차별 파라미터 매핑**:
   - `11:00:00 KST`: `step: 1` (오전 11시 선착순 1,000명)
   - `13:00:00 KST`: `step: 2` (오후 1시 선착순 1,000명)
   - `16:00:00 KST`: `step: 3` (오후 4시 선착순 1,000명)
   - `실시간 현황 조회`: `step: 0`
     - 반환 필드: `isFirstComeEvtEnd1`, `isFirstComeEvtEnd2`, `isFirstComeEvtEnd3` (마감 여부 불리언)
3. **응모 엔드포인트 및 응답 규격**:
   - `POST https://www.pocketcu.co.kr/event/applicationProc`
   - 페이로드: `evtCd=9005261011617&step=<1|2|3>&resultCheck=Y`
   - 주요 응답 코드:
     - `'00'`: 당첨 완료 (`rewardNm` 경품 명칭 포함)
     - `'27'`: 선착순 마감 (Sold out)
     - `'97'`: 금일 기참여 (Already participated today)
     - `'09'` / `'93'`: 로그인 필요 (세션 미바인딩)

---

## 3. 웹뷰 SSO 세션 연동 및 BGF WAF 방어

1. **웹뷰 SSO 바인딩 핸드셰이크 (`lib/pocketcu.mjs`)**:
   - 포켓CU 네이티브 로그인(`/api/v2/loginProc`)으로 획득한 `uniauth` 토큰만으로는 웹 컨트롤러의 이벤트 세션 컨텍스트가 형성되지 않음.
   - `GET https://www.pocketcu.co.kr/login?referer_url=/event/eventView/9005261011617` 호출 시 `Authorization: Bearer Uniauth <uniauth>` 헤더를 주입하여 유효한 `JSESSIONID`와 세션 쿠키를 바인딩.
2. **계정별 프록시 노드 격리 (`pickNextFarmNode`)**:
   - 여러 계정이 동일 IP에서 동시 호출할 경우 발생하는 BGF WAF 차단을 원천 방지하기 위해 계정마다 독립 송신 프록시 IP를 매핑.
3. **T-1.5s 선제 타격 및 버스트 오프셋**:
   - 타겟 시각 1.5초 전(`-1500ms`)부터 정각 직후까지 `[-1500, -1000, -500, 0, 300, 600, 1000, 1500, 2000, 2500]`ms 오프셋으로 초당 2~3회 연속 발사.
   - 당첨(`'00'`) 또는 마감(`'27'`) 확인 시 해당 계정의 후속 호출을 즉시 취소하여 불필요한 트래픽 절감.

---

## 4. 구현 세부 내역

1. **코어 모듈 ([`lib/pocketcu.mjs`](file:///home/krazyeom/dev/attendanceCheck/lib/pocketcu.mjs))**:
   - `DEFAULT_SWEETBOX_EVT_CD = '9005261011617'` 선언.
   - `checkPocketCuSweetboxStatus(account, evtCd)`: 실시간 마감 현황 조회 함수.
   - `snipePocketCuSweetboxEvent({ db, accounts, targetHour, step, isImmediate, targetEvtCd, progress })`: T-1.5s 정밀 스나이핑 엔진.
   - `important_prizes` 당첨 기록 적재 및 텔레그램 연동.
2. **백그라운드 워커 ([`scripts/worker.mjs`](file:///home/krazyeom/dev/attendanceCheck/scripts/worker.mjs))**:
   - `lastPocketCuSweetbox11Day`, `lastPocketCuSweetbox13Day`, `lastPocketCuSweetbox16Day` 일일 실행 가드 추가.
   - 10:58, 12:58, 15:58 사전 워밍업 및 정각 T-1.5s 자동 격발.
3. **관리자 라우트 및 UI 콘솔 ([`app/api/app/route.js`](file:///home/krazyeom/dev/attendanceCheck/app/api/app/route.js), [`app/admin/pocketcu/page.js`](file:///home/krazyeom/dev/attendanceCheck/app/admin/pocketcu/page.js))**:
   - API 액션 `checkPocketCuSweetboxStatus`, `snipePocketCuSweetbox` 등록.
   - 포켓CU 관리 화면에 달콤연구소 전용 카드 신설:
     - 11시/13시/16시 회차 탭 선택기.
     - 실시간 마감 현황(`isFirstComeEvtEnd1..3`) 조회 뱃지.
     - 단일/전체 계정 즉시 호출 테스트 버튼 및 결과 표 렌더링.

---

## 5. 검증 및 배포 결과
1. **API 및 세션 검증**:
   - 실시간 현황 조회(`step: 0`) 정상 응답 확인 (`11시 마감, 13시 마감, 16시 대기 중`).
   - 단일 계정 웹뷰 SSO 핸드셰이크 후 정상 세션 바인딩 확인.
2. **빌드 및 프로세스 재기동**:
   - Next.js 16.4.3 프로덕션 빌드 성공 (`npm run build`).
   - PM2 `attendance-check` 및 `attendance-check-worker` 무중단 재기동 완료.
   - 2026-11-03 16:00:00(오후 4시) 3회차 자동 스나이퍼 격발 대기 상태 확인.

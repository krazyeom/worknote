---
layout: note
title: "롯데백화점 선착순 쿠폰 부스터 미래 예약건 엄격 필터링 및 종료 쿠폰 자동 배제"
date: 2026-11-04
tags: [lottedpt, booster, coupon-reservation, filter, isClosed, daily-scan, automation]
---

# 롯데백화점 선착순 쿠폰 부스터 미래 예약건 엄격 필터링 및 종료 쿠폰 자동 배제

## 1. 작업 개요
- **배경**:
  - 11/3 일회성으로 종료된 롯데백화점 동탄점 무료 커피 이벤트(`CPM00000000000140886`)가 11/4 15:00에 부스터로 자동 재격발되어 텔레그램 알림 발송.
  - 사용자 피드백 접수: "매일 쿠폰이 나오는건 아냐. 쿠폰 목록을 확인하고 미래 예약건만 해야됨"
- **원인 분석**:
  1. 새벽 03:00 전 지점 탐색 루틴(`runLotteDeptAllStoresDailyScan`)이 지점 쿠폰 목록의 템플릿에 `data-dtdy-issue-st-tm`이 존재하면 마감 여부(`dimCode`, 본문 문구)를 검증하지 않고 당일(`open_date = day`) 15:00 예약으로 자동 등록하는 구조적 결함 확인.
  2. 100ms 간격 70회 버스트 중 롯데 쇼핑 서버가 고정 응답(`downloadCount: 3`)을 반복 반환하면서 `totalDownloaded`가 165건으로 중복 누적 집계되는 버그 확인.

---

## 2. 해결 및 구현 내역

1. **마감 / 발급 종료 상태 정밀 감지 엔진 ([`lib/lottedpt-coupon.mjs`](file:///home/krazyeom/dev/attendanceCheck/lib/lottedpt-coupon.mjs))**:
   - `data-dim-code="TODY_CLOS"` (금일 마감), `NOT_USE`, `EXPR`, `END` 감지
   - 본문 텍스트 내 `쿠폰 발급 종료`, `당일마감`, `선착순 마감`, `마감되었습니다` 감지
   - 버튼 `disabled="disabled"` 비활성화 상태 판별
   - 위 조건 중 하나라도 해당하면 `isClosed: true`로 마킹하여 새벽 탐색 및 부스터 예약 등록에서 원천 배제.
2. **미래 오픈 스케줄 검증 ([`runLotteDeptAllStoresDailyScan`](file:///home/krazyeom/dev/attendanceCheck/lib/lottedpt-coupon.mjs))**:
   - 시작일(`startDate`)이 오늘보다 미래인 경우에만 해당 미래 날짜로 예약 등록.
   - 당일 쿠폰인 경우 현재 시각보다 늦은 미래 시각(`openTime > curTime`)이어야 하며, `!isClosed`인 정상 대기 건만 예약 테이블(`lottedpt_coupon_reservations`)에 적재.
3. **부스터 가동 전 실시간 상태 사전 검증 ([`executeLotteDeptReservationBooster`](file:///home/krazyeom/dev/attendanceCheck/lib/lottedpt-coupon.mjs))**:
   - 워커가 부스터를 가동하기 직전 쿠폰 상세를 1회 실시간 조회하여 이미 마감된 경우 부스터 호출을 건너뛰고 상태를 완료 처리.
4. **버스트 응답 중복 카운트 방지**:
   - 100ms 초당 10회 버스트 중 동일 계정에 대해 중복 반환된 `downloadCount`를 누적하지 않고, 계정별 획득 수량의 최댓값만 온전히 집계하여 실제 수령 건수를 정확히 보고하도록 교정.
5. **DB 정리**:
   - `lottedpt_coupon_reservations` 테이블에서 오등록된 마감 쿠폰 데이터 정리 완료.

---

## 3. 검증 결과
- 28개 전 지점 대상 전체 탐색 재실행 검증 완료:
  - 마감된 동탄점 커피 및 다이슨 쿠폰이 정상적으로 `isClosed: true`로 감지되어 신규 예약 건수 0건으로 건너뜀 확인.
- Next.js 16.4.3 프로덕션 빌드 통과 및 PM2 서비스(`attendance-check`, `attendance-check-worker`) 무중단 재기동 완료.

---
layout: note
title: "롯데백화점 동탄점 11/3 뷰티 무료샘플링 13종 게이트 분석 및 12:00 정각 전 계정 자동 발급 시스템 구축"
date: 2026-11-03
tags: [lottedpt, coupon, dongtan, beauty-sampling, burst-scheduler, automation]
---

# 롯데백화점 동탄점 11/3 뷰티 무료샘플링 13종 게이트 분석 및 12:00 정각 전 계정 자동 발급 시스템 구축

## 1. 작업 개요
- **배경**: 롯데백화점 동탄점 전용 `11/3 단하루 뷰티 무료샘플링` 이벤트 게이트 URL(`https://m.lotteshopping.com/cpn/gate/CPM00000000000140651/lms`) 접수.
- **핵심 목표**:
  1. 게이트 웹뷰 및 백엔드 파라미터를 역공학 분석하여 오픈 시각, 지점 코드, 13개 참여 브랜드의 행사코드(`evntCd`)를 규명.
  2. 등록된 롯데백화점 전 계정의 세션 유효성을 사전 갱신하고, **오픈 시각인 12:00:00 KST 정각**에 자동으로 13종 전량을 일괄 수령하는 예약 스케줄러와 단독 CLI 스크립트 구축.

---

## 2. 게이트 역공학 및 기술 분석

1. **이벤트 속성 규명**:
   - 게이트 마스터 번호: `CPM00000000000140651`
   - 지점: 동탄점 (`cstrCd: 0399`)
   - 오픈 시각: **2026년 11월 3일 낮 12:00:00 KST** (`data-prst-prd-st-dtm="20261103120000"`)
2. **사전 발급 API 응답 특성**:
   - 오픈 시각(12:00:00) 이전에 `POST /cpn/cpnDwldAjax` 호출 시 서버는 `resultCode: "0000"`을 반환하지만 본문 데이터는 `totalCount: 13, downloadCount: 0`으로 실제 티켓 발급이 이루어지지 않음.
   - 따라서 `downloadCount > 0`을 기준으로 실 발급 성공을 확정하도록 방어 로직을 구현.
3. **13개 브랜드 샘플 및 전용 행사코드(`evntCd`) 전수 매핑**:
   - 헤라 15ml (100명): `CEC0000200216`
   - 딥티크 10ml (50명): `CEC0000200217`
   - 베르사체 1ml (100명): `CEC0000200218`
   - 로마 15ml (50명): `CEC0000200219`
   - 설화수 5ml (100명): `CEC0000200220`
   - 조말론런던 1.5ml (50명): `CEC0000200241`
   - 로라메르시에 5ml (50명): `CEC0000200242`
   - 라로제 페이스세럼 (30명): `CEC0000200243`
   - 숨 5ml (50명): `CEC0000200244`
   - 빌리프 12ml (50명): `CEC0000200245`
   - 오휘/후 3ml (100명): `CEC0000200246`
   - 시슬리 3종 (30명): `CEC0000200247`
   - 끌레드뽀보떼 0.3ml (30명): `CEC0000200254`

---

## 3. 주요 구현 및 개선 내역

1. **스페셜 쿠폰북 등록 및 발급 엔진 고도화 ([`lib/lottedpt-coupon.mjs`](file:///home/krazyeom/dev/attendanceCheck/lib/lottedpt-coupon.mjs))**:
   - `SPECIAL_COUPON_BOOKS`에 `dongtan_beauty_1103` 프리셋을 추가하고 지점코드(`0399`) 헤더 연동을 보장.
   - `downloadLotteDeptDongtanBeautyCoupons({ testMode })`를 구현하여 일괄 다운로드(`allDownYn='Y'`)와 13종 개별 단건 다운로드를 연계한 2중 안전망을 확립.
   - `DB_PATH` 상대 경로 참조 버그를 `import.meta.url` 기반 절대 경로로 수정하여 독립 스크립트 실행 시의 무결성 확보.

2. **12:00:00 정각 버스트 스케줄러 연동**:
   - 백그라운드 워커(`checkAndRunLotteDeptRoutines`)에 11:59:59 T-1s 사전 슬립 및 12:00:00 정각 버스트 발급을 연동. 12:00부터 12:05까지 매분 미발급분에 대해 자동 재시도.

3. **단독 CLI 스크립트 및 관리자 API 구축**:
   - 12시 이후 즉시 수동 실행할 수 있는 [`scripts/download-lottedpt-dongtan-beauty.mjs`](file:///home/krazyeom/dev/attendanceCheck/scripts/download-lottedpt-dongtan-beauty.mjs) 작성.
   - 관리자 API 라우트([`app/api/admin/lottedpt-coupon/route.js`](file:///home/krazyeom/dev/attendanceCheck/app/api/admin/lottedpt-coupon/route.js))에 `action === 'download_dongtan_beauty'` 엔드포인트 연동.

---

## 4. 검증 결과

1. **계정 세션 갱신 검증**:
   - 3개 롯데백화점 계정(염성욱 `420`, 박수지 `421`, 김진택 `422`) 세션 사전 갱신 성공 (`resultCode: 1400`, `tknVal` 신규 수령).
2. **사전 발급 파이프라인 시뮬레이션**:
   - 13개 항목 모두 12:00 오픈 대기 상태(`12:00 오픈 대기`)로 정상 식별됨을 확인.
3. **프로덕션 빌드 및 배포**:
   - Next.js 16.4.3 프로덕션 빌드 통과 (`exit code 0`).
   - PM2 데몬(`attendance-check`, `attendance-check-worker`) 정상 가동 유지.

---

## 5. 보안 검증 (Security Zero-Leak)
- L.POINT 및 롯데백화점 토큰(`acesTkn`, `rnwTkn`, `JSESSIONID`)은 로컬 SQLite DB에 암호화 보관되며 로그나 외부 통신에 노출되지 않도록 처리했습니다.

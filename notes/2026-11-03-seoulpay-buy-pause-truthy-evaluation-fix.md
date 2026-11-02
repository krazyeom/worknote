---
layout: note
title: "서울사랑상품권 수동 구매 시간대 truthy 평가 오류 긴급 조치 및 즉시 구매 복구"
date: 2026-11-03
tags: [seoulpay, attendance-check, bugfix, javascript, truthy-evaluation]
---

# 서울사랑상품권 수동 구매 시간대 truthy 평가 오류 긴급 조치 및 즉시 구매 복구

## 1. 작업 개요
- **배경**: 새벽 시간대(KST 03:48)에 사용자가 박수지 계정으로 서울사랑상품권 즉시 구매를 시도할 때, "선택하신 [박수지]은 현재 구매 일시중지 시간대(07:00~09:00)입니다." 안내와 함께 결제가 차단되는 현상 발생.
- **핵심 목표**: 시간대 판별 함수의 객체 반환값과 조건식 불리언 평가 불일치를 교정하여 07:00~09:00 외 정상 시간대에서 박수지 계정의 즉시 구매가 즉시 실행되도록 복구.

---

## 2. 주요 구현 및 수정 내역

1. **원인 규명 및 진단**:
   - `lib/seoulpay.mjs`의 `isSeoulPayAccountTimeRestricted(account)` 함수는 불리언이 아닌 객체 `{ restricted: false, reason: '', ... }`를 반환.
   - 백엔드 라우트([`app/api/admin/seoulpay/route.js`](file:///home/krazyeom/dev/attendanceCheck/app/api/admin/seoulpay/route.js))에서 `if (isSeoulPayAccountTimeRestricted(specificAcc))` 형태로 객체 자체를 조건문에 직접 대입.
   - 자바스크립트 언어 특성상 `{ restricted: false }` 객체는 `Boolean()` 평가 시 항상 `true`(truthy)로 취급되므로, 새벽 03시 등 중지 시간대가 아님에도 무조건 중지 시간대로 판정되어 결제가 차단됨.
2. **조건식 교정 ([`app/api/admin/seoulpay/route.js`](file:///home/krazyeom/dev/attendanceCheck/app/api/admin/seoulpay/route.js))**:
   - `const timeCheck = isSeoulPayAccountTimeRestricted(specificAcc); if (timeCheck.restricted)` 구조로 변경하여 `restricted` 불리언 프로퍼티를 명시적으로 검사하도록 수정.
   - 에러 메시지도 하드코딩 폴백 대신 `timeCheck.reason`이 우선 노출되도록 개선.
3. **기술문서 및 아키텍처 가이드 반영 ([`docs/seoulpay-technical-guide.md`](file:///home/krazyeom/dev/attendanceCheck/docs/seoulpay-technical-guide.md))**:
   - 섹션 8.5에 `isSeoulPayAccountTimeRestricted` 반환 객체의 truthy 평가 방지 지침 및 불리언 프로퍼티 검사 주의사항 명시.

---

## 3. 검증 결과

1. **시간대 판별 엔진 단위 검증 (KST 03:49 기준)**:
   - `isSeoulPayAccountTimeRestricted(acc)` 호출 결과: `restricted: false`, `currentHour: 3`, `currentMinute: 49`
   - `timeCheck.restricted`가 정확히 `false`로 산출되어 구매 허용 판정 정상 작동 확인.
2. **프로덕션 빌드 및 서비스 헬스체크**:
   - Next.js 16.4.3 빌드 성공 (`exit code 0`).
   - PM2 데몬(`attendance-check`, `attendance-check-worker`) 무중단 재기동 완료.

---

## 4. 보안 검증 (Security Zero-Leak)
* 카드 번호, 인증 세션 토큰, 개인 식별 정보(PII)는 일체 노출하지 않고 마스킹 처리함.

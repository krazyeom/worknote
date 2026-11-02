---
layout: note
title: "서울사랑상품권 계정별 잔여 구매한도 기반 4단계 우선순위 정렬 시스템 구축"
date: 2026-11-03
tags: [seoulpay, attendance-check, sorting, multi-account, quota]
---

# 서울사랑상품권 계정별 잔여 구매한도 기반 4단계 우선순위 정렬 시스템 구축

## 1. 작업 개요
- **배경**: 서울Pay+ 관리자 화면에서 상품권 목록이 단순 카테고리(자치구 $\rightarrow$ 광역 $\rightarrow$ 땡겨요) 순서로만 정렬되어, 등록된 사용자(염성욱, 박수지)의 개인 한도가 모두 소진된 상품권이 한도가 남아 있는 상품권보다 위에 노출되는 불편이 있었습니다.
- **핵심 목표**: 지자체 발행 잔여금액(`pubRemainAmt`)뿐 아니라 두 사용자 각각의 월간 잔여 한도(`purchasableAmt`)를 종합 평가하여, 실제로 즉시 구매 가능한 상품권을 최상단으로 우선 배치하는 4계층 정렬 파이프라인을 구축했습니다.

---

## 2. 주요 구현 및 수정 내역

1. **4계층 정렬 등급(Tier) 모델 설계**:
   - **Tier 3 (최우선)**: 등록된 두 계정 모두 잔여 한도가 남아 있는 상품권 (`purchasableAmt > 0` 2명)
   - **Tier 2 (2순위)**: 한 명이라도 잔여 한도가 남아 있어 즉시 결제 가능한 상품권 (`purchasableAmt > 0` 1명 이상)
   - **Tier 1 (3순위)**: 지자체 잔여 예산은 있으나 두 사용자 모두 월 한도를 채운 상품권 (`pubRemainAmt > 0`, 한도 0원)
   - **Tier 0 (최하단)**: 지자체 예산 소진 또는 판매 마감 (`pubRemainAmt == 0`)

2. **백엔드 정렬 엔진 구현 ([`lib/seoulpay.mjs`](file:///home/krazyeom/dev/attendanceCheck/lib/seoulpay.mjs))**:
   - `fetchSeoulPayCertificates` 함수 내 `getItemSortScore`를 추가.
   - 1차: 정렬 등급(Tier 3 > 2 > 1 > 0)
   - 2차: 등록 계정 중 실질 구매 가능 최고 한도(`effectiveAmt`) 내림차순
   - 3차: 지자체 총 발행 잔여금액(`pubRemainAmt`) 내림차순
   - 4차: 카테고리 순서 (자치구 $\rightarrow$ 광역 $\rightarrow$ 땡겨요 $\rightarrow$ 기타)
   - 5차: 상품권 명칭 가나다순

3. **프론트엔드 대시보드 연동 ([`app/admin/seoulpay/page.js`](file:///home/krazyeom/dev/attendanceCheck/app/admin/seoulpay/page.js))**:
   - `isItemPurchasableByAny(item)` 함수를 추가하여 상단 `내 구매가능` 뱃지 카운트 및 필터 탭이 염성욱, 박수지 두 사람 중 누구라도 한도가 남아 있으면 카운트하도록 개선.
   - `filteredItems`에 동일한 4계층 정렬 로직을 적용하여 검색 및 필터 전환 시에도 일관된 우선순위를 유지하도록 보장.

4. **기술 문서화 ([`docs/seoulpay-technical-guide.md`](file:///home/krazyeom/dev/attendanceCheck/docs/seoulpay-technical-guide.md), [`docs/DAILY_WORK_LOG.md`](file:///home/krazyeom/dev/attendanceCheck/docs/DAILY_WORK_LOG.md))**:
   - 기술 가이드 문서 섹션 19에 다중 계정 구매 가능 잔여한도 기준 우선순위 정렬 알고리즘 명세 추가.
   - 일일 개발 일지에 작업 내역 상세 기록.

---

## 3. 검증 결과

1. **실데이터 정렬 순서 검증**:
   - 종로사랑상품권 (발행잔액 80,000원 | 염성욱: 30,000원, 박수지: 70,000원) $\rightarrow$ **1순위 (Tier 3)**
   - 양천사랑상품권 (발행잔액 50,000원 | 염성욱: 50,000원, 박수지: 50,000원) $\rightarrow$ **2순위 (Tier 3)**
   - 강동땡겨요상품권 (발행잔액 18억여 원 | 염성욱: 0원, 박수지: 200,000원) $\rightarrow$ **3순위 (Tier 2)**
   - 성북사랑상품권 (발행잔액 1,485,000원 | 염성욱: 0원, 박수지: 0원) $\rightarrow$ **한도 소진 상품권으로 Tier 1 하단 배치**
2. **프로덕션 빌드 및 무중단 배포**:
   - `npm run build` 정상 완료 (`exit code 0`).
   - PM2 데몬(`attendance-check`, `attendance-check-worker`) 재기동 완료.

---

## 4. 보안 검증 (Security Zero-Leak)
* 사용자 계정의 식별 토큰이나 비밀번호 등 민감 데이터는 로그나 저장소에 노출되지 않도록 처리했습니다.

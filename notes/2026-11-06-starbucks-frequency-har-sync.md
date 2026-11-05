---
layout: note
title: "스타벅스 프리퀀시 11/6 HAR 데이터 지역별·날짜별 실측 정보 전면 동기화"
date: 2026-11-06
tags: [starbucks, frequency, har-sync, inventory, snapshots, areas, dates]
---

# 스타벅스 프리퀀시 11/6 HAR 데이터 지역별·날짜별 실측 정보 전면 동기화

## 1. 작업 개요
- **배경**:
  - `sp.istarbucks.co.kr_11-06-2026-07-36-51.har` 캡처 파일에 기록된 스타벅스 e-프리퀀시 2026 Winter 증정품의 지역별, 날짜별, 매장별 재고 실측 정보와 최신 세션을 현재 시간 기준으로 전면 업데이트 요청 접수.
- **주요 목표**:
  1. 최신 HAR 파일(`1793918220337_sp_istarbucks_co_kr_11-06-2026-07-36-51.har`)의 454개 네트워크 트랜잭션 전수 분석.
  2. 전국 201개 행정구역(`storeAreaList`) 및 최신 수령 예약 일자(`recvDateList`: 20261113 등) 전용 테이블 신설 및 색인.
  3. 지점별 실시간 수량 스냅샷(`starbucks_frequency_snapshots`) 및 상품 목록 최신화.
  4. 세션 토큰(`JSESSIONID`)을 11/6 최신 세션값으로 자동 갱신.

---

## 2. 세부 구현 내역

### 2.1. 테이블 스키마 확장 (`lib/starbucks-frequency.mjs`)
- `starbucks_frequency_areas`: 전국 시도 및 구군 지역 목록 영구 보관 (`sido_cd`, `sido_nm`, `gugun_cd`, `gugun_nm`, `updated_at`).
- `starbucks_frequency_dates`: 품목별 수령 가능 일자 목록 영구 보관 (`promo_seq`, `sku`, `recv_date`, `updated_at`).

### 2.2. 시딩 파이프라인 고도화 (`seedHarSnapshots`)
- `storeAreaList` 응답 파싱: 전국 17개 시도 및 201개 구군 데이터 추출 및 DB 적재 (총 1,206건).
- `recvDateList` 응답 파싱: 최신 수령 날짜 `20261113`을 포함한 462건의 날짜 매핑 적재.
- `recvStoreList` 응답 파싱: 죽전, 정자 및 전국 매장 실측 재고 788건 스냅샷을 현재 시점 타임스탬프로 전면 갱신.
- 최신 세션 가중치 적용: 11/6 파일에 포함된 최신 `JSESSIONID`(`2GMaFJ3YnonAGOoh0DmbcO8AO4Gpbw4j9gCHYlxOeaXVr1KVT7A9cO3JYHymr2LX.bXNyX2RvbWFpbi9wYXBheWEwNg==`)를 환경설정에 우선 바인딩.

### 2.3. 관리자 API 연동 (`app/api/admin/starbucks-frequency/route.js`)
- `getFrequencyAreas()` 함수를 연동하여 프론트엔드에서 지역별 필터링이 가능하도록 응답 페이로드에 `areas` 필드 추가.

---

## 3. 검증 결과
- **상품 동기화**: 704건
- **매장 재고 스냅샷**: 788건 (전국 69개 주요 지점)
- **전국 행정구역**: 201개 구군 등록 완료
- **수령 예약 일자**: 최신 `20261113` 포함 462건 등록 완료
- **예약 내역**: 13건
- **현재 시점 갱신 확인**: `recentSearchTime` 정상 타임스탬프 갱신 확인 완료.

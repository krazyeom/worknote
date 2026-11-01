# 2026-11-02 작업 노트: 현대Hi SPECIAL 룰렛 이벤트 추가 및 롯데시네마 무비싸다구 계정 복원

## 1. 작업 개요
* **프로젝트**: `attendanceCheck` (출석체크 자동화 시스템)
* **일자**: 2026-11-02
* **핵심 작업**:
  1. 현대Hi(더현대) 신규 진행 이벤트인 **SPECIAL 룰렛 (`00011015`)** 자동 참여 파이프라인 구축 및 출석체크(`00011031`)와의 듀얼 실행 연동.
  2. 롯데시네마 무비싸다구(`lottecinema`) 15개 계정 백업 복원 및 관리자 권한 통합 실행 파이프라인 검증.
  3. 도메인 변경(`ci.krazyeom.com` $\rightarrow$ `checkin.krazyeom.com`)에 따른 카카오 OAuth Redirect URI 및 PM2 런타임 환경변수 동기화.
  4. 롯데홈쇼핑(`lotteimall`) 정기 시스템 점검 안내 감지 및 사전 인증 토큰 발급 예외 처리 개선.

---

## 2. 주요 구현 및 변경 내역

### A. 현대Hi SPECIAL 룰렛 이벤트 (`00011015`) 연동
* **파일**: `lib/the-hyundai.mjs`, `lib/sites.mjs`, `docs/the-hyundai-technical-guide.md`
* **이벤트 정보**:
  - 이벤트 번호: `00011015`
  - 이벤트 명칭: `[11.2~15] SPECIAL 룰렛 이벤트` (1일 1회 참여, 100% 당첨)
  - 제공 경품: H.Point (10P, 100P, 500P, 1,000P), 투썸플레이스 아메리카노, BBQ 치킨, 도미노피자, 15% 및 3% 할인쿠폰 등
* **구현 세부사항**:
  1. `DEFAULT_ROULETTE_EVENT_NO = '00011015'` 상수 정의.
  2. `discoverEvents`: `evntMainList` API 응답에서 룰렛 키워드 또는 기본 룰렛 이벤트 번호(`00011015`)를 동적 탐색하여 `{ attendance, roulette }` 객체 동시 반환.
  3. `runTheHyundai`: 
     - 1단계 출석체크(`00011031`) 실행 후 세션 만료 시 1회 자동 재로그인.
     - 2단계 SPECIAL 룰렛(`00011015`) 순차 실행.
     - 결과 합성: `출석체크: [결과] · 룰렛: [당첨 결과/이미 참여 완료]`.
  4. 사이트 메타데이터(`lib/sites.mjs`): `eventName`을 `'매일 출석체크 & 룰렛'`으로 갱신.

### B. 롯데시네마 무비싸다구 (`lottecinema`) 계정 복원
* **파일**: `data/attendance.sqlite`
* **복원 계정**: 백업(`attendance_2026-11-01_043000_daily_auto.sqlite.gz`)에서 누락되었던 9개 계정 추출 및 전체 15개 계정 활성화(`enabled = 1`).
* **실행 권한 연동**: 관리자(`role: admin`) 권한으로 `/lottecinema` 전용 페이지 및 백그라운드 워커(`worker.mjs`의 `triggerCinemaSniper`)에서 15개 계정 일괄 사전 로그인 및 선착순 버스트 스나이핑 가능하도록 수립.

### C. 롯데홈쇼핑 (`lotteimall`) 시스템 점검 감지 및 예외 처리
* **파일**: `lib/lotteimall.mjs`, `docs/lotteimall-technical-guide.md`
* **문제 상황**: 롯데홈쇼핑 정기 시스템 점검(11.1 23:40 ~ 11.2 07:15) 중 `preAuthValidation.lotte` 요청 시 HTTP 404와 점검 HTML이 수신되어 모호한 에러(`사전 인증 토큰(LOGIN_TKN) 발급에 실패했습니다`)가 출력되는 현상 발생.
* **조치 사항**:
  - 응답 본문 내 `서비스 점검`, `error_notice service` 키워드 및 점검 시간 정규식 검사 로직 추가.
  - 점검 감지 시 `"롯데홈쇼핑 서비스 점검 중입니다. ({점검 시간})"` 메시지를 명확히 반환하도록 예외 처리.
  - 기술 가이드 문서(`docs/lotteimall-technical-guide.md`)에 점검 대응 프로토콜 반영.

### D. 신세계백화점 (`shinsegaedept`) 11월 제휴 하나카드 출석 챌린지 연동
* **파일**: `lib/shinsegaedept.mjs`, `docs/shinsegae-card-attendance-technical-guide.md`
* **배경**: 10월 리워드 캘린더 종료로 중단 가드가 걸려 있던 상황에서, 11월 제휴 하나카드 출석 챌린지(`3762816184550044722`, 11/2 ~ 11/15) 단독 오픈.
* **조치 사항**:
  - `SHINSEGAE_CARD_EVENTS`에 11월 하나카드 매핑 등록 (이벤트 코드: `3762816184550044722`, 내부 경로: `EVT_DAILY_HANA_202611`, 기간: `2026-11-02` ~ `2026-11-15`).
  - 일반 리워드 캘린더 미오픈 상태에서도 오류 없이 제휴 카드 출석이 단독 진행되도록 예외 격리 로직 적용.
  - `site_settings`의 `circuit_status` 및 `status`를 `active`/`dev`로 재가동하고 전체 23개 계정 일괄 응모 검증.

---

## 3. 검증 결과

1. **현대Hi 단일 계정 및 다중 계정 듀얼 실행 실측**:
   - 이벤트 탐색 대상 확장: `rllnList` 및 `evntContentList` 전체 배열 병합 탐색으로 배너 변동 시에도 룰렛/출석체크 자동 인식 보장.
   - 계정 15 (`dalkong19`): `출석체크: 이미 참여 완료 · 룰렛: 이미 참여 완료`
   - 계정 16 (`krazyeom`): `출석체크: 이미 참여 완료 · 룰렛: 이미 참여 완료`
   - 계정 17 (`mikako13`): `출석체크: 이미 참여 완료 · 룰렛: 이미 참여 완료`
   - 매일 스케줄러(`worker.mjs`) 및 수동 실행 시 출석체크(`00011031`)와 SPECIAL 룰렛(`00011015`)이 1회 호출로 모두 동시 응모되도록 연동 완료.
2. **서비스 재가동 및 헬스체크**:
   - `attendance-check` (id 16): `online`
   - `attendance-check-worker` (id 17): `online`
   - DB 무결성: `PRAGMA integrity_check` $\rightarrow$ `ok`

---

## 4. 보안 검증 (Security Zero-Leak)
* 비밀번호, 암호화 비밀키, 카카오 REST API 시크릿, 개인 JWT 토큰을 기록하지 않음.
* 개인 식별 정보(PII)는 마스킹 처리 및 표준 심볼로 기술함.

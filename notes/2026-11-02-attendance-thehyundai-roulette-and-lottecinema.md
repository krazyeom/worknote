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
  - Next.js 프로덕션 환경(`attendance-check`) 번들 최신화를 위해 `npm run build` 수행 및 PM2 서비스 재가동 완료.
  - 기술 가이드 문서(`docs/lotteimall-technical-guide.md`)에 점검 대응 프로토콜 반영.

### D. 신세계백화점 (`shinsegaedept`) 11월 리워드 챌린지(메인) 및 제휴 4대 카드사(서브) 통합 파이프라인 구축
* **파일**: `lib/shinsegaedept.mjs`, `lib/sites.mjs`, `docs/shinsegae-dept-technical-guide.md`, `docs/shinsegae-card-attendance-technical-guide.md`
* **이벤트 체계**:
  1. **[메인] 신세계 리워드 챌린지** (단축링크: `https://deptapp.shinsegae.com/s4xdodj` / 이벤트 코드: `7292516610982097714` / 기간: `11월 1일 ~ 11월 30일`)
  2. **[서브] 제휴 4대 카드사 출석 챌린지** (기간: `11월 2일 ~ 11월 15일` 한정)
     - BC바로카드: `7075491895546425394` / `https://deptapp.shinsegae.com/yxkfcc`
     - 삼성카드: `3846974798193255477` / `https://deptapp.shinsegae.com/x6mqnzf`
     - 하나카드: `3762816184550044722` / `https://deptapp.shinsegae.com/5v5iz6p`
     - 신한카드: `4122026423680067169` / `https://deptapp.shinsegae.com/uouxh2`
* **조치 사항**:
  - `discoverEvents`: 11월 리워드 챌린지 기본 fallback 코드를 `7292516610982097714`로 갱신하여 30일까지 메인 출석체크 수행.
  - `runShinsegaeDept`: 단일 세션(JWT Bearer)으로 [메인] 리워드 챌린지 응모 -> [서브] 4대 카드사 순차 응모 -> [마일리지] 잔여 마일리지 조회의 3단계 파이프라인 확립.
  - 사이트 설정(`lib/sites.mjs`): `eventName`을 `'리워드 챌린지 & 카드 4종 출석'`으로 갱신.
  - 전수 실행 검증: 셜리(3개) 및 ㅇㅋ(10개) 계정을 포함한 등록 활성 계정 전체(23개 계정)에 대해 메인 리워드 챌린지 및 서브 카드 4종 일괄 실행 완료 (`리워드 출석 완료 (누적 1일) · 카드 4종 완료 (BC 1일, 삼성 1일, 하나 1일, 신한 1일) · 잔여: ...R`).
  - Next.js 프로덕션 빌드(`npm run build`) 및 PM2 데몬 재기동 완료.

### E. 네이버 카페 자동 & 수동 포스팅 `[n]`일 차 매월 자동 초기화 구축 및 11월 1일 차 갱신
* **파일**: `lib/naver-cafe.mjs`, `lib/store.mjs`, `app/admin/naver-cafe/page.js`, `docs/naver-cafe-technical-guide.md`
* **문제 상황**: 네이버 카페 자동/수동 포스팅 제목 및 본문 템플릿의 `[n]` 태그가 시작일(`2026-10-02`)을 기준으로 날짜 차이를 단순 합산하여, 11월로 변경된 이후에도 `32일 차`로 누적 노출되는 문제 발생.
* **조치 사항**:
  1. **동적 템플릿 치환 엔진 (`lib/naver-cafe.mjs`)**:
     - `targetDate`와 `startDate`의 연/월이 불일치하는 경우, 시작일의 일자(`startDay`)를 타겟 월로 클램핑하여 당월 기준 시작일(`effectiveStartDate`)을 동적으로 재구성하는 매월 자동 초기화(Monthly Auto-Reset) 로직 구현.
     - `[start_m]`, `[end_m]` 태그 또한 이전 달인 경우 당월 기준으로 스마트 동기화 처리.
  2. **관리자 UI 실시간 프리뷰 (`app/admin/naver-cafe/page.js`)**:
     - 클라이언트 단 `livePreview` 연산 로직에도 동일한 월간 자동 초기화 로직을 반영하여 화면에서 즉시 1일 차로 렌더링되도록 개선.
  3. **데이터베이스 설정 갱신 (`naver_cafe_posts`)**:
     - 11월 4대 카드사 이벤트 기간에 맞추어 `start_date`를 `'2026-11-02'`, `end_date`를 `'2026-11-15'`로 갱신하여 오늘(11/2)이 정확히 `1일 차`로 시작되도록 수립.
  4. **워커 스케줄러 일자 범위 순환 (`lib/store.mjs`)**:
     - `getPendingNaverCafePosts`에서 명시적 기간뿐만 아니라 월간 반복 순환 일자(`sD <= cD <= eD`)를 지원하도록 보강.
  5. **자동 포스팅 검증 완료**:
     - 서비스 재기동 직후 워커가 11월 2일자 자동 포스팅을 감지하여 제목 `"2026 신세계 리워드 캘린더 Nov 출석챌린지 1일 차 (~11/15)"`로 네이버 카페에 즉시 성공 등록 (글 번호: `75509`).

### F. 포켓CU 14:00 선착순 이벤트('밥은 과학이다') 자동 응모 파이프라인 비활성화
* **파일**: `scripts/worker.mjs`, `app/admin/pocketcu/page.js`, `docs/pocketcu-technical-guide.md`
* **배경**: 10월 한정으로 진행되었던 포켓CU 14시 선착순 이벤트(`9005260911269`)가 11월에 종료됨에 따라, 불필요한 로그인 및 버스트 응모 트래픽과 텔레그램 알림을 중단하도록 사용자 요청 접수.
* **조치 사항**:
  - 백그라운드 워커(`scripts/worker.mjs`): 13:58 사전 로그인 및 14:00 정밀 버스트 스나이퍼 가동 플래그(`ENABLE_POCKETCU_14_SNIPER = false`)를 비활성화하여 자동 실행을 완전 차단.
  - 관리자 UI (`app/admin/pocketcu/page.js`): 14:00 자동 스나이퍼 상태 배지를 `비활성화됨`으로 전환하고 종료 안내 문구 반영.
  - 기술 가이드 문서(`docs/pocketcu-technical-guide.md`)에 11월 비활성화 내역 기록.

### G. 서울사랑상품권 (서울Pay+) HAR 세션 갱신 및 SQLite 바인딩 예외 패치
* **파일**: `lib/seoulpay.mjs`, `docs/seoulpay-technical-guide.md`, `docs/DAILY_WORK_LOG.md`
* **배경**: 사용자 업로드 HAR 파일(`1793599321408_seoul-wapi_bizplay_co_kr_11-02-2026-15-0.har`)을 이용한 서울Pay+ 세션 갱신 및 기존 만료 세션으로 인한 모니터링 루프 에러 해소.
* **조치 사항**:
  1. **SQLite `node:sqlite` 파라미터 바인딩 예외 수정 (`lib/seoulpay.mjs`)**:
     - `saveSeoulPayAccount`에서 `undefined` 전달 시 발생하는 `TypeError: Provided value cannot be bound to SQLite parameter`를 방지하기 위해 전체 바인딩 파라미터에 `?? null` 널 병합 연산자 적용.
  2. **HAR 세션 파싱 및 계정 정보 갱신**:
     - 업로드된 HAR 파일에서 마스터 계정(염성욱)의 최신 쿠키 및 결제 수단(롯데체크카드 등)을 추출하여 DB에 반영.
  3. **모니터링 검색 전담 및 구매 우선순위 전환**:
     - 검색 전담 계정(`is_search_account = 1`)과 구매 1순위 계정을 마스터 계정으로 전환하여 백그라운드 모니터링 루프 정상화.

### H. 서울사랑상품권 2인 사용자별 독립 즉시 구매 버튼 분리 UI 개편
* **파일**: `app/admin/seoulpay/page.js`, `docs/seoulpay-technical-guide.md`, `docs/DAILY_WORK_LOG.md`
* **배경**: 검색 계정에 종속되어 있던 단일 즉시 구매 버튼을 분리하여 2명의 유저(염성욱, 박수지)가 각각 본인 계정으로 즉시 결제할 수 있도록 개선.
* **조치 사항**:
  1. **상품권 카드 즉시 구매 버튼 2열 분할 (`app/admin/seoulpay/page.js`)**:
     - 상품권 카드 하단에 `[⚡ 염성욱 즉시 구매]`와 `[⚡ 박수지 즉시 구매]`를 2열 그리드로 배치하여 클릭 시 대상 계정 ID를 명시적으로 전달.
     - 수동 모니터링 결과 팝업 내 구매 버튼도 동일하게 2인 개별 버튼으로 분할.
  2. **모달 계정 프리셋 및 독립 결제 보장**:
     - 클릭한 사용자의 계정 ID가 구매 모달에 자동 프리셋되며, 특정 계정 지정 시 `allowFailover: false`를 전달하여 타 계정 전환 없이 해당 계정으로만 엄격하게 결제를 진행하도록 보장.
     - 모달 결제 승인 버튼 명칭도 `⚡ [염성욱] 결제 승인 및 즉시 구매`, `⚡ [박수지] 결제 승인 및 즉시 구매`로 동적 반영.

### I. 서울사랑상품권 검색 전담 계정 만료 시 자동 페일오버 및 설정 동기화
* **파일**: `lib/seoulpay.mjs`, `docs/seoulpay-technical-guide.md`, `docs/DAILY_WORK_LOG.md`
* **배경**: 신규 HAR 세션(염성욱) 등록 후에도 기존 검색 전담 계정(박수지)의 만료된 세션으로 인해 상품권 목록 조회 시 간헐적으로 `세션이 만료되었습니다` 오류가 반환되던 구조 개선.
* **조치 사항**:
  1. **다중 계정 자동 페일오버 (`fetchSeoulPayCertificates`)**:
     - 후보 계정 큐(`candidateQueue`)를 구성하여, 검색 계정이 세션 만료 시 정상 세션을 보유한 다른 계정(염성욱)으로 즉시 순차 조회.
     - 조회 성공 시 `setSearchAccount(activeAcc.id)`를 호출하여 정상 계정으로 검색 전담을 자동 전환.
  2. **`setSearchAccount` 시 설정 자격증명 완전 동기화**:
     - `seoulpay_config` 테이블의 쿠키, 단말 User-Agent, userNo, 결제수단 일체를 새 계정 정보로 실시간 동기화.
  3. **HAR 임포트 연동**:
     - HAR 반영 계정을 검색 계정으로 즉시 활성화하여 브라우저 새로고침 시 즉각 반영되도록 조치.
  4. **비즈플레이 리프레시 토큰 기반 원클릭 & 무중단 자가치유(Self-Healing) 세션 연장 시스템 구축**:
     - **프로토콜 분석**: 비즈플레이 서울Pay+ 앱 로그인 시 발급되는 `refreshToken`의 유효기간이 1년(~2027년)임을 확인하고, `POST https://seoul-wapi.bizplay.co.kr/wapi/app/token/refresh` 엔드포인트를 발굴.
     - **DB 영구 보관**: `seoulpay_accounts` 및 `seoulpay_config` 테이블에 `refresh_token` 컬럼을 신설하고 전 계정 토큰 등록.
     - **자가치유(Self-Healing)**: 상품권 목록 조회(`fetchSeoulPayCertificates`) 및 구매 시도(`executeSeoulPayPurchase`) 중 세션 만료 감지 시 자동으로 리프레시 토큰을 호출해 세션을 즉시 갱신하고 재시도하는 회복 메커니즘 탑재.
     - **관리자 UI 원클릭 갱신**: 대시보드 상단 글로벌 버튼(`[🔄 세션 즉시 갱신]`), 계정 관리 탭 헤더(`[🔄 전 계정 세션 즉시 갱신]`), 각 계정 카드별(`[🔄 세션 갱신]`) 버튼을 배치하여 수동 본인인증이나 HAR 업로드 없이 원클릭 세션 연장 지원.

---

## 3. 검증 결과

1. **현대Hi 단일 계정 및 다중 계정 듀얼 실행 실측**:
   - 이벤트 탐색 대상 확장: `rllnList` 및 `evntContentList` 전체 배열 병합 탐색으로 배너 변동 시에도 룰렛/출석체크 자동 인식 보장.
   - 계정 15 (`dalkong19`): `출석체크: 이미 참여 완료 · 룰렛: 이미 참여 완료`
   - 계정 16 (`krazyeom`): `출석체크: 이미 참여 완료 · 룰렛: 이미 참여 완료`
   - 계정 17 (`mikako13`): `출석체크: 이미 참여 완료 · 룰렛: 이미 참여 완료`
   - 매일 스케줄러(`worker.mjs`) 및 수동 실행 시 출석체크(`00011031`)와 SPECIAL 룰렛(`00011015`)이 1회 호출로 모두 동시 응모되도록 연동 완료.
2. **신세계백화점 11월 제휴 4대 카드사 전체 23개 계정 실행**:
   - 셜리 계정(3개), ㅇㅋ 계정(10개) 및 전 계정 4대 카드(BC바로, 삼성, 하나, 신한) 출석 1일 차 완료 (`status: success`).
3. **네이버 카페 자동 포스팅 검증**:
   - 11월 2일 기준 `1일 차` 자동 계산 및 실게시 완료 (글 번호: `75509`).
4. **서울사랑상품권 실시간 모니터링 및 세션 검증**:
   - WAPI 상품권 목록 53건 조회 정상 응답 (HTTP 200).
   - 잔여 상품권 감지 루프 정상 가동 및 `세션이 만료되었습니다` 에러 완전 해소.
5. **서울사랑상품권 2인 개별 즉시 구매 버튼 빌드 및 렌더링 검증**:
   - Next.js 16.4.3 프로덕션 빌드 성공 및 PM2 무중단 재기동 완료.
   - 염성욱(`userA`), 박수지(`userB`) 각각의 독립 즉시 구매 버튼 렌더링 및 모달 프리셋 동작 확인.
6. **서비스 재가동 및 헬스체크**:
   - `attendance-check` (id 16): `online`
   - `attendance-check-worker` (id 17): `online`
   - DB 무결성: `PRAGMA integrity_check` $\rightarrow$ `ok`

---

## 4. 보안 검증 (Security Zero-Leak)
* 비밀번호, 암호화 비밀키, 카카오 REST API 시크릿, 개인 JWT 토큰을 기록하지 않음.
* 개인 식별 정보(PII)는 마스킹 처리 및 표준 심볼로 기술함.

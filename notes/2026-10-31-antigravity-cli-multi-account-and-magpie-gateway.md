---
layout: default
title: "2026-10-31 작업 노트: Antigravity CLI 다중 계정 분기 아키텍처 및 Magpie 게이트웨이 연동"
---

# 2026-10-31 작업 노트: Antigravity CLI 다중 계정 분기 아키텍처 및 Magpie 게이트웨이 연동

* **작업 대상**: Google Antigravity CLI (`agy`), Magpie AI Gateway (`krazyeom/magpie`), Worknote 문서화 시스템
* **핵심 주제**: 단일 계정 키체인 제약 분석, 게이트웨이 기반 다중 계정 풀링 및 페일오버, 계정 격리 실행(Gateway Key 바인딩), 개인 원격 저장소 이관 및 전역 룰 수립
* **문서 성격**: 엔지니어링 분석 기록, 연동 전략 수립 및 기술 결정 사항 정리

---

## 1. 당일 작업 개요

Google Antigravity CLI(`agy`)는 기본적으로 macOS 시스템 키체인(`keychainStorage`)에 1개의 OAuth 토큰만 저장하도록 설계되어 있어, 단독 실행 환경에서는 복수 계정 간 프로필 전환이나 다중 계정 선택 기능을 제공하지 않습니다.  
이에 따라 사용자가 보유한 다수의 Antigravity 계정을 유연하게 선택해 활용하거나, 계정별 쿼터를 하나로 묶어 사용할 수 있도록 **Magpie 게이트웨이 연동 아키텍처**를 정밀 분석하고 운용 전략을 수립했습니다.  
아울러 향후 변경 사항 관리를 위해 Magpie 저장소의 원격(Remote)을 개인 저장소(`git@github.com:krazyeom/magpie.git`)로 재편하고 최신 변경점을 동기화했으며, 시스템 전역에 적용되는 **Antigravity 공통 룰(Universal Rule)**을 배포했습니다.

---

## 2. 주요 분석 및 아키텍처 설계

### A. Antigravity CLI (`agy`) 인증 구조 및 한계 분석
* **단일 자격 증명 저장 메커니즘**:
  * `agy` 바이너리 내부 분석 결과, macOS Keychain API(`go_keyring` / `find-generic-password`)를 사용하여 OAuth 리프레시 토큰을 단일 키 슬롯에 보관합니다.
  * CLI 자체적으로 `--profile`이나 계정 전환 서브커맨드를 지원하지 않아, 단독 상태에서는 한 번에 1개의 계정만 활성화할 수 있습니다.
* **외부 엔드포인트 연동 통로 확인**:
  * `~/.gemini/antigravity-cli/settings.json` 내 `modelProvider: "gemini"` 및 `customModelsConfig.customModels` 구조를 통해 프록시 엔드포인트로 우회할 수 있습니다.
  * 기동 시 환경변수 `GOOGLE_GEMINI_BASE_URL`과 `GEMINI_API_KEY`를 주입받아 동작하므로, 로컬 AI 게이트웨이(Magpie)와 연동하여 다중 계정 처리가 가능함을 확인했습니다.

---

### B. Magpie 기반 Antigravity 다중 계정 제어 체계
* **다수 계정 등록 및 자동 풀링 (`antigravity_pool.go`)**:
  * `magpie accounts add antigravity`를 통해 여러 개의 Google Antigravity 계정을 등록할 수 있습니다.
  * 등록된 계정이 모두 활성화(`On: true`)되면 `antigravityPoolModels()`가 계정별 모델 목록을 병합하고, 계정 순서 및 쿼터 잔여량에 따라 자동 라우팅을 수행합니다.
* **쿼터 자동 페일오버 (Failover) 및 부하 분산 (`fallback.go`)**:
  * 기본 계정의 사용량이 100%에 도달하거나 속도 제한(429 Rate Limit)에 걸리면, `AlsoOn()`에 정의된 차순위 활성 계정으로 요청을 즉시 우회하여 중단 없는 작업을 보장합니다.
* **기본 계정 명시적 전환 (`accounts switch`)**:
  * `magpie accounts switch antigravity <user@example.com>` 명령을 통해 게이트웨이가 1순위로 사용할 활성(`Active`) 계정을 실시간 변경할 수 있습니다.

---

### C. 계정별 완전 격리 실행 (Gateway Key 바인딩 전략)
Antigravity CLI 기동 시 특정 계정만 배타적으로 사용해야 하는 경우(예: 회사 계정과 개인 계정의 엄격한 분리), Magpie의 Gateway Key 화이트리스트 기능을 활용합니다.

1. **계정 전용 게이트웨이 키 생성**:
   ```bash
   # 전용 키 생성 및 계정 바인딩
   magpie gateway-key add agy-work
   magpie gateway-key accounts agy-work antigravity/work@example.com
   ```
2. **독립 환경변수 주입을 통한 CLI 기동**:
   ```bash
   # 특정 계정에 고정하여 agy 실행
   GEMINI_API_KEY="<발급받은_키>" GOOGLE_GEMINI_BASE_URL="http://127.0.0.1:51121" agy
   ```
   * 이를 셸 환경의 `agy-work`, `agy-personal` 등의 alias 또는 래퍼 스크립트로 래핑하여 CLI 상에서 계정을 골라 즉시 실행할 수 있습니다.

---

### D. Magpie 저장소 원격 관리 재편 및 동기화
* **원격 저장소 구조 재구성**:
  * 오픈소스 공식 저장소(`https://github.com/yetone/magpie`)를 `upstream`으로 재명명했습니다.
  * 개인 관리 저장소(`git@github.com:krazyeom/magpie.git`)를 새로운 `origin`으로 등록했습니다.
* **패스트포워드(Fast-Forward) 동기화**:
  * `origin/main`의 최신 커밋(`7aa67e9e5`)을 페치하여 로컬 `main` 브랜치에 안전하게 병합하고 업스트림 추적 브랜치(`branch --set-upstream-to=origin/main main`)를 정렬했습니다.

---

### E. Antigravity 머신 전역 룰 (Global Rule) 배포
* 시스템 전체의 Antigravity 및 Gemini CLI 세션에 일관되게 적용되는 공통 규칙을 `~/.gemini/GEMINI.md` 및 `~/.gemini/config/GEMINI.md`에 배포했습니다.
* **5대 보안 원칙 (Security Zero-Leak)**:
  * API Key, 비밀번호, 사설 IP, PII(개인정보), `.env` 실제 값의 커밋 및 문서 노출을 전면 금지했습니다.

---

### F. Antigravity Pool 통합 CLI 래퍼 (`agyp`) 개발 및 배포
* 다중 계정 자동 Failover 풀링과 수동 계정 선택을 단일 명령어로 제어할 수 있는 CLI 도구 [`agyp`](~/.local/bin/agyp) 및 심볼릭 링크 [`agy-pool`](~/.local/bin/agy-pool)을 개발하여 `~/.local/bin/`에 배포했습니다.
* **주요 기능**:
  * `agyp`: 등록된 모든 계정의 자동 Failover 풀링 상태로 agy 실행
  * `agyp -a <계정>`: 지정한 계정을 1순위로 지정하여 선택 실행
  * `agyp list`: 계정 목록 및 실시간 쿼터 확인
  * `agyp add`: 새 구글/Antigravity 계정 간편 추가
  * `agyp switch <계정>`: 기본 1순위 주 계정 변경
  * `agyp status`: 게이트웨이 기동 및 연결 상태 점검
* **업무 일지 표준 규격 동기화**:
  * `krazyeom/worknote` 저장소와 연동하여 작업 내역이 누락 없이 GitHub Pages 규격으로 정리되도록 정의했습니다.

---

### G. Magpie 앱(GUI/CLI) 네이티브 Antigravity 계정 스위칭 및 시스템 키체인 동기화 구현
* **Magpie 앱 GUI 계정 스위처 연동 (`internal/gui/assets/app.js`)**:
  * `switchesAccounts` 함수에 `agy`를 등록하여, 미연결 단독 모드에서도 Claude Code나 Codex처럼 에이전트 목록 행에 계정 스위처 버튼(`.ag-acc.ag-who`)이 노출되도록 개선했습니다.
  * 팝업 메뉴에서 원하는 Antigravity 계정을 선택하면 `POST /api/login/switch`를 호출하여 실시간 계정 전환이 수행됩니다.
* **에이전트 설정 서랍(Drawer) 내 `account` Field 신설 (`internal/agent/agy.go`)**:
  * Antigravity CLI 설정 서랍에 `account` 필드를 추가하여, 현재 활성화된 주 계정을 표시하고 등록된 계정 풀 목록을 드롭다운으로 선택하여 전환할 수 있도록 구현했습니다.
* **macOS 시스템 키체인 원자적 동기화 (`internal/provider/google.go`)**:
  * `switchGoogleLogin` 수행 시 Magpie의 `logins.json` 내 1순위 계정(`First: true`) 갱신뿐만 아니라, macOS 시스템 키체인(`service: gemini, account: antigravity`)의 OAuth 자격 증명(`go-keyring-base64:<json>`)을 직접 갱신하도록 구현했습니다.
  * 이를 통해 Magpie 게이트웨이를 경유하는 호출은 물론, 터미널에서 `agy`를 단독 실행하는 경우에도 선택한 계정으로 즉시 전환되어 동작합니다.
* **바이너리 빌드 및 배포**:
  * `make build` 및 `make app`을 통해 macOS `magpie.app` 번들을 성공적으로 패키징하고 `/Applications/magpie.app`에 반영했습니다.
  * 단위 테스트(`internal/agent`, `internal/provider`) 검증 및 실시간 계정 스위칭 통신 검증을 완료했습니다.

---

## 3. 기술 결정 사항 (ADR 요약)

| 결정 주제 | 채택한 방안 | 기각된 대안 및 사유 |
| :--- | :--- | :--- |
| **다중 계정 관리 주체** | **Magpie AI Gateway 프록시 라우팅 위임** | Antigravity CLI 자체 소스코드 패치: 공식 바이너리 자동 업데이트 시 수정 내역이 덮어쓰여 유지보수 불가 |
| **계정 분기 제어 방식** | **Gateway Key 계정 바인딩 (`gateway-key accounts`)** | 홈 디렉토리 분리(`HOME=~/.agy2 agy`): 키체인 접근 권한 및 도구 전역 설정 공유가 깨져 사용성 저하 |
| **Git 원격 구조** | **`origin`(개인 포크) / `upstream`(오리지널) 분리** | 단일 `origin` 강제 푸시: 오리지널 업데이트 추적 및 풀 리퀘스트 관리가 번거로워짐 |
| **전역 룰 배치 경로** | **`~/.gemini/GEMINI.md` 표준 마운트** | 프로젝트별 개별 복사: 새로운 디렉터리마다 룰 파일 생성을 반복해야 하는 비효율 발생 |

---

## 4. 검증 결과

* **원격 접근 및 동기화 검증**:
  * `git ls-remote git@github.com:krazyeom/magpie.git` 정상 통신 확인.
  * 로컬 브랜치 `origin/main` 추적 및 클린 워킹 트리 확인.
* **전역 룰 배포 검증**:
  * `~/.gemini/GEMINI.md` 및 `~/.gemini/config/GEMINI.md` 정상 저장 확인.
* **보안 검수 (Security Zero-Leak)**:
  * 실제 토큰, 비밀번호, 실명, 사설 IP가 본문에 포함되지 않았음을 교차 검증 완료.

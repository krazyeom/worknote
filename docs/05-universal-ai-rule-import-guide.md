# 문서 05: 범용 AI 작업 일지 룰 및 스킬 임포트 가이드

본 문서는 사내 프로젝트나 개인 저장소에서 **Claude, Codex, Antigravity, Gemini, Cursor** 등 어떤 AI 도구를 사용하더라도 표준화된 업무 일지 및 아키텍처 문서를 생성할 수 있도록 규칙과 스킬을 임포트하는 방법을 안내합니다.

---

## 1. 지원 도구 및 인식 파일 매핑표

| AI 도구 / 에이전트 | 인식 파일 경로 | 동작 방식 |
| :--- | :--- | :--- |
| **OpenAI Codex / ChatGPT** | `AGENTS.md` (루트) | 워크스페이스 컨텍스트 최상위 규칙으로 자동 로드 |
| **Antigravity CLI / IDE** | `AGENTS.md`, `GEMINI.md`, `.agents/skills/` | 프로젝트 루트 규칙 및 스킬 자동 로드 |
| **Anthropic Claude Code** | `CLAUDE.md` (루트) | 대화 시작 시 프로젝트 지침으로 자동 참조 |
| **Google Gemini CLI** | `GEMINI.md` (루트 또는 `~/.gemini/`) | 세션 초기화 시 전역/로컬 규칙으로 자동 주입 |
| **Cursor IDE** | `.cursorrules`, `.cursor/rules/*.mdc` | 에디터 채팅 및 코드 생성 프롬프트에 자동 적용 |

---

## 2. 임포트 방법 1: 원클릭 자동 설정 스크립트 (가장 권장)

새로운 프로젝트 디렉터리에서 아래 명령을 실행하면 `worknote`를 서브모듈로 등록하고, 각 AI 도구에 필요한 심볼릭 링크를 한 번에 구성합니다.

```bash
# 프로젝트 루트에서 실행
curl -fsSL https://raw.githubusercontent.com/krazyeom/worknote/main/scripts/setup-worknote.sh | bash
```

이 스크립트는 다음 작업을 원자적으로 수행합니다:
1. `.worknote` 경로로 저장소를 서브모듈 추가(또는 클론)
2. `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.cursorrules` 심볼릭 링크 생성
3. `.agents/skills/daily-worknote` 스킬 마운트

---

## 3. 임포트 방법 2: Git 서브모듈 수동 연결

사내 보안 프록시 환경 등으로 쉘 파이프 실행이 제한되는 경우, Git 명령어로 직접 연결할 수 있습니다.

```bash
# 1. 서브모듈 추가
git submodule add https://github.com/krazyeom/worknote.git .worknote

# 2. 각 AI 도구용 심볼릭 링크 생성
ln -sf .worknote/rules/AGENTS.md AGENTS.md
ln -sf .worknote/rules/AGENTS.md CLAUDE.md
ln -sf .worknote/rules/AGENTS.md GEMINI.md
ln -sf .worknote/rules/AGENTS.md .cursorrules

# 3. Antigravity 스킬 폴더 마운트
mkdir -p .agents/skills
ln -sfn ../../.worknote/skills/daily-worknote .agents/skills/daily-worknote
```

팀원들은 저장소를 클론한 후 `git submodule update --init --recursive`만 실행하면 즉시 동일한 AI 작업 일지 환경을 사용할 수 있습니다.

---

## 4. 임포트 방법 3: 개발자 PC 전역(Global) 적용

프로젝트 저장소에 별도 파일을 커밋하지 않고 개인 작업 환경 전체에 일괄 적용하려는 경우:

### A. Antigravity & Gemini CLI
```bash
# 글로벌 스킬 디렉터리에 마운트
mkdir -p ~/.gemini/antigravity-cli/skills
git clone https://github.com/krazyeom/worknote.git ~/.gemini/worknote-src
ln -sfn ~/.gemini/worknote-src/skills/daily-worknote ~/.gemini/antigravity-cli/skills/daily-worknote
```

### B. Claude Code
```bash
# Claude 전역 설정 파일에 룰 복사 또는 심볼릭 링크
mkdir -p ~/.claude
ln -sf ~/.gemini/worknote-src/rules/AGENTS.md ~/.claude/CLAUDE.md
```

---

## 5. 실무 사용 및 명령 예시

임포트가 완료되면 어떤 AI 챗봇에서도 평어로 업무 일지 작성을 요청할 수 있습니다:

```text
사용자: "오늘 작업한 내용을 worknote로 정리해서 커밋해줘."
```

AI 에이전트의 내부 실행 순서:
1. `git status` 및 `git diff`를 조회하여 당일 수정 사항 수집
2. API Key, 비밀번호, 사설 IP 등 보안 취약 요소 사전 검수 (Security Zero-Leak)
3. `notes/YYYY-MM-DD-<project>.md` 파일 생성 (개요, 변경점, 트러블슈팅, ADR)
4. `index.md` 목차 자동 동기화
5. `git add` 및 커밋/푸시 수행

---
layout: default
title: "Engineering Worknotes"
---

# Engineering Worknotes

기술 설계, 구현 내역, 아키텍처 결정 사항(ADR)을 기록하는 작업 노트 저장소입니다.  
GitHub Pages 및 마크다운 뷰어에서 바로 열람할 수 있도록 정돈된 문서 구조를 유지합니다.

> 🎬 **신규 프로젝트 [subtitle-to-speech](https://subtitle.krazyeom.com)**: 영화 대본 자막 TTS 섀도잉 플레이어  
> [작업 일지 보기](notes/2026-10-31-subtitle-to-speech-tts-shadowing-archive.md) · [아키텍처 명세(문서 07) 보기](docs/07-subtitle-to-speech-audio-pipeline-and-slicing.md)

---

## 📚 목차

### 1. 작업 일지 (Daily Logs)
* [2026-10-31: subtitle-to-speech 영화 대본 TTS 섀도잉 및 대용량 배치 슬라이서 구축](notes/2026-10-31-subtitle-to-speech-tts-shadowing-archive.md)
  * IMSDb 원본 각본 기반 노팅힐 12개 메이저 챕터(936개 대사) 전편 수록
  * 80ms 쿼드라틱 감쇄 및 60ms 무음 제로 패딩을 통한 오디오 팝/클릭 노이즈 완전 박멸
  * 화자 성별 자동 감지 기반 남녀 배역 음성(`Puck`/`Kore`) 자동 분기
  * 15개 대사 묶음 호출 및 RMS 침묵 탐지 슬라이서를 통한 API 요청수 92% 절감
  * 백그라운드 사전 캐싱(Pre-cache) 파이프라인 및 메인 화면 실시간 캐싱 진행도(%) 게이지
  * 관리자(ADMIN) 권한 기반 자막 수정 제어 및 HMAC 보안 세션 인증
  * 다크/라이트 테마 전환 시스템 및 Anti-FOUC 하이드레이션 구축
  * 모바일 뷰포트(360~390px) 상단 메뉴 겹침 해소 및 반응형 타이포그래피 최적화
  * 대사별 순차 큐 자동 전진 및 2단계 프리페치를 통한 음성-자막 100% 실시간 싱크 보장
  * aWord 계승 Zero-Layout-Shift 단어 하이라이터 구축으로 글자 흔들림 박멸
  * 328.5초 선두/후미 무음 제거 및 60fps rAF 초정밀 싱크 엔진 적용
  * 비발화 기호(`...`, `--`) 하이라이트 배제 및 가중치 기반 발화 단어 매핑으로 싱크 오차 원천 차단
* [2026-10-31: Antigravity CLI 다중 계정 분기 아키텍처 및 Magpie 게이트웨이 연동](notes/2026-10-31-antigravity-cli-multi-account-and-magpie-gateway.md)
  * Antigravity CLI 단일 키체인 저장 한계 및 외부 엔드포인트 우회 분석
  * Magpie 게이트웨이 기반 다중 계정 풀링, 자동 페일오버 및 계정 전환 메커니즘
  * Gateway Key 화이트리스트 바인딩을 통한 계정별 독립 실행 전략
  * Magpie 저장소 개인 원격(`krazyeom/magpie`) 관리 체계 전환 및 전역 룰 배포
* [2026-10-31: aWord 영한 대조 학습 엔진 및 블로그 다국어 시스템 구축](notes/2026-10-31-aword-tts-shadowing-and-blog-i18n.md)
  * Gemini Flash 기반 1:1 문장 정합 번역 파이프라인
  * 24kHz Studio AI 음성 합성 및 0ms 프리페치
  * 실시간 배속(0.5x~2.0x) 및 3단계 루프 모드(S/A/Off)
  * Zero-Layout-Shift 인라인 하이라이터
  * 블로그 다국어(EN/KO) 실시간 동기화 스위처

---

### 2. 아키텍처 명세서 (Architecture Specifications)
* [문서 01: 영한 대조 학습 및 백그라운드 번역 파이프라인](docs/01-bilingual-study-tts-pipeline.md)
  * 마크다운 본문 추출(코드 블록 및 터미널 명령어 정제)
  * 7문장 청크 분할 및 자가 복구 JSON 파서
  * SHA-256 디스크 영구 캐시(`.study.json`) 및 원자적 락 관리
* [문서 02: 오디오 엔진 비교 및 iOS Safari 환경 분석](docs/02-audio-engine-safari-analysis.md)
  * Google Cloud 24kHz Studio 음성 vs iOS Web Speech API 음질 실측
  * iOS Safari WebKit 자동 재생 정책과 단일 오디오 엘리먼트 유지 기법
  * 전역 오디오 레지스트리를 활용한 페이지 전환 시 음원 누수 차단
* [문서 03: 실시간 오디오 제어 및 다단계 루프 메커니즘](docs/03-playback-control-and-loop-modes.md)
  * HTMLMediaElement `src` 변경 시 `playbackRate` 리셋 방어 알고리즘
  * 문장 반복(`S`) 및 전체 문장 반복(`A`) 순환 제어 로직
  * 단어 발화 중심점 스냅 기반 인라인 텍스트 하이라이터
* [문서 04: 블로그 시스템 및 다국어(I18n) 동기화 아키텍처](docs/04-blog-system-and-i18n-sync.md)
  * Next.js 14 App Router 서버 컴포넌트와 클라이언트 뷰 분리
  * `localStorage` 및 커스텀 이벤트를 활용한 에디터-블로그 언어 동기화
  * 메타데이터 바 배지 배치 및 가독성 최적화
* [문서 05: 범용 AI 작업 일지 룰 및 스킬 임포트 가이드](docs/05-universal-ai-rule-import-guide.md)
  * Claude, Codex, Antigravity, Gemini, Cursor 환경 원클릭 연동
  * 사내 프로젝트 서브모듈 및 심볼릭 링크 표준 세팅
  * Security Zero-Leak 자동 검증 워크플로
* [문서 06: Antigravity CLI 다중 계정 분기 및 게이트웨이 통합 아키텍처](docs/06-antigravity-cli-multi-account-architecture.md)
  * Antigravity CLI 단일 키체인 바인딩 제약과 커스텀 엔드포인트 우회 기법
  * Magpie 게이트웨이의 계정 풀링, 자동 페일오버 및 라운드로빈 메커니즘
  * GUI 조작 매뉴얼(Agents 탭 빠른 스위처, 설정 서랍, Providers 카드 Make first)
  * macOS 키체인 양방향 동기화 및 CLI 래퍼(`agyp`)
  * krazyeom 커스텀 빌드 식별 메타데이터, 독립 버전 태그 및 업스트림 덮어쓰기 방어
* [문서 07: 영화 대본 TTS 오디오 파이프라인 및 침묵 탐지 슬라이싱 아키텍처](docs/07-subtitle-to-speech-audio-pipeline-and-slicing.md)
  * 16-bit 24kHz Linear PCM 디클릭 신호 처리 및 끝단 제로 패딩
  * 대용량 대본 청크 벌크 호출 및 국소 윈도우 RMS 침묵 탐지 분할 알고리즘
  * 브라우저 WebAudio 하드웨어 버퍼 파쇄음 방어를 위한 단일 Audio 인스턴스 재사용 패턴

---

### 3. 공용 규칙 및 스킬 (Rules & Skills)
* **[rules/AGENTS.md](rules/AGENTS.md)**: 모든 AI 에이전트(Claude, Codex, Antigravity, Cursor) 공용 표준 규칙
* **[skills/daily-worknote/SKILL.md](skills/daily-worknote/SKILL.md)**: 하루 작업 내역을 자동 수집하고 표준 문서로 생성하는 에이전트 스킬
* **[scripts/setup-worknote.sh](scripts/setup-worknote.sh)**: 새로운 프로젝트에서 1초 만에 AI 규칙을 적용하는 설치 스크립트

---

## 🔒 보안 및 개인정보 보호 지침
* API 키, 서비스 토큰, 데이터베이스 접속 정보, 개인 식별 정보는 일절 기록하지 않습니다.
* 모든 환경 설정 변수는 템플릿(`process.env.GEMINI_API_KEY`) 형태로 표기합니다.

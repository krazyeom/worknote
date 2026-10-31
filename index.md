# Engineering Worknotes

기술 설계, 구현 내역, 아키텍처 결정 사항(ADR)을 기록하는 작업 노트 저장소입니다.  
GitHub Pages 및 마크다운 뷰어에서 바로 열람할 수 있도록 정돈된 문서 구조를 유지합니다.

---

## 📚 목차

### 1. 작업 일지 (Daily Logs)
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

---

## 🔒 보안 및 개인정보 보호 지침
* API 키, 서비스 토큰, 데이터베이스 접속 정보, 개인 식별 정보는 일절 기록하지 않습니다.
* 모든 환경 설정 변수는 템플릿(`process.env.GEMINI_API_KEY`) 형태로 표기합니다.

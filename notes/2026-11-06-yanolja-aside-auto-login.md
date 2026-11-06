---
layout: note
title: "야놀자 Aside AI 브라우저 기반 krazyeom@gmail.com 자동 로그인 및 라이브 세션 동기화"
date: 2026-11-06
tags: [yanolja, aside, auto-login, session-sync, coupon-api, live-test]
---

# 야놀자 Aside AI 브라우저 기반 krazyeom@gmail.com 자동 로그인 및 라이브 세션 동기화

## 1. 작업 개요
- **배경**:
  - 사용자 계정(`krazyeom@gmail.com` / `P@ssW0rd3#`)을 원격 맥북의 Aside AI 브라우저를 통해 야놀자에 로그인하고, 획득한 세션을 출석체크 서버 DB에 동기화한 뒤 실시간 쿠폰 발급 API 동작을 검증함.
- **주요 해결 사항**:
  1. 단순 아이디(`krazyeom`) 입력 시 야놀자 이메일 로그인 폼의 유효성 검사("올바른 이메일 형식으로 입력해 주세요")로 인해 폼 제출이 차단되던 문제를 `krazyeom@gmail.com` 적용으로 해결.
  2. Cloudflare Turnstile 토큰 수신 대기 및 CDP `Input.insertText`를 활용한 리액트 폼 컨트롤러 바인딩.
  3. 로그인 성공 후 마이페이지(`https://nol.yanolja.com/member/mypage`) 진입 및 닉네임(`가랑비놀고싶소5346`) 확인.
  4. 세션 쿠키(`yanolja_sid` 등)를 출석체크 서버 `accounts` 및 `aside_sessions` 테이블에 안전하게 암호화 동기화.
  5. 최신 해외 항공 쿠폰 발급 API(`contentId=3197`, `moduleId=163243`) 테스트 호출로 회원 인증 무결성 검증.

---

## 2. 세부 검증 결과

### 2.1. 로그인 결과
- **계정**: `krazyeom@gmail.com`
- **회원 닉네임**: `가랑비놀고싶소5346`
- **최종 이동 URL**: `https://nol.yanolja.com/member/mypage`
- **추출 세션**: `yanolja_sid = s%3AYKmfY0mq1I1V...` (동기화 완료)

### 2.2. 쿠폰 발급 API 실시간 통신 테스트
- **엔드포인트**: `POST https://cx-content-api.yanolja.com/promotion/v1/use-benefit-promotion?contentId=3197&moduleId=163243`
- **HTTP 응답 코드**: `201 Created`
- **지연 시간**: `114ms`
- **인증 상태**: `unauthorized: false` (정상 로그인 회원 식별 확인)
- **응답 팝업**: `선착순 쿠폰이 모두 마감되었어요.` (당일 10시 선착순 종료 정상 메시지 수신)

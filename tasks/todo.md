# 출시 과업

상태: planned → active → done. 외부 조건이 필요하면 blocked. 관리: `python3 scripts/tasks.py --help`.

## T01: 저장소 과업 관리와 worktree

**Status:** active
**Depends:** None
**Acceptance:** 상태 원본·CLI·Git 템플릿을 준비하고 브랜치를 원격에 등록
**Verify:** task CLI check; git worktree list; remote branch 확인
**Files:** scripts/tasks.py, tasks/*, .github/*
**Evidence:** —
**Reason:** —

## T02: 금액 의미와 후보 데이터

**Status:** planned
**Depends:** T01
**Acceptance:** 상품 가격/할인액/잔액 분리; 모든 번호 후보 보존; 기존 데이터 유지
**Verify:** parser/persistence/migration 단위 테스트
**Files:** Models/*, Services/GifticonParser.swift, Services/PersistenceService.swift
**Evidence:** —
**Reason:** —

## T03: 인식 실패 직접 등록

**Status:** planned
**Depends:** T02
**Acceptance:** 바코드 실패에도 원본+직접 입력; 선택 후보와 번호 중복 검증; 취소 시 고아 파일 없음
**Verify:** manual import UI + persistence 테스트
**Files:** Views/ManualImportView.swift, Views/GifticonEditor.swift
**Evidence:** —
**Reason:** —

## T04: 기존 쿠폰 후보와 금액 수정

**Status:** planned
**Depends:** T03
**Acceptance:** 후보 선택 가능; 교환권 가격과 잔액 분리; 차감 후 원금 수정 제한
**Verify:** editor/detail UI + balance 회귀 테스트
**Files:** Views/GifticonEditor.swift, Views/GifticonDetailView.swift
**Evidence:** —
**Reason:** —

## T05: 공유 저장 결과와 실패 큐

**Status:** planned
**Depends:** T02
**Acceptance:** 공유 저장 실패 안내; 순차 제한 크기 처리; 앱 재시도 실패가 원본을 유실하지 않음
**Verify:** inbox/import 단위 테스트 + 공유 확장 빌드
**Files:** GifticonCollectorShare/ShareViewController.swift, Services/SharedImageInbox.swift, Services/SharedImportService.swift
**Evidence:** —
**Reason:** —

## T06: 실패 큐 복구 화면

**Status:** planned
**Depends:** T05,T03
**Acceptance:** 대기 항목 재시도/직접 입력/삭제; 앱 재진입 결과 표시; 중복 파일 정리
**Verify:** queue UI + duplicate/retry 테스트
**Files:** Views/RootView.swift, Views/GifticonListView.swift, Views/ManualImportView.swift
**Evidence:** —
**Reason:** —

## T07: 자동 찾기와 기존 원본 보존

**Status:** planned
**Depends:** T02
**Acceptance:** 새 쿠폰 원본 복사 후 등록; 기존 Photos 참조 복사; 권한 상실 시 원본 누락 복구
**Verify:** archive persistence 테스트 + scan build
**Files:** Services/PhotoLibraryService.swift, ViewModels/ScanViewModel.swift, Services/SharedImportService.swift
**Evidence:** —
**Reason:** —

## T08: 만료 알림 예약과 갱신

**Status:** planned
**Depends:** T04
**Acceptance:** 명시적 권한과 설정; 승인된 미사용 쿠폰만 예약; 수정/사용/삭제와 날짜 경계에서 갱신
**Verify:** notification plan 단위 테스트 + settings UI
**Files:** Services/NotificationService.swift, Services/PersistenceService.swift, Views/RootView.swift, Views/GifticonListView.swift
**Evidence:** —
**Reason:** —

## T09: 출시 후보 회귀와 네이티브 배포

**Status:** planned
**Depends:** T04,T06,T07,T08
**Acceptance:** 전체 자동 테스트 통과; iPhone/iPad QA 증거; Release Archive와 로컬 설치
**Verify:** xcodebuild test/archive; deploy-local; 결과 bundle
**Files:** Tests/*, UITests/*, scripts/*, project.yml
**Evidence:** —
**Reason:** —

## T10: 심사 자료와 출시 절차

**Status:** planned
**Depends:** T09
**Acceptance:** 소개/개인정보/지원/심사 노트/스크린샷 초안; 제출 gate 검증; 한계 명시
**Verify:** release-check CLI; 자료 검토
**Files:** docs/release/*, PrivacyPolicy.md, docs/APP_STORE_READINESS.md
**Evidence:** —
**Reason:** —

## T11: 운영 정보와 App Store 배포 검증

**Status:** planned
**Depends:** T10
**Acceptance:** 실제 공개 정책·지원 URL; 운영자/문의 정보; Connect 등록/배포 Validate 확인
**Verify:** 공개 URL HTTP 확인; Xcode Validate 결과; Connect 미제출 상태
**Files:** 운영 정보/계정 상태, docs/release/*
**Evidence:** —
**Reason:** —

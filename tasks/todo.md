# 출시 과업

상태: planned → active → done. 외부 조건이 필요하면 blocked. 관리: `python3 scripts/tasks.py --help`.

## T01: 저장소 과업 관리와 worktree

**Status:** done
**Depends:** None
**Acceptance:** 상태 원본·CLI·Git 템플릿을 준비하고 브랜치를 원격에 등록
**Verify:** task CLI check; git worktree list; remote branch 확인
**Files:** scripts/tasks.py, tasks/*, .github/*
**Evidence:** docs/qa/T01-tracker.md
**Reason:** —

## T02: 금액 의미와 후보 데이터

**Status:** done
**Depends:** T01
**Acceptance:** 상품 가격/할인액/잔액 분리; 모든 번호 후보 보존; 기존 데이터 유지
**Verify:** parser/persistence/migration 단위 테스트
**Files:** Models/*, Services/GifticonParser.swift, Services/PersistenceService.swift
**Evidence:** docs/qa/T02-models.md
**Reason:** —

## T03: 인식 실패 직접 등록

**Status:** done
**Depends:** T02
**Acceptance:** 바코드 실패에도 원본+직접 입력; 선택 후보와 번호 중복 검증; 취소 시 고아 파일 없음
**Verify:** manual import UI + persistence 테스트
**Files:** Views/ManualImportView.swift, Views/GifticonEditor.swift
**Evidence:** docs/qa/T03-registration.md
**Reason:** —

## T04: 기존 쿠폰 후보와 금액 수정

**Status:** done
**Depends:** T03
**Acceptance:** 후보 선택 가능; 교환권 가격과 잔액 분리; 차감 후 원금 수정 제한
**Verify:** editor/detail UI + balance 회귀 테스트
**Files:** Views/GifticonEditor.swift, Views/GifticonDetailView.swift
**Evidence:** docs/qa/T04-editor.md
**Reason:** —

## T05: 공유 저장 결과와 실패 큐

**Status:** done
**Depends:** T02
**Acceptance:** 공유 저장 실패 안내; 순차 제한 크기 처리; 앱 재시도 실패가 원본을 유실하지 않음
**Verify:** inbox/import 단위 테스트 + 공유 확장 빌드
**Files:** GifticonCollectorShare/ShareViewController.swift, Services/SharedImageInbox.swift, Services/SharedImportService.swift
**Evidence:** docs/qa/T05-sharing.md
**Reason:** —

## T06: 실패 큐 복구 화면

**Status:** done
**Depends:** T05,T03
**Acceptance:** 대기 항목 재시도/직접 입력/삭제; 앱 재진입 결과 표시; 중복 파일 정리
**Verify:** queue UI + duplicate/retry 테스트
**Files:** Views/RootView.swift, Views/GifticonListView.swift, Views/ManualImportView.swift
**Evidence:** docs/qa/T06-queue.md
**Reason:** —

## T07: 자동 찾기와 기존 원본 보존

**Status:** done
**Depends:** T02
**Acceptance:** 새 쿠폰 원본 복사 후 등록; 기존 Photos 참조 복사; 권한 상실 시 복사본 조회와 누락 복구 안내
**Verify:** archive persistence 테스트 + scan build
**Files:** Services/PhotoLibraryService.swift, ViewModels/ScanViewModel.swift, Services/SharedImportService.swift
**Evidence:** docs/qa/T07-originals.md
**Reason:** —

## T08: 만료 알림 예약과 갱신

**Status:** done
**Depends:** T04
**Acceptance:** 명시적 권한과 설정; 승인된 미사용 쿠폰만 예약; 수정/사용/삭제와 날짜 경계에서 갱신
**Verify:** notification plan 단위 테스트 + settings UI
**Files:** Services/NotificationService.swift, Services/PersistenceService.swift, Views/RootView.swift, Views/GifticonListView.swift
**Evidence:** docs/qa/T08-reminders.md
**Reason:** —

## T09: 출시 후보 회귀와 네이티브 배포

**Status:** blocked
**Depends:** T04,T06,T07,T08,T12,T17
**Acceptance:** 전체 자동 테스트 통과; iPhone/iPad QA 증거; Release Archive와 로컬 설치
**Verify:** xcodebuild test/archive; deploy-local; 결과 bundle
**Files:** Tests/*, UITests/*, scripts/*, project.yml
**Evidence:** docs/qa/T09-release.md
**Reason:** 전체 자동 회귀·Archive·iPhone 설치; iPad/최소 OS/Photos 호스트 및 권한·사진 삭제·저장 실패 실제 과업 검증 미완료

## T10: 심사 자료와 출시 절차

**Status:** blocked
**Depends:** T09
**Acceptance:** 소개/개인정보/지원/심사 노트/스크린샷 초안; 제출 gate 검증; 한계 명시
**Verify:** release-check CLI; 자료 검토
**Files:** docs/release/*, PrivacyPolicy.md, docs/APP_STORE_READINESS.md
**Evidence:** docs/release/RELEASE_RUNBOOK.md
**Reason:** 심사 자료 초안과 무효 입력 이미지 준비; T09 검증 및 제출 규격 iPhone/iPad 실제 화면 미완료

## T11: 운영 정보와 App Store 배포 검증

**Status:** blocked
**Depends:** T10
**Acceptance:** 실제 공개 정책·지원 URL; 운영자/문의 정보; Connect 등록/배포 Validate 확인
**Verify:** 공개 URL HTTP 확인; Xcode Validate 결과; Connect 미제출 상태
**Files:** 운영 정보/계정 상태, docs/release/*
**Evidence:** docs/APP_STORE_READINESS.md
**Reason:** 지원 이메일 반영; 운영자명·공개 정책/지원 URL·심사 연락처 미설정; App Store profile 생성 권한 부족, Connect/Validate 미확인

## T12: 중단된 원본 파일 저장 복구

**Status:** done
**Depends:** T06,T07
**Acceptance:** 파일 보관 후 DB 저장 전에 중단돼도 다음 실행에서 복구 목록 표시; 등록된 원본은 이동하지 않음; 반복 복구 안전
**Verify:** unreferenced archive 반례 테스트 + 전체 회귀
**Files:** Services/SharedImageInbox.swift, Services/SharedImportService.swift, Services/PersistenceService.swift
**Evidence:** docs/qa/T12-interrupted-save.md
**Reason:** —

## T13: 광고 수익화 명세와 과업

**Status:** done
**Depends:** T01
**Acceptance:** 로그인 없는 무료 앱의 AdMob 구조·위치·동의·출시와 수익 gate 구분
**Verify:** 공식 문서 확인; 명세 반증 검토
**Files:** docs/AD_MONETIZATION.md, tasks/*
**Evidence:** docs/AD_MONETIZATION.md
**Reason:** —

## T14: 광고 SDK와 동의·설정 안전장치

**Status:** done
**Depends:** T13
**Acceptance:** 정확한 SDK 버전 고정; UMP 이전 요청 없음; 기본 광고 꺼짐; 개인정보 설정과 오래된 완료 방지
**Verify:** 정책·설정·동의 반례 단위 테스트; 빌드
**Files:** Services/Advertising/*, project.yml
**Evidence:** docs/qa/T14-ad-consent.md
**Reason:** —

## T15: 보관함 배너와 실패 시 기능 유지

**Status:** done
**Depends:** T14
**Acceptance:** 보관함에서만 배너; 등록/검색/상세/스캔에서 제거; 실패 공간 없음
**Verify:** UI 회귀; Google 테스트 배너 렌더링
**Files:** Views/*, UITests/*
**Evidence:** docs/qa/T15-wallet-ad.md
**Reason:** —

## T16: 광고 개인정보와 출시 검사

**Status:** done
**Depends:** T14
**Acceptance:** SDK 데이터 고지; 실광고 ID·정책·동의·app-ads.txt 검사; 계정 없는 활성화 방지
**Verify:** 설정 검사 반례; release-check; 문서 검토
**Files:** scripts/*, PrivacyPolicy.md, docs/release/*
**Evidence:** docs/qa/T16-ad-release-gates.md
**Reason:** —

## T17: 광고 후보 네이티브 검증과 로컬 배포

**Status:** blocked
**Depends:** T15,T16
**Acceptance:** 전체 자동 회귀; Release Archive; 연결 기기 로컬 설치·실행과 결과 기록
**Verify:** xcodebuild test/archive; devicectl
**Files:** docs/qa/T17-ads.md, scripts/*
**Evidence:** docs/qa/T17-ads.md
**Reason:** 회귀·실제 테스트 배너·Release Archive·Simulator 설치 완료; iPhone 1.0(6) 설치 중 CoreDevice 연결 reset, 기기 재연결 필요

## T18: AdMob 실제 계정과 수익 개시

**Status:** blocked
**Depends:** T17
**Acceptance:** 게시자 지급 정보; 실제 앱/배너 ID; UMP; 공개 정책; app-ads.txt; Store 연결과 AdMob 준비 승인
**Verify:** 공개 파일과 실제 계정 상태 확인; 실광고 활성 후보 검증
**Files:** 운영 계정, docs/release/metadata.local.json
**Evidence:** docs/qa/T16-ad-release-gates.md
**Reason:** 실제 AdMob 앱/배너/게시자·지급 정보 미제공; UMP 실제 계정·공개 정책/웹사이트·app-ads.txt·Store 연결과 광고 준비 승인 미확인

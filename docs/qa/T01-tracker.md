# T01 검증

- worktree ../moa-con-release, 브랜치 feature/release-readiness 생성.
- `python3 scripts/tasks.py check`: 11 tasks valid.
- `git push -u origin feature/release-readiness`: 원격 브랜치 생성 성공.
- 원래 작업 폴더의 project.pbxproj/scheme 수정은 보존.
- 단일 상태 원본 tasks/todo.md, 상태 변경 CLI, 이력/계획, GitHub 과업/PR 템플릿 제공.

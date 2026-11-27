# Palbahngmiyine's Toolbox

LLM과 함께 일할 때 필요한 도구를 모아 두는 곳입니다. 에이전트가 읽고 따르는 지침인 스킬과, 프롬프트를 보내거나 에이전트가 도구를 쓰기 직전에 자동으로 실행되는 스크립트인 훅이 들어 있습니다.

| 경로 | 용도 |
|---|---|
| `skills/dolpa` | 작업 하나를 스펙부터 병합된 PR까지 적은 토큰으로 진행합니다. 작업은 스펙의 태스크, 이슈, 대화로 받은 요청 중 무엇이든 됩니다. 결정적 검사를 먼저 거치고 독립 리뷰는 한 번만 받습니다. |
| `skills/dolpa-swarm` | 큰 작업 하나를 작은 항목으로 나누고, 서로 겹치지 않는 항목들을 `dolpa`로 동시에 진행한 뒤 하나씩 병합합니다. |
| `skills/conventional-commit` | Conventional Commits 형식으로 커밋 메시지를 씁니다. |
| `skills/fork-pr` | fork에서 upstream으로 PR을 엽니다. |
| `skills/evening-socratic-journal` | 그날의 에이전트 세션을 문답을 거쳐 일기로 남깁니다. |
| `hooks/quiet-checks.sh` | 테스트·린트·빌드 출력을 로그 파일로 보내고 에이전트에게는 끝부분만 보여 줍니다. |
| `hooks/secret-guard.sh` | 토큰, 웹훅 주소, 개인 키가 들어 있는 프롬프트·셸 명령·파일 쓰기를 차단합니다. |
| `hooks/pr-explain.sh` | PR 설명에 변경 전후 구역, 전후 비교 표, 변경을 보여 주는 이미지나 영상, 동작 원리 설명, 경고 상자가 있는 엣지 케이스, 확인하지 못한 것이 없으면 `gh pr create`를 차단합니다. |

## 설치

스킬은 에이전트의 스킬 디렉터리에 링크합니다.

```bash
ln -s "$PWD/skills/dolpa" ~/.claude/skills/dolpa
```

`dolpa`와 `dolpa-swarm`은 수동 호출 전용입니다. 에이전트가 스스로 부르지 않으므로 `/dolpa <작업>`처럼 직접 입력합니다.

훅은 `~/.claude/settings.json`에 등록합니다. 경로는 이 저장소를 받은 위치로 바꿉니다.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "hooks": [{ "type": "command", "command": "/path/to/toolbox/hooks/secret-guard.sh" }] }
    ],
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "/path/to/toolbox/hooks/quiet-checks.sh" }] },
      { "matcher": "Bash|Write|Edit", "hooks": [{ "type": "command", "command": "/path/to/toolbox/hooks/secret-guard.sh" }] },
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "/path/to/toolbox/hooks/pr-explain.sh" }] }
    ]
  }
}
```

## 훅 설정

`quiet-checks.sh`는 인식한 검사 명령이 성공하면 마지막 5줄, 실패하면 마지막 80줄을 보여 주고 종료 상태와 로그 경로를 덧붙입니다. 줄 수는 `QUIET_CHECKS_OK_LINES`와 `QUIET_CHECKS_FAIL_LINES`로 바꿉니다. 명령 앞에 `QUIET_CHECKS=0`을 붙이면 그 명령은 손대지 않고 실행합니다.

`secret-guard.sh`는 임의의 문자열이 아니라 알려진 자격 증명 접두사만 검사합니다. 차단된 프롬프트는 모델로 전송되지 않지만 로컬 프롬프트 기록에는 남을 수 있으므로, 실제 값이었다면 교체해야 합니다. 끄려면 에이전트를 `SECRET_GUARD=0`으로 시작합니다.

`pr-explain.sh`는 `gh pr create`의 설명에서 여섯 가지를 찾습니다. 첫째는 줄 첫머리의 `## Before and after` 또는 `## 변경 전후` 제목입니다. 둘째는 전후 비교 표로, `Before`(또는 `변경 전`) 칸과 `After`(또는 `변경 후`) 칸이 나란히 있는 표의 행입니다. 셋째는 변경을 보여 주는 자료로, 본문의 이미지나 영상 또는 `--attach`로 올리는 파일입니다. `mermaid` 코드 블록만으로는 통과하지 않습니다. 넷째는 줄 첫머리의 `## How it works` 또는 `## 동작 원리` 제목입니다. 다섯째는 `## Edge cases` 또는 `## 엣지 케이스` 제목과 GitHub 경고 상자(`> [!WARNING]` 또는 `> [!CAUTION]`)이며, 경고할 사례가 없으면 제목 바로 아래에 `None`이나 `없음`이라고 씁니다. 여섯째는 `## Not verified` 또는 `## 확인하지 못한 것` 제목입니다. 명령에 직접 쓴 본문이 제목으로 시작하면 여는 따옴표 바로 뒤의 제목도 인정합니다. 설명은 명령에 직접 쓴 본문이나 `--body-file`로 넘긴 파일에서 읽습니다. `gh`가 명령 자리에 있을 때만 검사하므로, 커밋 메시지나 `echo` 안에 그 문구가 들어 있는 것은 막지 않습니다. `--web`으로 여는 PR, `gh pr edit`, 설명이 없는 `--help`와 `--dry-run`도 검사하지 않습니다. 끄려면 에이전트를 `PR_EXPLAIN=0`으로 시작합니다.

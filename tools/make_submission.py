"""제출용 ZIP 생성 스크립트.

사용법 (저장소 루트에서):
    python tools/make_submission.py mp1

구성:
    README.md, prompts_log.md, screenshots/   ← ZIP 최상위
    app/                                       ← git이 추적하는 앱 소스 전체
빌드 산출물(build/, .dart_tool/, .gradle/ 등)은 git이 추적하지 않으므로 들어가지 않는다.
커밋된 내용(HEAD)만 담으므로, 먼저 커밋한 뒤 실행한다.
"""

import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOP_LEVEL = ("README.md", "prompts_log.md")
EXCLUDE_PREFIX = ("screenshots/", "tools/")
MAX_SHOT_BYTES = 2 * 1024 * 1024
MAX_SHOTS = 12


def tracked_files() -> list[str]:
    out = subprocess.run(
        ["git", "ls-files", "-z"], cwd=ROOT, capture_output=True, check=True
    ).stdout.decode("utf-8")
    return [f for f in out.split("\0") if f]


def main() -> None:
    stage = sys.argv[1] if len(sys.argv) > 1 else "mp"
    dist = ROOT / "dist"
    dist.mkdir(exist_ok=True)
    target = dist / f"scheduly_2109_{stage}.zip"

    files = tracked_files()
    shots = sorted(f for f in files if f.startswith("screenshots/"))
    if len(shots) > MAX_SHOTS:
        sys.exit(f"스크린샷이 {len(shots)}장입니다 (최대 {MAX_SHOTS}장)")
    for s in shots:
        if (ROOT / s).stat().st_size > MAX_SHOT_BYTES:
            sys.exit(f"2MB 초과 스크린샷: {s}")

    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as zf:
        for f in files:
            src = ROOT / f
            if not src.is_file():
                continue
            if f in TOP_LEVEL or f.startswith("screenshots/"):
                zf.write(src, f)
            elif f == ".env.example":
                # 설정 키 목록은 최상위와 app/ 양쪽에 둔다 (실행 시에는 app/ 기준)
                zf.write(src, f)
                zf.write(src, f"app/{f}")
            elif not f.startswith(EXCLUDE_PREFIX):
                zf.write(src, f"app/{f}")

    print(f"생성: {target}  ({target.stat().st_size // 1024} KB, 스크린샷 {len(shots)}장)")


if __name__ == "__main__":
    main()

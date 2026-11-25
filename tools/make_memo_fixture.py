"""OCR 확인용 '종이 메모' 픽스처 이미지 생성 (개인정보 없음).

사용법 (저장소 루트에서):
    python tools/make_memo_fixture.py

결과: fixtures/memo_fixture.png  (fixtures/ 는 .gitignore — 제출하지 않음)
에뮬레이터로 보내기:
    adb push fixtures/memo_fixture.png /sdcard/Pictures/memo_fixture.png
    adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/memo_fixture.png
"""

import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "fixtures" / "memo_fixture.png"
FONT = "C:/Windows/Fonts/malgun.ttf"  # 맑은 고딕 (Windows 기본)

TITLE = "오늘 할 일"
LINES = [
    "- 우유 사기",
    "- 알고리즘 과제 제출",
    "- 도서관 책 반납",
    "- 운동 30분",
    "- Buy printer paper",
]


def main() -> None:
    random.seed(2109)
    w, h = 1200, 1500
    img = Image.new("RGB", (w, h), (252, 246, 222))  # 노란 메모지
    d = ImageDraw.Draw(img)

    # 메모지 줄
    for y in range(260, h - 80, 150):
        d.line([(70, y + 95), (w - 70, y + 95)], fill=(200, 210, 235), width=3)
    d.line([(150, 0), (150, h)], fill=(240, 170, 170), width=3)  # 왼쪽 여백선

    title_font = ImageFont.truetype(FONT, 88)
    font = ImageFont.truetype(FONT, 72)
    ink = (35, 45, 80)
    d.text((190, 90), TITLE, font=title_font, fill=ink)
    for i, line in enumerate(LINES):
        x = 190 + random.randint(-6, 6)
        y = 270 + i * 150 + random.randint(-4, 4)
        d.text((x, y), line, font=font, fill=ink)

    # 사진처럼 약간 기울이고 흐리게 + 배경(책상)
    img = img.rotate(-2.5, expand=True, fillcolor=(120, 95, 70))
    img = img.filter(ImageFilter.GaussianBlur(0.6))
    OUT.parent.mkdir(exist_ok=True)
    img.save(OUT)
    print(f"생성: {OUT}  ({img.size[0]}x{img.size[1]})")


if __name__ == "__main__":
    main()

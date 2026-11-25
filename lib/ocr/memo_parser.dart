/// OCR 결과(줄 목록)를 할 일 후보로 정리한다.
///
/// - 앞뒤 공백, 글머리표(-, •, ·, *, □, ☐, ☑, [ ], [x]), 번호(1. 1) ①)를 떼어 낸다
/// - 빈 줄, 1글자 줄, 숫자·기호만 있는 줄은 버린다
/// - 같은 내용은 한 번만 남긴다(대소문자·공백 무시)
/// - 너무 긴 줄은 100자로 자른다
List<String> extractCandidates(Iterable<String> lines) {
  final result = <String>[];
  final seen = <String>{};
  for (final raw in lines) {
    var t = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    t = t.replaceFirst(_prefix, '').trim();
    if (t.length < 2) continue;
    if (!RegExp(r'[0-9A-Za-z가-힣]').hasMatch(t)) continue;
    if (RegExp(r'^[\d\s.,:/\-]+$').hasMatch(t)) continue; // 날짜·쪽수만 있는 줄
    if (t.length > 100) t = t.substring(0, 100);
    final key = t.toLowerCase().replaceAll(' ', '');
    if (seen.add(key)) result.add(t);
  }
  return result;
}

final _prefix = RegExp(
  r'^(?:[-–—•·*▪◦□☐☑✓✔]+|\[\s?[xX✓]?\s?\]|\(?\d{1,2}[.)]|[①-⑳])\s*',
);

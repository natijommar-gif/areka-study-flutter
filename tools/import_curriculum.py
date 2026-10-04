#!/usr/bin/env python3
"""Read-only importer from New-copy-apk Kotlin curriculum to Flutter JSON assets.

The legacy source is only read. New generated assets are written under this Flutter project.
"""
from __future__ import annotations
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_LEGACY_ROOT = (
    PROJECT_ROOT.parent / 'New-copy-apk' / 'app' / 'src' / 'main' / 'java'
    / 'com' / 'areka' / 'app' / 'data' / 'repository'
)
DEFAULT_GEOGRAPHY_ROOT = Path.home() / 'upload'
OUT = PROJECT_ROOT / 'assets' / 'data'
LEGACY_QUIZ_FILES = ['CurriculumQuizzesPart1.kt', 'CurriculumQuizzesPart2.kt', 'CurriculumQuizzesPart3.kt']
UPGRADE_FILES = ['CurriculumDriveQuestionBank.kt', 'CurriculumHistoryQuizImport.kt']
FLASH_FILES = [f'CurriculumFlashcardsPart{i}.kt' for i in range(1, 5)]


def mask_non_code(source: str) -> str:
    """Replace Kotlin string/comment contents with spaces while preserving offsets."""
    out = list(source)
    i, n = 0, len(source)
    while i < n:
        if source.startswith('//', i):
            j = source.find('\n', i)
            j = n if j < 0 else j
            for k in range(i, j): out[k] = ' '
            i = j
        elif source.startswith('/*', i):
            depth, j = 1, i + 2
            while j < n and depth:
                if source.startswith('/*', j): depth += 1; j += 2
                elif source.startswith('*/', j): depth -= 1; j += 2
                else: j += 1
            for k in range(i, j):
                if source[k] != '\n': out[k] = ' '
            i = j
        elif source.startswith('"""', i):
            j = source.find('"""', i + 3)
            j = n if j < 0 else j + 3
            for k in range(i, j):
                if source[k] != '\n': out[k] = ' '
            i = j
        elif source[i] == '"':
            j, escaped = i + 1, False
            while j < n:
                if escaped: escaped = False
                elif source[j] == '\\': escaped = True
                elif source[j] == '"':
                    j += 1
                    break
                j += 1
            for k in range(i, j):
                if source[k] != '\n': out[k] = ' '
            i = j
        else:
            i += 1
    return ''.join(out)


def matching_paren(source: str, open_index: int) -> int:
    """Return exclusive close-paren offset with nested calls/strings/comments handled."""
    masked = mask_non_code(source)
    depth = 0
    for i in range(open_index, len(source)):
        if masked[i] == '(':
            depth += 1
        elif masked[i] == ')':
            depth -= 1
            if depth == 0:
                return i + 1
    raise ValueError(f'unclosed parenthesis at offset {open_index}')


def calls(source: str, name: str):
    mask = mask_non_code(source)
    pattern = re.compile(r'\b' + re.escape(name) + r'\s*\(')
    for match in pattern.finditer(mask):
        open_index = mask.find('(', match.start(), match.end())
        end = matching_paren(source, open_index)
        yield source[open_index + 1:end - 1]


def split_top(source: str, separator: str = ',') -> list[str]:
    mask = mask_non_code(source)
    result, last = [], 0
    stack = []
    pairs = {')': '(', ']': '[', '}': '{'}
    for i, char in enumerate(mask):
        if char in '([{': stack.append(char)
        elif char in ')]}':
            if stack and stack[-1] == pairs[char]: stack.pop()
        elif char == separator and not stack:
            result.append(source[last:i].strip()); last = i + 1
    tail = source[last:].strip()
    if tail: result.append(tail)
    return result


def named_fields(body: str) -> dict[str, str]:
    fields = {}
    for chunk in split_top(body):
        mask = mask_non_code(chunk)
        # Do not let the masked string contents (spaces) get consumed as whitespace.
        match = re.match(r'\s*([A-Za-z_]\w*)\s*=', mask)
        if match:
            equals = mask.find('=', match.start(), match.end())
            fields[match.group(1)] = chunk[equals + 1:].strip()
    return fields


def decode_string(value: str) -> str:
    value = value.strip()
    if value.startswith('"""') and value.endswith('"""'):
        return value[3:-3]
    if not (value.startswith('"') and value.endswith('"')):
        raise ValueError('Expected Kotlin string literal: ' + value[:80])
    token = value[:-1] + '"'
    token = token.replace(r'\$', '$')
    return json.loads(token)


def scalar(fields: dict[str, str], key: str, default=None):
    value = fields.get(key)
    if value is None: return default
    value = value.strip()
    if value.startswith('"') or value.startswith('"""'): return decode_string(value)
    return value


def option_list(value: str) -> list[dict]:
    if value.strip().startswith('emptyList'): return []
    parsed = []
    for body in calls(value, 'QuestionOption'):
        args = split_top(body)
        if len(args) >= 2:
            parsed.append({'key': decode_string(args[0]), 'text': decode_string(args[1])})
    return parsed


def parse_quizzes(path: Path) -> list[dict]:
    text = path.read_text(encoding='utf-8')
    out = []
    for body in calls(text, 'Quiz'):
        f = named_fields(body)
        if 'id' not in f or 'questions' not in f: continue
        quiz = {
            'id': scalar(f, 'id'), 'title': scalar(f, 'title', ''),
            'subject': scalar(f, 'subject', ''), 'subjectId': scalar(f, 'subjectId', ''),
            'unitId': scalar(f, 'unitId', ''), 'durationMinutes': int(scalar(f, 'durationMinutes', '10')),
            'questions': []
        }
        for qbody in calls(f['questions'], 'Question'):
            q = named_fields(qbody)
            if 'text' not in q or 'correctOptionId' not in q: continue
            options = option_list(q.get('options', 'emptyList()'))
            kind = 'fill_in' if 'FILL_IN_THE_BLANK' in q.get('type', '') or not options else 'multiple_choice'
            quiz['questions'].append({
                'id': str(scalar(q, 'id', len(quiz['questions']) + 1)),
                'number': int(scalar(q, 'questionNumber', str(len(quiz['questions']) + 1))),
                'text': scalar(q, 'text', ''), 'options': options,
                'answerKey': scalar(q, 'correctOptionId', ''),
                'explanation': scalar(q, 'explanation', ''), 'type': kind
            })
        if quiz['questions']:
            out.append(quiz)
    return out


def parse_flashcards(paths: list[Path]) -> list[dict]:
    result = []
    for path in paths:
        for body in calls(path.read_text(encoding='utf-8'), 'Flashcard'):
            args = split_top(body)
            if len(args) < 5: continue
            strings = [decode_string(arg) for arg in args[:5]]
            result.append({'id': strings[0], 'subjectId': strings[1], 'unitId': strings[2], 'front': strings[3], 'back': strings[4]})
    return result


def import_geography(upload_dir: Path):
    q_doc = json.loads((upload_dir / '0ab95a336356ab3606afdc2c_question-bank.json').read_text(encoding='utf-8'))
    f_doc = json.loads((upload_dir / '4a813747bb74182dd547c2d1_flashcards.json').read_text(encoding='utf-8'))
    q_by_unit, c_by_unit = defaultdict(list), defaultdict(list)
    meta = q_doc['metadata']
    for q in q_doc['questions']:
        unit = int(q['unit']); unit_id = f'geo_verified_u{unit}'
        q_by_unit[unit].append({
            'id': q['id'], 'number': len(q_by_unit[unit]) + 1, 'text': q['prompt'],
            'options': [{'key': o['key'], 'text': o['text']} for o in q['options']],
            'answerKey': q['answerKey'], 'answerText': q['answerText'],
            'explanation': q['explanation'], 'type': 'multiple_choice',
            'section': q.get('section'), 'sectionTitle': q.get('sectionTitle'),
            'printedPages': q.get('printedPages', []), 'pdfPages': q.get('pdfPages', []),
            'sourceTitle': meta.get('textbook'), 'sourcePublisher': meta.get('publisher'),
            'sourceYear': meta.get('year'), 'sourceSha256': meta.get('sourceSha256'),
            'printedToPdfOffset': meta.get('printedToPdfOffset')
        })
    for c in f_doc['flashcards']:
        unit = int(c['unit']); unit_id = f'geo_verified_u{unit}'
        c_by_unit[unit].append({
            'id': c['id'], 'subjectId': 'geography', 'unitId': unit_id,
            'front': c['front'], 'back': c['back'], 'explanation': c.get('explanation', ''),
            'unit': unit, 'unitTitle': c['unitTitle'], 'section': c.get('section'),
            'sectionTitle': c.get('sectionTitle'), 'printedPages': c.get('printedPages', []),
            'pdfPages': c.get('pdfPages', []), 'sourceTitle': meta.get('textbook'),
            'sourcePublisher': meta.get('publisher'), 'sourceYear': meta.get('year'),
            'sourceSha256': meta.get('sourceSha256'), 'printedToPdfOffset': meta.get('printedToPdfOffset')
        })
    quizzes = []
    for unit, questions in sorted(q_by_unit.items()):
        title = questions[0].get('unitTitle') if 'unitTitle' in questions[0] else q_doc['metadata']['unitTitles'][str(unit)]
        quizzes.append({'id': f'geo_verified_quiz_{unit}', 'title': f'Geography · Unit {unit}: {title}',
            'subject': 'Geography', 'subjectId': 'geography', 'unitId': f'geo_verified_u{unit}',
            'durationMinutes': 10, 'verifiedPacket': True, 'questions': questions})
        for card in c_by_unit[unit]: card['unitTitle'] = title
    return quizzes, [card for unit in sorted(c_by_unit) for card in c_by_unit[unit]], q_doc['metadata']


def main(argv: list[str] | None = None):
    import argparse

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--legacy-data-dir', type=Path, default=DEFAULT_LEGACY_ROOT,
        help='directory containing the original and replacement Kotlin curriculum files',
    )
    parser.add_argument(
        '--geography-data-dir', type=Path, default=DEFAULT_GEOGRAPHY_ROOT,
        help='directory containing the validated Geography question/card JSON files',
    )
    args = parser.parse_args(argv)

    legacy = []
    for name in LEGACY_QUIZ_FILES:
        legacy.extend(parse_quizzes(args.legacy_data_dir / name))
    if len(legacy) != 66:
        raise SystemExit(f'Expected 66 base quiz units, parsed {len(legacy)}')
    chosen = {q['unitId']: q for q in legacy}
    if len(chosen) != len(legacy): raise SystemExit('Duplicate legacy unit IDs')
    overrides = []
    for name in UPGRADE_FILES:
        overrides.extend(parse_quizzes(args.legacy_data_dir / name))
    for q in overrides:
        if q['unitId'] not in chosen:
            raise SystemExit(f'Upgrade does not map to an existing unit: {q["unitId"]}')
        chosen[q['unitId']] = q
    base_quizzes = list(chosen.values())
    base_questions = [q for quiz in base_quizzes for q in quiz['questions']]
    types = Counter(q['type'] for q in base_questions)
    subjects = {quiz['subject'] for quiz in base_quizzes}
    if len(base_quizzes) != 66 or len(subjects) != 9:
        raise SystemExit(f'Base structure mismatch: quizzes={len(base_quizzes)}, subjects={len(subjects)}')
    if len(base_questions) != 1776 or types != Counter({'multiple_choice': 1218, 'fill_in': 558}):
        raise SystemExit(f'Base question count mismatch: total={len(base_questions)}, types={dict(types)}')
    legacy_cards = parse_flashcards(
        [args.legacy_data_dir / name for name in FLASH_FILES]
    )
    if len(legacy_cards) != 462: raise SystemExit(f'Expected 462 original flashcards, parsed {len(legacy_cards)}')

    geo_quizzes, geo_cards, geo_meta = import_geography(args.geography_data_dir)
    if len(geo_quizzes) != 8 or sum(map(lambda q: len(q['questions']), geo_quizzes)) != 48 or len(geo_cards) != 64:
        raise SystemExit('The separately validated Geography packet did not match expected counts')
    # Geography is an additional verified module inside the existing Geography subject.
    quizzes = sorted(base_quizzes + geo_quizzes, key=lambda q: (q['subject'].casefold(), q['unitId']))
    cards = legacy_cards + geo_cards
    questions = [q for quiz in quizzes for q in quiz['questions']]
    metadata = {
        'appContentVersion': 1,
        'sourceNote': 'Offline study data imported from the verified Grade 10 curriculum bank; citations are retained on the separate Geography textbook packet.',
        'originalSubjectCount': len(subjects), 'originalQuizCount': len(base_quizzes),
        'originalQuestionCount': len(base_questions), 'originalMultipleChoiceCount': types['multiple_choice'],
        'originalFillInCount': types['fill_in'], 'originalFlashcardCount': len(legacy_cards),
        'additionalGeographyQuizCount': len(geo_quizzes), 'additionalGeographyQuestionCount': 48,
        'additionalGeographyFlashcardCount': len(geo_cards),
        'totalQuizCount': len(quizzes), 'totalQuestionCount': len(questions), 'totalFlashcardCount': len(cards),
        'geographyTextbook': {k: geo_meta[k] for k in ['textbook', 'publisher', 'year', 'sourceSha256', 'printedToPdfOffset', 'unitTitles'] if k in geo_meta},
        'geographyNote': 'Unit 5 RDI band discrepancy is disclosed in that item’s explanation and the accompanying source report.'
    }
    payload = {'metadata': metadata, 'quizzes': quizzes, 'flashcards': cards}
    OUT.mkdir(parents=True, exist_ok=True)
    target = OUT / 'curriculum.json'
    target.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    report = {
        'originalSubjects': sorted(subjects), 'originalQuizCount': len(base_quizzes),
        'originalQuestionCount': len(base_questions), 'originalQuestionTypes': dict(types),
        'originalFlashcardCount': len(legacy_cards), 'additionalGeographyQuizCount': len(geo_quizzes),
        'additionalGeographyQuestionCount': 48, 'additionalGeographyFlashcardCount': 64,
        'finalQuizCount': len(quizzes), 'finalQuestionCount': len(questions), 'finalFlashcardCount': len(cards),
        'perSubject': {s: sum(1 for q in quizzes if q['subject'] == s) for s in sorted({q['subject'] for q in quizzes})},
        'assetBytes': target.stat().st_size
    }
    (OUT / 'import-report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()

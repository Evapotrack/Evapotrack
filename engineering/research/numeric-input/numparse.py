# Reference for NumericInput.parse (Swift). Locale data: (decimal, grouping).
LOCALES = {'en_US': ('.', ','), 'es_ES': (',', '.'), 'de_DE': (',', '.'), 'fr_FR': (',', ' '), 'pt_BR': (',', '.'), 'es_MX': ('.', ',')}
SPACES = {' ', ' ', ' ', ' ', "'", '’'}

def digits(s): return len(s) > 0 and all(c in '0123456789' for c in s)

def grouped_ok(int_part, sep):
    """int_part like '1.234.567' (no sign). First group 1-3 digits not starting
    with 0, following groups exactly 3 digits."""
    groups = int_part.split(sep)
    if len(groups) < 2: return False
    first = groups[0]
    if not (digits(first) and 1 <= len(first) <= 3 and first[0] != '0'): return False
    return all(digits(g) and len(g) == 3 for g in groups[1:])

def parse(text, loc):
    dec_sep, grp_sep = LOCALES[loc]
    s = text.strip()
    if not s: return None
    s = s.replace('−', '-')
    sign = ''
    if s[0] in '+-': sign, s = s[0], s[1:]
    s = ''.join(c for c in s if c not in SPACES)
    if not s: return None
    dots, commas = s.count('.'), s.count(',')
    if dots and commas:
        dec = '.' if s.rfind('.') > s.rfind(',') else ','
        grp = ',' if dec == '.' else '.'
        if s.count(dec) != 1: return None
        int_part, frac = s.split(dec)
        if not digits(frac): return None
        if not grouped_ok(int_part, grp): return None
        normalized = int_part.replace(grp, '') + '.' + frac
    elif dots or commas:
        sep = '.' if dots else ','
        count = dots or commas
        if count > 1:
            if not grouped_ok(s, sep): return None
            normalized = s.replace(sep, '')
        else:
            int_part, frac = s.split(sep)
            is_locale_grouping = sep == grp_sep and sep != dec_sep
            if is_locale_grouping and grouped_ok(s, sep):
                normalized = int_part + frac
            else:
                if not (int_part == '' or digits(int_part)) or not (frac == '' or digits(frac)): return None
                if int_part == '' and frac == '': return None
                normalized = (int_part or '0') + '.' + (frac or '0')
    else:
        if not digits(s): return None
        normalized = s
    v = float(sign + normalized)
    return v

tests = [
 # (input, locale, expected)
 ('1.5', 'en_US', 1.5), ('1,5', 'en_US', 1.5), ('1,500', 'en_US', 1500.0), ('0,250', 'en_US', 0.25), ('1,234.5', 'en_US', 1234.5),
 ('1,5', 'es_ES', 1.5), ('1.5', 'es_ES', 1.5), ('1.500', 'es_ES', 1500.0), ('1.234,5', 'es_ES', 1234.5), ('0,25', 'es_ES', 0.25),
 ('1,5', 'de_DE', 1.5), ('2.000,75', 'de_DE', 2000.75), ('1.234.567', 'de_DE', 1234567.0),
 ('1,5', 'fr_FR', 1.5), ('1 234,5', 'fr_FR', 1234.5), ('1 234,5', 'fr_FR', 1234.5), ('1.5', 'fr_FR', 1.5),
 ('1,5', 'pt_BR', 1.5), ('1.234,56', 'pt_BR', 1234.56),
 ('  2 ', 'en_US', 2.0), ('.5', 'en_US', 0.5), (',5', 'es_ES', 0.5), ('5.', 'en_US', 5.0), ('-1,5', 'es_ES', -1.5), ('−1.5', 'en_US', -1.5),
 ('', 'en_US', None), ('   ', 'en_US', None), ('abc', 'en_US', None), ('1..2', 'en_US', None), ('1,2,3', 'en_US', None),
 ('1e3', 'en_US', None), ('nan', 'en_US', None), ('inf', 'en_US', None), ('0x10', 'en_US', None), ('.', 'en_US', None),
 ('1.2.3', 'de_DE', None), ('1,234,5', 'en_US', None), ('12,34.5', 'en_US', None), ('+2', 'en_US', 2.0), ('--2', 'en_US', None),
]
bad = 0
for inp, loc, exp in tests:
    got = parse(inp, loc)
    ok = (got is None and exp is None) or (got is not None and exp is not None and abs(got - exp) < 1e-12)
    if not ok:
        bad += 1; print('FAIL', repr(inp), loc, 'got', got, 'expected', exp)
print(len(tests), 'cases,', bad, 'failures')

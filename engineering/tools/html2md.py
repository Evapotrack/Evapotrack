# Converts the review page (known structure) to plain GitHub-flavored Markdown.
import re, sys
from html.parser import HTMLParser

VOID = {'link', 'meta', 'br', 'img', 'hr', 'input', 'source', 'wbr'}
SKIP = {'title', 'style', 'link', 'nav', 'script', 'meta'}

class Node:
    def __init__(self, tag, attrs=None, parent=None):
        self.tag, self.attrs, self.children, self.parent = tag, dict(attrs or {}), [], parent
    def cls(self):
        return (self.attrs.get('class') or '').split()
    def kids(self, *tags):
        return [c for c in self.children if isinstance(c, Node) and (not tags or c.tag in tags)]

class Builder(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = Node('root'); self.cur = self.root
    def handle_starttag(self, tag, attrs):
        n = Node(tag, attrs, self.cur); self.cur.children.append(n)
        if tag not in VOID: self.cur = n
    def handle_startendtag(self, tag, attrs):
        self.cur.children.append(Node(tag, attrs, self.cur))
    def handle_endtag(self, tag):
        if tag in VOID: return
        n = self.cur
        while n is not self.root and n.tag != tag: n = n.parent
        if n is not self.root: self.cur = n.parent
    def handle_data(self, data):
        self.cur.children.append(data)

def norm(s): return re.sub(r'\s+', ' ', s).strip()
def text(n): return ''.join(c if isinstance(c, str) else text(c) for c in n.children)
def find(n, tag, cls=None):
    for c in n.kids():
        if c.tag == tag and (cls is None or cls in c.cls()): return c
        r = find(c, tag, cls)
        if r: return r
    return None
def find_all(n, tag):
    out = []
    for c in n.kids():
        if c.tag == tag: out.append(c)
        out.extend(find_all(c, tag))
    return out

def inline(children):
    return ''.join(c if isinstance(c, str) else inline_node(c) for c in children)

def inline_node(n):
    t, cl = n.tag, n.cls()
    if t in SKIP: return ''
    if t == 'span' and 'tag' in cl:
        label = {'fact': 'FACT', 'finding': 'FINDING', 'rec': 'RECOMMENDATION'}[[c for c in cl if c != 'tag'][0]]
        return f' **[{label}]** '
    if t == 'span' and ('sev' in cl or 'v' in cl): return ' [' + norm(text(n)) + '] '
    if t == 'span' and 'id' in cl: return ' ' + norm(text(n)) + ': '
    if t in ('strong', 'b'):
        inner = norm(inline(n.children)); return f'**{inner}**' if inner else ''
    if t in ('em', 'i'):
        inner = norm(inline(n.children)); return f'*{inner}*' if inner else ''
    if t == 'code':
        s = norm(text(n)); tick = '``' if '`' in s else '`'; return f'{tick}{s}{tick}'
    if t == 'a':
        inner = norm(inline(n.children)); href = n.attrs.get('href', '')
        return inner if (not href or href.startswith('#')) else f'[{inner}]({href})'
    if t == 'br': return ' '
    return inline(n.children)

def item_md(label_prefix, node, level):
    """One list item: inline content on the bullet line, nested lists indented 4 spaces."""
    parts, nested = [], []
    for c in node.children:
        if isinstance(c, Node) and c.tag in ('ul', 'ol'): nested.append(list_md(c, level + 1))
        else: parts.append(c if isinstance(c, str) else inline_node(c))
    lines = ['    ' * level + label_prefix + norm(''.join(parts))]
    lines.extend(nested)
    return lines

def list_md(n, level=0):
    lines = []
    for i, li in enumerate(n.kids('li'), 1):
        lines.extend(item_md(f'{i}. ' if n.tag == 'ol' else '- ', li, level))
    return '\n'.join(lines)

def table_md(t):
    rows = []
    for tr in find_all(t, 'tr'):
        cells = []
        for c in tr.kids('td', 'th'):
            cells.append(norm(inline(c.children)).replace('|', '\\|'))
            cells.extend([''] * (int(c.attrs.get('colspan', 1)) - 1))
        rows.append(cells)
    ncol = max(len(r) for r in rows)
    rows = [r + [''] * (ncol - len(r)) for r in rows]
    fmt = lambda r: '| ' + ' | '.join(r) + ' |'
    return '\n'.join([fmt(rows[0]), fmt(['---'] * ncol)] + [fmt(r) for r in rows[1:]])

def finding_md(n, out):
    out.append('#### ' + norm(inline(n.kids('h4')[0].children)))
    dl = n.kids('dl')[0]; lines = []; label = None
    for c in dl.kids('dt', 'dd'):
        if c.tag == 'dt': label = norm(inline(c.children))
        else: lines.extend(item_md(f'- **{label}:** ', c, 0))
    out.append('\n'.join(lines))

def block(n, out):
    t, cl = n.tag, n.cls()
    if t in SKIP: return
    if t == 'header':
        out.append('# ' + norm(inline(find(n, 'h1').children)))
        out.append('*' + norm(inline(find(n, 'p', 'eyebrow').children)) + '*')
        out.append(' · '.join(norm(inline(s.children)) for s in find(n, 'p', 'meta').kids('span')))
        return
    if t in ('h1', 'h2', 'h3', 'h4'):
        out.append('#' * int(t[1]) + ' ' + norm(inline(n.children))); return
    if t == 'p':
        s = norm(inline(n.children))
        if s: out.append(s)
        return
    if t in ('ul', 'ol'): out.append(list_md(n)); return
    if t == 'pre': out.append('```\n' + text(n).strip('\n') + '\n```'); return
    if t == 'table': out.append(table_md(n)); return
    if t == 'div' and 'finding' in cl: finding_md(n, out); return
    if t == 'div' and 'summary-grid' in cl:
        out.append('\n'.join(f"- **{norm(text(d.kids('b')[0]))}** {norm(text(d.kids('span')[0]))}" for d in n.kids('div')))
        return
    for c in n.children:
        if isinstance(c, Node): block(c, out)
        elif c.strip(): out.append(norm(c))

b = Builder(); b.feed(open(sys.argv[1], encoding='utf-8').read())
out = []
block(b.root, out)
open(sys.argv[2], 'w', encoding='utf-8').write('\n\n'.join(out).rstrip() + '\n')

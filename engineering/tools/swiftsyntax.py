# Syntax-only check of Swift files with tree-sitter (no type checking).
import sys, tree_sitter_swift as ts
from tree_sitter import Language, Parser
parser = Parser(Language(ts.language()))
def errors(node, out):
    if node.type == 'ERROR' or node.is_missing:
        out.append(node)
    for c in node.children:
        errors(c, out)
bad = 0
for path in sys.argv[1:]:
    src = open(path, 'rb').read()
    tree = parser.parse(src)
    errs = []
    errors(tree.root_node, errs)
    if errs:
        bad += 1
        for e in errs[:5]:
            line = e.start_point[0] + 1
            text = src.splitlines()[e.start_point[0]].decode(errors='replace').strip()
            kind = 'MISSING ' + e.type if e.is_missing else 'ERROR'
            print(f'{path}:{line}: {kind}: {text[:110]}')
print(f'{len(sys.argv) - 1} files checked, {bad} with syntax errors')

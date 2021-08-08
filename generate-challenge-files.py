import os
from glob import glob
import re


def parse_md_file(fname):
    # Note: parser_state would be better as an object
    #       but works for now...
    ret = dict()
    parser_state = ''
    code = []
    with open(fname, 'r') as fd:
        for line in fd:
            line = line.rstrip('\n')
            if len(line) == 0:
                continue
            if line.startswith("---") and parser_state != "meta":
                # meta start
                parser_state = "meta"
                ret['meta'] = dict()
                continue
            if line.startswith("---") and parser_state == 'meta':
                # meta end
                parser_state = ''
                continue
            if parser_state == "meta":
                # parse meta k/v pairs
                k, v = line.split(':')
                v = v[1:]
                ret['meta'][k] = v
                continue
            if line.startswith('{{< code'):
                # code start
                parser_state = 'code'
                code_title = ''
                for entry in line.split(' '):
                    if entry.startswith('title='):
                        code_title = entry.split('=')[1]\
                                          .strip('"')\
                                          .rstrip('"')\
                                          .lower()
                        break
                parser_state += ":"+code_title
                continue
            if line.startswith('{{< /code'):
                # code end
                title = parser_state.split(':')[1]
                ret[title] = "\n".join(code)
                code = []
                parser_state = ''
                continue
            if parser_state.startswith('code:'):
                # record code lines
                code.append(line)
    return ret

def is_sane_fname(fname):
    return re.match(r'^[a-zA-Z0-9_\-]+$', fname) is not None

def is_sane_md(md):
    checks = [is_sane_fname(md['meta']['title'])]
    for k in md.keys():
        checks.append(is_sane_fname(k))
    # at least three entries: meta, challenge, solution
    # even if solution is empty
    checks.append(len(md.keys()) >= 3)
    return False not in checks

def dump_to_files(md):
    assert(is_sane_md(md))

dump_to_files(parse_md_file("content/vcdb/rips-38.md"))

import os
from glob import glob

def parse_org_file(fname):
    ret = dict()
    parser_mode = ''
    code = []
    solution = []
    with open(fname, 'r') as fd:
        for line in fd:
            line = line.rstrip('\n')
            if line.startswith(":ROAM_REFS:"):
                ret['ref'] = line.split(' ')[1]
                continue
            if line.startswith("#+title:"):
                ret['title'] = line.split(' ')[1]
                continue
            if line.startswith("#+filetags:"):
                ret['tags'] = [tag for tag in line.split(' ')[1].split(':') if tag != 'vcdb' and len(tag) != 0]
                continue
            if line.startswith("* Code"):
                parser_mode = "code"
                continue
            if line.startswith("* Solution"):
                parser_mode = "solution"
                continue
            if line.startswith("#+begin_src"):
                parser_mode = "%s_%s"%(parser_mode, line.split(' ')[1])
                if parser_mode.startswith('code'):
                    code.append(parser_mode.split('_')[1])
                elif parser_mode.startswith('solution'):
                    solution.append(parser_mode.split('_')[1])
                continue
            if parser_mode.startswith('code'):
                if line.startswith('#+end_src'):
                    parser_mode = ''
                    continue
                code.append(line)
            if parser_mode.startswith('solution'):
                if line.startswith('#+end_src'):
                    parser_mode = ''
                    continue
                solution.append(line)
           
    ret['code'] = code
    ret['solution'] = solution
            
    return ret
#print("\n".join(parse_org_file("vcdb/20210802230817-rips-38.org")['code']))
def convert_org_to_md(fname):
    org = parse_org_file(fname)
    md = ['---',
          '',
          'title: ' + org['title'],
          'author: raxjs',
          'tags: [' + ", ".join(org['tags']) + ']',
          '',
          '---',
          '',
          '$DESCRIPTION',
          '',
          '<!--more-->',
          "{{< reference src=\"%s\" >}}"%(org['ref']),
          '',
          '# Code',
          '{{< code language="%s"  title="Challenge" expand="Show" collapse="Hide" isCollapsed="false" >}}'%(org["code"][0]),
          ]
    md += org['code'][1:]
    md += ['{{< /code >}}',
           '',
           '# Solution',
           '{{< code language="%s" highlight="" title="Solution" expand="Show" collapse="Hide" isCollapsed="true" >}}'%(org["solution"][0]),
           ]
    md += org['solution'][1:]
    md += ['{{< /code >}}']
    return "\n".join(md)


#print(convert_org_to_md("vcdb/20210802230817-rips-38.org"))
for f in glob("vcdb/*.org"):
    md = convert_org_to_md(f)
    org = parse_org_file(f)
    out_file = os.path.join('tmp', org['title'] + '.md')
    with open(out_file, 'w') as fd:
        fd.write(md)


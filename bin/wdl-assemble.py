#!/usr/bin/env python3

import argparse
import re
import sys
import os

pr = argparse.ArgumentParser("Assemble WDL file from a workflow file")
pr.add_argument("workflow", help="workflow file")

argv = pr.parse_args()
out = sys.stdout

pattern = re.compile(r'^\s*include\s+([A-Za-z_/:,.]+)$')

with open(argv.workflow) as inf:
    for line in inf:
        m = pattern.match(line)
        if m:
            include_file = m.group(1)
            if not os.path.exists(include_file):
                sys.stderr.write("Error: include file '%s' does not exist".format(include_file))
            with open(include_file) as f:
                out.write(f.read() + '\n')
        else:
            out.write(line)


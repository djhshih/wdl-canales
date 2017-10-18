#!/usr/bin/env python

# requires python2 or python3

import argparse
import re
import sys
import os

pr = argparse.ArgumentParser("Assemble WDL file from a workflow file")
pr.add_argument("workflow", help="workflow file")

argv = pr.parse_args()
out = sys.stdout

workflow_fpath = argv.workflow
pattern = re.compile(r'^\s*include\s+([A-Za-z_/:,.]+)$')

with open(workflow_fpath) as inf:
    for line in inf:
        m = pattern.match(line)
        if m:
            include_fname = m.group(1)
            include_fpath = os.path.join(os.path.dirname(workflow_fpath), include_fname)
            if not os.path.exists(include_fpath):
                raise RuntimeError("Include file '%s' does not exist".format(include_fpath))
            with open(include_fpath) as f:
                out.write(f.read() + '\n')
        else:
            out.write(line)


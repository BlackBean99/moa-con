#!/usr/bin/env python3
"""Repository-local task tracker. tasks/todo.md is the only source of status."""
import argparse
import datetime
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FILE = ROOT / 'tasks/todo.md'
parser = argparse.ArgumentParser()
parser.add_argument('command', choices=['list', 'next', 'check', 'start', 'done', 'block'])
parser.add_argument('id', nargs='?')
parser.add_argument('--evidence')
parser.add_argument('--reason')
args = parser.parse_args()
text = FILE.read_text()
blocks = re.split(r'(?=^## T\d+:)', text, flags=re.M)[1:]
tasks = {}
for block in blocks:
    key, title = re.match(r'## (T\d+): (.+)', block).groups()
    fields = dict(re.findall(r'^\*\*(\w+):\*\* (.+)$', block, re.M))
    tasks[key] = (title, fields, block)

def dependencies(fields):
    return [] if fields['Depends'] == 'None' else fields['Depends'].split(',')

for key, (_, fields, _) in tasks.items():
    assert fields['Status'] in ['planned', 'active', 'done', 'blocked'], key
    assert all(dep in tasks for dep in dependencies(fields)), key
    if fields['Status'] == 'done':
        assert fields['Evidence'] != '—', f'{key}: missing evidence'
        assert (ROOT / fields['Evidence']).exists(), f'{key}: evidence does not exist'
        assert all(tasks[d][1]['Status'] == 'done' for d in dependencies(fields)), f'{key}: dependency incomplete'
    if fields['Status'] == 'blocked':
        assert fields['Reason'] != '—', f'{key}: missing blocker'

if args.command in ['list', 'next', 'check']:
    for key, (title, fields, _) in tasks.items():
        ready = all(tasks[d][1]['Status'] == 'done' for d in dependencies(fields))
        if args.command == 'list' or (args.command == 'next' and ready and fields['Status'] in ['planned', 'active']):
            print(f"{key} {fields['Status']:7} {title}")
    if args.command == 'check': print(f'{len(tasks)} tasks valid')
else:
    if args.id not in tasks: parser.error('Choose a valid task ID')
    title, fields, block = tasks[args.id]
    status = {'start': 'active', 'done': 'done', 'block': 'blocked'}[args.command]
    if status != 'blocked' and not all(tasks[d][1]['Status'] == 'done' for d in dependencies(fields)):
        parser.error('Complete dependencies first')
    changes = {'Status': status, 'Reason': args.reason or '—'}
    if status == 'done':
        if not args.evidence or not (ROOT / args.evidence).exists(): parser.error('Provide an existing evidence file')
        changes['Evidence'] = args.evidence
    if status == 'blocked' and not args.reason: parser.error('Provide the blocking reason')
    if status == 'blocked' and args.evidence:
        if not (ROOT / args.evidence).exists(): parser.error('Evidence file does not exist')
        changes['Evidence'] = args.evidence
    updated = block
    for field, value in changes.items():
        if '\n' in value: parser.error('Values must be one line')
        updated = re.sub(rf'^\*\*{field}:\*\* .+$', lambda _: f'**{field}:** {value}', updated, flags=re.M)
    FILE.write_text(text.replace(block, updated, 1))
    with (ROOT / 'tasks/events.md').open('a') as log:
        log.write(f"- {datetime.datetime.now().astimezone().isoformat(timespec='seconds')} {args.id}: {status}; {args.evidence or args.reason or title}\n")
    print(f'{args.id}: {status}')

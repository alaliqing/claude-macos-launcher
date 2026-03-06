#!/usr/bin/env python3
"""
Generates the "Open Claude with File" Automator workflow
"""
import plistlib
import uuid
import os
import sys


def create_workflow(script_content):
    """Create the workflow plist structure"""
    contents_dir = os.path.expanduser('~/Library/Services/Open Claude with File.workflow/Contents')

    # Remove existing workflow
    workflow_dir = os.path.dirname(contents_dir)
    if os.path.exists(workflow_dir):
        import shutil
        shutil.rmtree(workflow_dir)

    os.makedirs(contents_dir, exist_ok=True)

    # Create Info.plist
    info_plist = {
        'NSServices': [{
            'NSMenuItem': {'default': 'Open Claude with File'},
            'NSMessage': 'runWorkflowAsService',
            'NSRequiredContext': {'NSApplicationIdentifier': 'com.apple.finder'},
            'NSSendFileTypes': ['public.item', 'public.folder']
        }]
    }

    with open(os.path.join(contents_dir, 'Info.plist'), 'wb') as f:
        plistlib.dump(info_plist, f)

    # Create document.wflow
    doc = {
        'AMApplicationBuild': '523',
        'AMApplicationVersion': '2.10',
        'AMDocumentVersion': '2',
        'actions': [{
            'action': {
                'AMAccepts': {'Container': 'List', 'Optional': True, 'Types': ['com.apple.cocoa.path']},
                'AMProvides': {'Container': 'List', 'Types': ['com.apple.cocoa.path']},
                'ActionBundlePath': '/System/Library/Automator/Run Shell Script.action',
                'ActionName': 'Run Shell Script',
                'ActionParameters': {
                    'COMMAND_STRING': script_content,
                    'CheckedForUserDefaultShell': True,
                    'inputMethod': 0,
                    'shell': '/bin/bash',
                    'source': '',
                },
                'BundleIdentifier': 'com.apple.RunShellScript',
                'CFBundleVersion': '2.0.3',
                'CanShowSelectedItemsWhenRun': False,
                'CanShowWhenRun': True,
                'Category': ['AMCategoryUtilities'],
                'Class Name': 'RunShellScriptAction',
                'InputUUID': str(uuid.uuid4()).upper(),
                'OutputUUID': str(uuid.uuid4()).upper(),
                'UUID': str(uuid.uuid4()).upper(),
                'UnlocalizedApplications': ['Automator'],
                'isViewVisible': True,
                'location': '309.500000:253.000000',
                'nibPath': '/System/Library/Automator/Run Shell Script.action/Contents/Resources/en.lproj/main.nib',
            },
            'isViewVisible': True,
        }],
        'connectors': {},
        'workflowMetaData': {
            'workflowTypeIdentifier': 'com.apple.Automator.servicesMenu',
            'serviceInputTypeIdentifier': 'com.apple.Automator.fileSystemObject',
            'serviceOutputTypeIdentifier': 'com.apple.Automator.nothing',
            'serviceProcessesInput': False,
            'serviceApplicationBundleID': 'com.apple.finder',
        },
    }

    with open(os.path.join(contents_dir, 'document.wflow'), 'wb') as f:
        plistlib.dump(doc, f, fmt=plistlib.FMT_BINARY)

    # Set permissions
    os.chmod(workflow_dir, 0o755)

    print('[OK] Created: Open Claude with File.workflow')


if __name__ == '__main__':
    # Read script content from argument or stdin
    if len(sys.argv) > 1:
        with open(sys.argv[1], 'r') as f:
            script_content = f.read()
    else:
        script_content = sys.stdin.read()

    create_workflow(script_content)

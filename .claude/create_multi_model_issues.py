#!/usr/bin/env python3
"""
Multi-Model GitHub Issue Creator
Creates issues with model selection reasoning
"""

import json
import subprocess
import sys
from datetime import datetime


def create_github_issue(issue_data):
    """Create a GitHub issue with multi-model analysis"""

    title = issue_data.get("title", "Code Review Finding")
    body = issue_data.get("body", "")

    # Add timestamp and metadata
    full_body = f"""{body}

---
**Auto-generated**: {datetime.now().isoformat()}
**Created by**: Multi-Model Code Review System

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
"""

    try:
        result = subprocess.run(
            ["gh", "issue", "create", "--title", title, "--body", full_body],
            capture_output=True,
            text=True,
            check=True,
        )

        if result.returncode == 0:
            print(f"✅ Created: {result.stdout.strip()}")
            return True
        else:
            print(f"❌ Failed: {result.stderr}")
            return False

    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def main():
    if len(sys.argv) > 1:
        # Read from file
        with open(sys.argv[1], "r") as f:
            issues = json.load(f)
    else:
        # Read from stdin
        issues = json.load(sys.stdin)

    created = 0
    for issue in issues:
        if create_github_issue(issue):
            created += 1

    print(f"\nCreated {created}/{len(issues)} issues")
    return 0 if created > 0 else 1


if __name__ == "__main__":
    sys.exit(main())

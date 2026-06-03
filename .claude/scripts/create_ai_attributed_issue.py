#!/usr/bin/env python3
"""
Create GitHub issues with AI model attribution.
Records which AI models found the issue, arbiter decision, and why models were accepted/rejected.
"""

import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path

REPO = "FlossWare/VirtOS"
ARBITER = "Claude Sonnet 4.5"

def create_issue_with_attribution(issue_data):
    """
    Create a GitHub issue with full AI model attribution.

    issue_data structure:
    {
        "title": str,
        "severity": str,
        "models_found": [{"name": str, "severity": str, "details": str}],
        "models_missed": [{"name": str, "reason": str}],
        "arbiter_decision": str,  # "auto-fix", "manual-review", "partial"
        "accepted_approach": str,
        "rejected_approaches": [{"approach": str, "reason": str}],
        "body": str
    }
    """

    # Build attribution section
    attribution = f"""## AI Model Attribution

### Arbiter: {ARBITER}

**Decision**: {issue_data['arbiter_decision'].upper()}

### Model Findings

| AI Model | Verdict | Severity | Analysis |
|----------|---------|----------|----------|
"""

    for model in issue_data['models_found']:
        attribution += f"| **{model['name']}** | ✅ FOUND | {model['severity']} | {model['details']} |\n"

    for model in issue_data.get('models_missed', []):
        attribution += f"| **{model['name']}** | ❌ MISSED | N/A | {model['reason']} |\n"

    consensus_pct = len(issue_data['models_found']) / (len(issue_data['models_found']) + len(issue_data.get('models_missed', []))) * 100
    attribution += f"\n**Consensus**: {len(issue_data['models_found'])}/{len(issue_data['models_found']) + len(issue_data.get('models_missed', []))} models ({consensus_pct:.0f}%)\n\n"

    # Accepted approach
    attribution += f"""### Arbiter Decision

✅ **Accepted Approach**: {issue_data['accepted_approach']}

"""

    # Rejected approaches
    if issue_data.get('rejected_approaches'):
        attribution += "❌ **Rejected Approaches**:\n\n"
        for rejected in issue_data['rejected_approaches']:
            attribution += f"- **{rejected['approach']}**\n"
            attribution += f"  - Why: {rejected['reason']}\n\n"

    # Full body
    full_body = f"""{issue_data['body']}

---

{attribution}

---
*Arbiter: {ARBITER}*
*Session: {datetime.now().strftime('%Y-%m-%d')}*
*Automated multi-model code review*
"""

    # Create issue
    result = subprocess.run(
        ["gh", "issue", "create",
         "--repo", REPO,
         "--title", f"[{issue_data['severity']}] {issue_data['title']}",
         "--body", full_body],
        capture_output=True,
        text=True
    )

    if result.returncode == 0:
        print(f"✓ Created issue: {result.stdout.strip()}")
        return result.stdout.strip()
    else:
        print(f"✗ Failed: {result.stderr}", file=sys.stderr)
        return None

def example_usage():
    """Example of creating an issue with AI attribution."""
    issue = {
        "title": "Example security vulnerability",
        "severity": "HIGH",
        "models_found": [
            {"name": "Claude Opus 4.8", "severity": "CRITICAL", "details": "Comprehensive audit"},
            {"name": "Claude Sonnet 4.5", "severity": "HIGH", "details": "Confirmed finding"}
        ],
        "models_missed": [
            {"name": "Claude Haiku 4.5", "reason": "Focused on different area"}
        ],
        "arbiter_decision": "auto-fix",
        "accepted_approach": "Use safe library function",
        "rejected_approaches": [
            {"approach": "Manual review", "reason": "Too simple, library exists"},
            {"approach": "Ignore", "reason": "Multi-model consensus validates severity"}
        ],
        "body": """## Problem
Description of the security issue.

## Impact
What happens if this isn't fixed.

## Recommended Fix
How to fix it safely.
"""
    }

    create_issue_with_attribution(issue)

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--example":
        example_usage()
    else:
        print("Usage: create_ai_attributed_issue.py [--example]")
        print("Import this module and call create_issue_with_attribution(issue_data)")

#!/usr/bin/env python3
"""
VirtOS Automated Code Review - GitHub Issue Creator
Creates GitHub issues for code review findings
"""

import json
import subprocess
import sys
from datetime import datetime


class GitHubIssueCreator:
    def __init__(self):
        self.issues_created = 0
        self.review_timestamp = datetime.now().isoformat()

    def create_issue(
        self, title: str, body: str, priority: str = "P2"
    ) -> bool:
        """Create a GitHub issue using gh CLI"""
        try:
            # Add metadata to body
            full_body = f"""{body}

---
**Auto-detected**: {self.review_timestamp}
**Priority**: {priority}
**Created by**: Automated Code Review System

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
"""

            # Create issue via gh CLI
            result = subprocess.run(
                [
                    "gh",
                    "issue",
                    "create",
                    "--title",
                    title,
                    "--body",
                    full_body,
                ],
                capture_output=True,
                text=True,
                check=True,
            )

            if result.returncode == 0:
                issue_url = result.stdout.strip()
                print(f"✅ Created issue: {issue_url}")
                self.issues_created += 1
                return True
            else:
                print(f"❌ Failed to create issue: {result.stderr}")
                return False

        except subprocess.CalledProcessError as e:
            print(f"❌ Error creating issue: {e.stderr}")
            return False
        except Exception as e:
            print(f"❌ Unexpected error: {e}")
            return False

    def check_existing_issue(self, search_term: str) -> bool:
        """Check if similar issue already exists"""
        try:
            result = subprocess.run(
                [
                    "gh",
                    "issue",
                    "list",
                    "--search",
                    search_term,
                    "--json",
                    "number,title",
                    "--limit",
                    "10",
                ],
                capture_output=True,
                text=True,
                check=True,
            )

            if result.returncode == 0:
                issues = json.loads(result.stdout)
                return len(issues) > 0
            return False

        except Exception:
            return False


def main():
    """Main entry point for automated review issue creation"""
    creator = GitHubIssueCreator()

    # Read review findings from stdin (JSON format expected)
    if not sys.stdin.isatty():
        try:
            findings = json.load(sys.stdin)

            for finding in findings:
                title = finding.get("title", "Code Review Finding")
                body = finding.get("body", "")
                priority = finding.get("priority", "P2")
                search_term = finding.get("search_term", title[:30])

                # Check for duplicates
                if not creator.check_existing_issue(search_term):
                    creator.create_issue(title, body, priority)
                else:
                    print(f"ℹ️  Skipping duplicate: {title}")

        except json.JSONDecodeError as e:
            print(f"❌ Invalid JSON input: {e}")
            sys.exit(1)
    else:
        print("Usage: cat findings.json | python3 create_review_issues.py")
        print("Or: Pass findings via stdin in JSON format")
        sys.exit(1)

    print(f"\n=== Summary ===")
    print(f"Issues created: {creator.issues_created}")

    sys.exit(0 if creator.issues_created == 0 else 1)


if __name__ == "__main__":
    main()

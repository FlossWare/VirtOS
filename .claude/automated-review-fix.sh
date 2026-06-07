#!/bin/bash
# Quick fix: Use --body-file for large issue bodies

# Find the create_issue function and add --body-file support
sed -i.bak '/gh issue create --title/,/fi$/c\
    # Write body to temp file to avoid "argument list too long"\
    local body_file\
    body_file=$(mktemp)\
    echo "$body" > "$body_file"\
\
    local issue_url\
    if issue_url=$(gh issue create --title "$title" --body-file "$body_file" 2>&1 | tee -a "$REVIEW_LOG"); then\
        rm -f "$body_file"\
        # Extract issue number from URL\
        local issue_number\
        issue_number=$(echo "$issue_url" | grep -oE "/issues/[0-9]+$" | grep -oE "[0-9]+$")\
\
        if [ -n "$issue_number" ]; then\
            record_issue_hash "$title" "$body" "$issue_number"\
            ISSUES_CREATED=$((ISSUES_CREATED + 1))\
            echo "✅ Issue #$issue_number created successfully" | tee -a "$REVIEW_LOG"\
        else\
            release_issue_reservation "$title" "$body"\
            ISSUES_CREATED=$((ISSUES_CREATED + 1))\
            echo "✅ Issue created successfully (could not extract number)" | tee -a "$REVIEW_LOG"\
        fi\
    else\
        rm -f "$body_file"\
        release_issue_reservation "$title" "$body"\
        echo "❌ Failed to create issue" | tee -a "$REVIEW_LOG"\
        return 1\
    fi' .claude/automated-review.sh

echo "✅ Applied --body-file fix"

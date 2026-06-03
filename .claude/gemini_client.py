#!/usr/bin/env python3
"""
Gemini API Client for VirtOS Code Review
Calls Google Gemini API with prompts and returns structured responses
"""

import os
import sys
import json
import requests


def call_gemini(prompt, schema=None):
    """Call Gemini API with a prompt and optional JSON schema"""

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("ERROR: GEMINI_API_KEY not set", file=sys.stderr)
        return None

    # Use Gemini 1.5 Pro or Flash
    model = os.environ.get("GEMINI_MODEL", "gemini-1.5-pro-latest")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"

    # Build request
    request_body = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.7,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 8192,
        },
    }

    # If schema provided, request JSON output
    if schema:
        request_body["generationConfig"]["response_mime_type"] = "application/json"
        request_body["generationConfig"]["response_schema"] = schema

    try:
        response = requests.post(url, json=request_body, timeout=120)
        response.raise_for_status()

        result = response.json()

        # Extract text from response
        if "candidates" in result and len(result["candidates"]) > 0:
            candidate = result["candidates"][0]
            if "content" in candidate and "parts" in candidate["content"]:
                text = candidate["content"]["parts"][0].get("text", "")

                # If schema was provided, parse as JSON
                if schema:
                    try:
                        return json.loads(text)
                    except json.JSONDecodeError:
                        print(
                            f"WARNING: Gemini returned invalid JSON: {text[:200]}",
                            file=sys.stderr,
                        )
                        return None

                return text

        print(f"ERROR: Unexpected Gemini response format: {result}", file=sys.stderr)
        return None

    except requests.exceptions.RequestException as e:
        print(f"ERROR: Gemini API call failed: {e}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"ERROR: Unexpected error: {e}", file=sys.stderr)
        return None


def main():
    """CLI interface for testing"""
    if len(sys.argv) < 2:
        print("Usage: gemini_client.py 'prompt text' [schema.json]")
        sys.exit(1)

    prompt = sys.argv[1]
    schema = None

    if len(sys.argv) > 2:
        with open(sys.argv[2], "r") as f:
            schema = json.load(f)

    result = call_gemini(prompt, schema)

    if result:
        print(json.dumps(result, indent=2) if isinstance(result, dict) else result)
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()

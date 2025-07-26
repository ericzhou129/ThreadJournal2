#!/usr/bin/env python3
"""
Feature Request Process Hook for Claude Code
Ensures the Feature Request Process is followed when feature requests are mentioned
"""

import json
import sys
import re
import os

def main():
    # Read the input from stdin
    input_data = json.load(sys.stdin)
    prompt = input_data.get("prompt", "").lower()
    
    # Check if the prompt mentions feature requests
    feature_patterns = [
        r"feature request",
        r"new feature",
        r"add.*feature",
        r"implement.*feature",
        r"can you add",
        r"i want.*to be able",
        r"it would be nice if",
        r"enhancement",
        r"improve.*functionality"
    ]
    
    contains_feature_request = any(re.search(pattern, prompt, re.IGNORECASE) for pattern in feature_patterns)
    
    if contains_feature_request:
        # Check if the user is explicitly asking to skip the process
        skip_patterns = [
            r"skip.*process",
            r"quick.*implementation",
            r"just.*code",
            r"directly.*implement"
        ]
        
        should_skip = any(re.search(pattern, prompt, re.IGNORECASE) for pattern in skip_patterns)
        
        if not should_skip:
            # Add context about the feature request process
            context = """
IMPORTANT: Feature Request Process Detected

The user's message appears to contain a feature request. Please follow the 5-step Feature Request Process:

1. Exchange with User - Understand the actual need
2. Design - Create visual mockups/prototypes
3. Write Ticket - Document requirements (no tech details)
4. Update Technical Plan - Modify Technical-Implementation-Plan.md
5. Revise Ticket - Add technical implementation details

Reference: /Feature-Request-Process.md

Start by asking clarifying questions to understand the user's actual need before jumping to implementation.
"""
            
            output = {
                "decision": "allow",
                "context": context
            }
        else:
            output = {"decision": "allow"}
    else:
        output = {"decision": "allow"}
    
    # Write the output
    json.dump(output, sys.stdout)

if __name__ == "__main__":
    main()
#!/bin/bash
# Feature Request Process Hook for Claude Code
# Ensures the Feature Request Process is followed when feature requests are mentioned

# Read input from stdin
input=$(cat)

# Extract the prompt using jq
prompt=$(echo "$input" | jq -r '.prompt // ""' | tr '[:upper:]' '[:lower:]')

# Check if prompt mentions feature requests
if echo "$prompt" | grep -qiE "(feature request|new feature|add.*feature|implement.*feature|can you add|i want.*to be able|it would be nice if|enhancement|improve.*functionality)"; then
    
    # Check if user wants to skip the process
    if ! echo "$prompt" | grep -qiE "(skip.*process|quick.*implementation|just.*code|directly.*implement)"; then
        
        # Create the context message
        context="IMPORTANT: Feature Request Process Detected

The user's message appears to contain a feature request. Please follow the 5-step Feature Request Process:

1. Exchange with User - Understand the actual need
2. Design - Create visual mockups/prototypes
3. Write Ticket - Document requirements (no tech details) - MUST reference design files
4. Update Technical Plan - Modify Technical-Implementation-Plan.md
5. Revise Ticket - Add technical implementation details

Reference: /Feature-Request-Process.md

REMINDER: When writing tickets, always include a 'Design Reference' section that links to:
- Mockup files (e.g., /Design/feature-name-mockup.html)
- Design system components (e.g., Design:v1.2/ComponentName)

Start by asking clarifying questions to understand the user's actual need before jumping to implementation."

        # Output the decision with context
        jq -n --arg context "$context" '{decision: "allow", context: $context}'
    else
        # Allow without context if skip is detected
        echo '{"decision": "allow"}'
    fi
else
    # Allow without context if no feature request detected
    echo '{"decision": "allow"}'
fi
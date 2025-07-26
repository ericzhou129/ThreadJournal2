# Claude Code Hooks

This directory contains custom hooks for Claude Code to enhance the development workflow.

## Feature Request Checker Hook

**File:** `feature-request-checker.sh`
**Event:** `UserPromptSubmit`

### Purpose
Automatically detects when a user mentions a feature request and reminds Claude to follow the established 5-step Feature Request Process.

### How it Works
1. Monitors user prompts for feature request keywords:
   - "feature request"
   - "new feature"
   - "can you add"
   - "enhancement"
   - etc.

2. When detected, adds context to remind Claude about the process:
   - Exchange with User
   - Design
   - Write Ticket
   - Update Technical Plan
   - Revise Ticket

3. Can be bypassed if user explicitly mentions:
   - "skip process"
   - "quick implementation"
   - "just code"
   - "directly implement"

### Configuration
Registered in `.claude/settings.json`:
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/feature-request-checker.sh\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### Testing
To test the hook manually:
```bash
echo '{"prompt": "I have a feature request for dark mode"}' | bash .claude/hooks/feature-request-checker.sh
```

### Troubleshooting
- Ensure the script has execute permissions: `chmod +x feature-request-checker.sh`
- Check that `jq` is installed on your system
- Review Claude Code logs if the hook isn't triggering

## Adding New Hooks
1. Create a new script in this directory
2. Make it executable: `chmod +x your-hook.sh`
3. Add configuration to `.claude/settings.json`
4. Document it in this README
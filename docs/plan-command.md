# The /plan Slash Command

## Overview

The `/plan` command transforms Claude into a Software Project Planner agent that breaks down high-level tasks, features, or GitHub issues into detailed, actionable development plans. This helps ensure a clear approach before implementation begins.

**IMPORTANT**: The `/plan` command is for planning only. It will never start implementing code or making changes. Its sole purpose is to create comprehensive plans.

## Usage

### Basic Syntax
```
/plan "Task description"
/plan issue-123
/plan #456
/plan owner/repo#789
```

### Examples

**Plan from text description:**
```
/plan "Add user authentication with OAuth2"
```

**Plan from GitHub issue:**
```
/plan issue-678
/plan #123
/plan myorg/myrepo#456
```

## Features

### 1. Flexible Input Handling
- **Direct text**: Provide task description in quotes
- **GitHub issues**: Automatically fetches issue title and body
- **Repository support**: Can fetch issues from different repositories

### 2. Intelligent Planning Process
The planner follows a multi-phase approach:

**Phase 1: Codebase Analysis**
- Searches for relevant files and patterns
- Reads key files to understand architecture
- Identifies existing patterns and dependencies
- Uses this knowledge to ask better questions

**Phase 2: Interactive Questions**
- Asks clarifying questions based on codebase analysis
- Presents all questions at once for efficiency
- Supports up to 3 rounds of follow-up questions
- Uses answers to create more targeted plans

**Phase 3: Comprehensive Planning**
Creates detailed plans including:
- **Overview**: Summary of the task
- **Prerequisites**: Dependencies and setup requirements
- **Development Tasks**: Numbered, actionable implementation steps
- **Testing Strategy**: Unit, integration, and manual testing approach
- **Edge Cases**: Special scenarios and error handling
- **Documentation**: What needs to be created/updated
- **Acceptance Criteria**: Clear definition of completion

### 3. GitHub Integration
When planning from a GitHub issue, the command:
1. Fetches issue details using `gh` CLI
2. Creates a comprehensive plan
3. **Automatically appends the plan to the issue** with proper formatting
4. Preserves existing issue content

### 4. Complexity Estimation
Each task includes complexity indicators:
- `[Small]`: Quick tasks (< 1 hour)
- `[Medium]`: Standard tasks (1-4 hours)
- `[Large]`: Complex tasks (4+ hours)

## Interactive Example

```
User: /plan "Add user authentication to the app"

Assistant: *Analyzing codebase for authentication patterns...*
[Searches for auth-related files, reads existing patterns]

Based on my analysis of the codebase, I have some questions to help create a better plan:

1. **Authentication Type**: What type of authentication do you need?
   - Simple username/password
   - OAuth2 (Google, GitHub, etc.)
   - JWT-based
   - Session-based

2. **User Data Storage**: Where should user data be stored?
   - Existing database (which one?)
   - New database table
   - External service

3. **Scope**: Which parts of the app need authentication?
   - Entire application
   - Specific routes/features only
   - API endpoints

User: JWT-based with PostgreSQL storage. Protect all API endpoints except /login and /register.

Assistant: Thank you! Creating comprehensive plan...
[Generates detailed plan based on codebase analysis and answers]
```

## Output Format

The planner produces structured markdown output:

```markdown
## Plan: [Task Title]

### Overview
Brief description of the feature and its purpose.

### Prerequisites
- [ ] Required dependencies
- [ ] Access permissions
- [ ] Environment setup

### Development Tasks
1. **Database Schema** [Complexity: Medium]
   - Design user table structure
   - Add OAuth provider fields
   
2. **API Endpoints** [Complexity: Large]
   - Implement /auth/login endpoint
   - Create OAuth callback handlers

### Testing Strategy
- Unit tests for authentication logic
- Integration tests for OAuth flow
- Manual testing checklist

### Edge Cases & Considerations
- Invalid OAuth tokens
- Provider API downtime
- Concurrent login attempts

### Documentation Updates
- API documentation for new endpoints
- User guide for OAuth setup
- Configuration instructions

### Acceptance Criteria
- [ ] Users can log in via OAuth
- [ ] Sessions persist correctly
- [ ] Error handling works properly
- [ ] All tests pass

### Suggested Next Steps
1. Review and adjust this plan
2. Run `starttask myapp feature/oauth-auth`
3. Begin with database schema task
```

## Integration with Agentyard

The planner suggests using Agentyard commands for implementation:
- Creates branch names based on the task
- Recommends `starttask` commands
- Suggests breaking large features into multiple worktrees

## GitHub Issue Updates

When planning from a GitHub issue, the plan is automatically appended:

```markdown
[Original issue content]

---
## Implementation Plan
*Generated on 2024-01-20*

[Full plan content]
```

## Advanced Usage

### Planning Phases
For large features, request phased planning:
```
/plan "Implement full e-commerce checkout - phase 1 only"
```

### Technology-Specific Plans
Include context for better plans:
```
/plan "Add Redis caching to Node.js API"
```

### Skip Questions (Not Recommended)
The planner will always ask questions to ensure better plans. There is no way to skip this phase as it leads to more accurate, tailored plans.

### Multiple Repository Support
```
/plan frontend-org/web-app#123
/plan backend-org/api#456
```

## Best Practices

1. **Answer Questions Thoroughly**
   - More detailed answers lead to better plans
   - Include technical constraints
   - Mention existing systems to integrate with

2. **Review Before Implementation**
   - Plans are suggestions, not mandates
   - Adjust based on your knowledge
   - Consider team conventions

2. **Use with starttask**
   - Each major task can become a worktree
   - Implement tasks sequentially
   - Commit frequently

3. **Update Plans**
   - Plans can evolve during implementation
   - Re-run `/plan` for complex features
   - Keep GitHub issues updated

4. **Break Down Large Tasks**
   - Request phased approaches
   - Create sub-issues for major components
   - Use multiple worktrees for parallel work

## Technical Details

### GitHub CLI Integration
The command uses `gh` CLI for GitHub operations:
```bash
# Fetch issue
gh issue view 123 --json title,body,assignees,labels,milestone

# Update issue
gh issue edit 123 --body "updated content"
```

### Requirements
- GitHub CLI (`gh`) installed and authenticated
- Repository access for issue operations
- Claude Code with slash command support

## Key Differences from Other Commands

| Feature | /plan | /implement-gh-issue |
|---------|-------|-------------------|
| Purpose | Planning only | Full implementation |
| Codebase Analysis | Yes (for questions) | Yes (for coding) |
| Interactive Questions | Yes (always) | No |
| Output | Detailed plan | Working code + PR |
| GitHub | Updates issue description | Creates PR |
| Implementation | Never implements | Always implements |
| Time | Minutes | Hours/Days |
| Use Case | Before coding | Ready to code |

**Remember**: `/plan` will NEVER write code or implement features. It's purely a planning tool.

## Troubleshooting

**"Issue not found"**
- Verify issue number is correct
- Check you're in the right repository
- Ensure `gh` is authenticated

**"Plan too vague"**
- Provide more context in description
- Include technical requirements
- Specify constraints or preferences

**"Can't update issue"**
- Check repository permissions
- Verify `gh` authentication
- Ensure issue isn't locked

## Summary

The `/plan` command provides a crucial planning phase before implementation, helping to:
- Clarify requirements before coding
- Identify potential challenges early
- Create structured approach to features
- Maintain clear documentation
- Improve communication via GitHub issues

Use it whenever you need to think through a task before diving into implementation.
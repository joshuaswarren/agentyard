# Agentsmd Directory Structure

This directory contains the data and configuration files for the `agentsmd` command.

## Directory Layout

```
agentsmd/
├── best-practices/     # Migration files (001-*.md, 002-*.md, etc.)
├── cache/              # Cached Claude analysis results
├── templates/          # Base templates (future use)
└── lib/                # Helper scripts and libraries (future use)
```

## Best Practices Directory

Contains numbered migration files that are applied in order:
- `001-header.md` - Basic header and project overview
- `002-architecture.md` - Architecture patterns and technologies
- `003-development-setup.md` - Setup instructions
- `004-testing-approach.md` - Testing strategy
- `005-file-roadmap.md` - Key files and conventions
- `006-ai-guidelines.md` - Guidelines for AI assistants

## Cache Directory

Stores Claude Code analysis results to avoid redundant API calls:
- Organized by project name and cache key
- Automatically invalidated when code changes
- Can be cleared with `rm -rf cache/`

## Adding New Migrations

1. Create a new file in `best-practices/` with the next number
2. Start with `# Description: Your description here`
3. Include static content and/or `{{CLAUDE_PROMPT}}...{{/CLAUDE_PROMPT}}` blocks
4. Test with `agentsmd --check-only` before committing

## Migration File Format

```markdown
# Description: Brief description of what this migration adds

## Section Title

Static content that will be copied as-is.

{{CLAUDE_PROMPT}}
Instructions for Claude Code to analyze the repository.
The output will replace this entire block.
{{/CLAUDE_PROMPT}}

More static content...
```
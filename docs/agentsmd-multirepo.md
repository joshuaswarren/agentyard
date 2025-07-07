# Multi-Repository Support in agentsmd

The `agentsmd` command now supports discovering rules and best practices from multiple repositories, following the agentyard three-folder architecture.

## Overview

agentsmd will search for content in three locations (in order of precedence):

1. `~/agentyard-private/agentsmd/` - Personal configurations (highest priority)
2. `~/agentyard-team/agentsmd/` - Team-specific configurations
3. `~/agentyard/agentsmd/` - Public configurations (lowest priority)

## How It Works

### Rules Discovery

- Rules are discovered from `rules/` subdirectory in each repository
- If the same rule filename exists in multiple repos, the first one found takes precedence
- This allows private repositories to override public rules
- The source repository is tracked in `.agentyard-rules.yml`

### Best Practices Migrations

- Migrations are discovered from `best-practices/` subdirectory in each repository
- Migrations with the same filename are considered overrides
- Only the highest-priority version of each migration is applied
- The `--list-migrations` flag shows all available migrations and indicates overrides

## Example Structure

```
~/agentyard-private/agentsmd/
├── rules/
│   └── commit.mdc          # Personal override of commit rules
└── best-practices/
    └── 001-header.md       # Personal override of header migration

~/agentyard-team/agentsmd/
├── rules/
│   └── team-workflow.mdc   # Team-specific workflow rules
└── best-practices/
    └── 008-team-setup.md   # Team-specific setup migration

~/agentyard/agentsmd/
├── rules/
│   └── commit.mdc          # Public commit rules (overridden by private)
└── best-practices/
    └── 001-header.md       # Public header migration (overridden by private)
```

## Usage

No special configuration is needed. Simply organize your rules and migrations in the appropriate directories, and agentsmd will automatically discover them.

### List all available migrations:
```bash
agentsmd --list-migrations
```

### Preview what would be synced:
```bash
agentsmd --check-only --verbose
```

### Apply migrations and sync rules:
```bash
agentsmd
```

## Benefits

1. **Flexibility**: Keep personal preferences separate from team and public configurations
2. **Override capability**: Customize any public rule or migration without modifying the original
3. **Team collaboration**: Share team-specific practices without affecting public repositories
4. **Clean separation**: Each repository maintains its own set of configurations
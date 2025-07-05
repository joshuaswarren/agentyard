#!/usr/bin/env python3
"""
mentor - AI-powered code review tool for git commits

This tool uses OpenAI's API to analyze git commits and provide actionable
feedback on code quality, comparing against existing guidelines in AGENTS.md
and CLAUDE.md files.
"""

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# ANSI color codes for terminal output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[0;33m'
    BLUE = '\033[0;34m'
    MAGENTA = '\033[0;35m'
    CYAN = '\033[0;36m'
    BOLD = '\033[1m'
    RESET = '\033[0m'


def print_error(message: str) -> None:
    """Print error message in red"""
    print(f"{Colors.RED}Error: {message}{Colors.RESET}", file=sys.stderr)


def print_success(message: str) -> None:
    """Print success message in green"""
    print(f"{Colors.GREEN}{message}{Colors.RESET}")


def print_info(message: str) -> None:
    """Print info message in blue"""
    print(f"{Colors.BLUE}{message}{Colors.RESET}")


def print_warning(message: str) -> None:
    """Print warning message in yellow"""
    print(f"{Colors.YELLOW}Warning: {message}{Colors.RESET}")


def check_git_repo() -> bool:
    """Check if we're in a git repository"""
    try:
        subprocess.run(['git', 'rev-parse', '--git-dir'], 
                      capture_output=True, check=True)
        return True
    except subprocess.CalledProcessError:
        return False


def get_commit_hash(commit_ref: Optional[str] = None) -> str:
    """Get full commit hash from a reference"""
    if not commit_ref:
        commit_ref = "HEAD"
    
    try:
        result = subprocess.run(
            ['git', 'rev-parse', commit_ref],
            capture_output=True, text=True, check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        print_error(f"Invalid commit reference: {commit_ref}")
        sys.exit(1)


def get_commit_range(start: str, end: str) -> List[str]:
    """Get list of commit hashes in a range (inclusive)"""
    try:
        # Get commits from start to end (inclusive)
        result = subprocess.run(
            ['git', 'rev-list', f'{start}^..{end}'],
            capture_output=True, text=True, check=True
        )
        return result.stdout.strip().split('\n') if result.stdout.strip() else []
    except subprocess.CalledProcessError:
        # If start^ fails (e.g., for initial commit), try without it
        try:
            result = subprocess.run(
                ['git', 'rev-list', f'{start}..{end}'],
                capture_output=True, text=True, check=True
            )
            commits = result.stdout.strip().split('\n') if result.stdout.strip() else []
            # Add the start commit manually
            commits.append(start)
            return list(reversed(commits))
        except subprocess.CalledProcessError:
            print_error(f"Failed to get commit range from {start} to {end}")
            sys.exit(1)


def get_commit_info(commit_hash: str) -> Dict[str, str]:
    """Get commit information"""
    try:
        # Get commit message and metadata
        result = subprocess.run(
            ['git', 'show', '--no-patch', '--format=%H%n%an%n%ae%n%at%n%s%n%b', commit_hash],
            capture_output=True, text=True, check=True
        )
        lines = result.stdout.strip().split('\n')
        
        return {
            'hash': lines[0],
            'author': lines[1],
            'email': lines[2],
            'timestamp': lines[3],
            'subject': lines[4],
            'body': '\n'.join(lines[5:]) if len(lines) > 5 else ''
        }
    except subprocess.CalledProcessError:
        print_error(f"Failed to get commit info for {commit_hash}")
        sys.exit(1)


def get_commit_diff(commit_hash: str) -> str:
    """Get the diff for a commit"""
    try:
        result = subprocess.run(
            ['git', 'show', '--format=', commit_hash],
            capture_output=True, text=True, check=True
        )
        return result.stdout
    except subprocess.CalledProcessError:
        print_error(f"Failed to get diff for commit {commit_hash}")
        sys.exit(1)


def filter_third_party_files(diff: str) -> str:
    """Filter out third-party code from diff"""
    # Patterns for third-party directories and files
    third_party_patterns = [
        r'^diff --git a/node_modules/',
        r'^diff --git a/vendor/',
        r'^diff --git a/venv/',
        r'^diff --git a/\.venv/',
        r'^diff --git a/dist/',
        r'^diff --git a/build/',
        r'^diff --git a/target/',
        r'^diff --git a/\.git/',
        r'^diff --git a/bower_components/',
        r'^diff --git a/jspm_packages/',
        r'^diff --git a/web_modules/',
        r'^diff --git a/\.cache/',
        r'^diff --git a/coverage/',
        r'^diff --git a/\.pytest_cache/',
        r'^diff --git a/__pycache__/',
        r'^diff --git a/.*\.min\.js',
        r'^diff --git a/.*\.min\.css',
        r'^diff --git a/package-lock\.json',
        r'^diff --git a/yarn\.lock',
        r'^diff --git a/composer\.lock',
        r'^diff --git a/Gemfile\.lock',
        r'^diff --git a/poetry\.lock',
        r'^diff --git a/Pipfile\.lock',
    ]
    
    # Split diff into individual file diffs
    file_diffs = re.split(r'^diff --git', diff, flags=re.MULTILINE)
    filtered_diffs = []
    
    for file_diff in file_diffs:
        if not file_diff.strip():
            continue
            
        # Check if this file should be filtered
        full_diff = 'diff --git' + file_diff
        skip = False
        
        for pattern in third_party_patterns:
            if re.search(pattern, full_diff, re.MULTILINE):
                skip = True
                break
        
        if not skip:
            filtered_diffs.append(full_diff)
    
    return '\n'.join(filtered_diffs)


def read_existing_guidelines() -> Tuple[str, str]:
    """Read existing guidelines from AGENTS.md and CLAUDE.md"""
    agents_content = ""
    claude_content = ""
    
    # Read AGENTS.md
    agents_path = Path("AGENTS.md")
    if agents_path.exists():
        try:
            with open(agents_path, 'r') as f:
                content = f.read()
                # Extract Code Quality section
                match = re.search(r'## Code Quality.*?(?=\n##|\Z)', content, re.DOTALL)
                if match:
                    agents_content = match.group(0)
        except Exception as e:
            print_warning(f"Failed to read AGENTS.md: {e}")
    
    # Read CLAUDE.md
    claude_path = Path("CLAUDE.md")
    if claude_path.exists():
        try:
            with open(claude_path, 'r') as f:
                content = f.read()
                # Extract Code Quality section
                match = re.search(r'## Code Quality.*?(?=\n##|\Z)', content, re.DOTALL)
                if match:
                    claude_content = match.group(0)
        except Exception as e:
            print_warning(f"Failed to read CLAUDE.md: {e}")
    
    return agents_content, claude_content


def load_env_file() -> None:
    """Load .env file if it exists"""
    env_path = Path(".env")
    if env_path.exists():
        try:
            with open(env_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        # Don't override existing environment variables
                        if key not in os.environ:
                            os.environ[key] = value.strip('"').strip("'")
        except Exception as e:
            print_warning(f"Failed to load .env file: {e}")


def get_api_key() -> str:
    """Get OpenAI API key from environment"""
    api_key = os.environ.get('OPENAI_API_KEY')
    if not api_key:
        print_error("OPENAI_API_KEY environment variable not set")
        print_info("Please set it using: export OPENAI_API_KEY='your-api-key'")
        sys.exit(1)
    return api_key


def get_model_name(args) -> str:
    """Get model name from args, env, or default"""
    if args.model:
        return args.model
    
    # Check environment variable
    env_model = os.environ.get('OPENAI_MODEL')
    if env_model:
        return env_model
    
    # Default
    return 'o3'


def create_analysis_prompt(commit_info: Dict[str, str], diff: str, 
                         existing_agents: str, existing_claude: str) -> str:
    """Create the prompt for OpenAI API"""
    prompt = f"""You are an expert software development mentor and code reviewer. Your task is to review the following git commit and provide actionable feedback on how the developer could improve their code quality to meet commercial standards.

EXISTING GUIDELINES TO AVOID DUPLICATING:

From AGENTS.md:
{existing_agents if existing_agents else "(No existing guidelines found)"}

From CLAUDE.md:
{existing_claude if existing_claude else "(No existing guidelines found)"}

IMPORTANT: Do not suggest improvements that are already covered in the existing guidelines above.

COMMIT INFORMATION:
- Hash: {commit_info['hash'][:8]}
- Subject: {commit_info['subject']}
- Author: {commit_info['author']}
- Date: {datetime.fromtimestamp(int(commit_info['timestamp'])).strftime('%Y-%m-%d %H:%M:%S')}

COMMIT DIFF:
{diff}

Please analyze this commit and provide specific examples of how the code could be improved. Focus on:
1. Code organization and structure
2. Error handling
3. Testing practices
4. Documentation
5. Performance considerations
6. Security best practices
7. DRY/SOLID principles
8. Language-specific standards (PEP 8 for Python, PSR-12 for PHP, etc.)

For each issue you find, provide:
1. A clear title describing the issue
2. The current implementation (as it appears in the diff)
3. An improved version showing how it should be written
4. A brief explanation of why the improvement is better

Format your response as a JSON array of findings, where each finding has:
{{
  "title": "Brief descriptive title",
  "file": "path/to/file.ext",
  "current_code": "The problematic code as written",
  "improved_code": "The improved version",
  "explanation": "Why this is better",
  "category": "One of: error_handling, structure, testing, documentation, performance, security, principles, standards"
}}

If the commit is already following best practices and no improvements are needed, return an empty array.
Only include findings that represent genuine improvements, not stylistic preferences.
"""
    
    return prompt


def call_openai_api(prompt: str, api_key: str, model: str) -> Optional[List[Dict]]:
    """Call OpenAI API and parse response"""
    try:
        import openai
    except ImportError:
        print_error("OpenAI package not installed")
        print_info("Install it with: pip install openai")
        sys.exit(1)
    
    client = openai.OpenAI(api_key=api_key)
    
    try:
        print_info(f"Analyzing with {model}...")
        
        # Build parameters conditionally based on model
        params = {
            "model": model,
            "messages": [
                {"role": "system", "content": "You are a code review expert. Always respond with valid JSON."},
                {"role": "user", "content": prompt}
            ],
            "response_format": {"type": "json_object"}
        }
        
        # Only add temperature for non-o3 models
        # o3 models only support default temperature value (1)
        if not model.startswith('o3'):
            params["temperature"] = 0.3
        
        response = client.chat.completions.create(**params)
        
        # Parse the response
        content = response.choices[0].message.content
        try:
            # Try to parse as JSON
            data = json.loads(content)
            # Handle both array and object with findings key
            if isinstance(data, list):
                return data
            elif isinstance(data, dict) and 'findings' in data:
                return data['findings']
            else:
                print_warning("Unexpected response format")
                return []
        except json.JSONDecodeError:
            print_error("Failed to parse API response as JSON")
            print(f"Response: {content}")
            return None
            
    except Exception as e:
        print_error(f"OpenAI API error: {e}")
        return None


def format_terminal_output(findings: List[Dict], commit_info: Dict[str, str]) -> None:
    """Format and print findings to terminal"""
    if not findings:
        print_success(f"\n✅ Commit {commit_info['hash'][:8]} follows best practices!")
        return
    
    print(f"\n{Colors.BOLD}📝 Code Review for commit {commit_info['hash'][:8]}{Colors.RESET}")
    print(f"{Colors.CYAN}Subject: {commit_info['subject']}{Colors.RESET}")
    print(f"{Colors.CYAN}Author: {commit_info['author']}{Colors.RESET}\n")
    
    for i, finding in enumerate(findings, 1):
        print(f"{Colors.YELLOW}{Colors.BOLD}Finding {i}: {finding.get('title', 'Untitled')}{Colors.RESET}")
        print(f"{Colors.BLUE}File: {finding.get('file', 'Unknown')}{Colors.RESET}")
        print(f"{Colors.MAGENTA}Category: {finding.get('category', 'general')}{Colors.RESET}")
        
        print(f"\n{Colors.RED}Current implementation:{Colors.RESET}")
        print("```")
        print(finding.get('current_code', '').strip())
        print("```")
        
        print(f"\n{Colors.GREEN}Suggested improvement:{Colors.RESET}")
        print("```")
        print(finding.get('improved_code', '').strip())
        print("```")
        
        print(f"\n{Colors.CYAN}Explanation:{Colors.RESET} {finding.get('explanation', '')}")
        print("-" * 80 + "\n")


def format_markdown_output(findings: List[Dict], commit_info: Dict[str, str]) -> str:
    """Format findings as markdown for file output"""
    if not findings:
        return ""
    
    output = f"\n### Review: Commit {commit_info['hash'][:8]} - \"{commit_info['subject']}\"\n"
    output += f"*Reviewed on {datetime.now().strftime('%Y-%m-%d')} by mentor (model: {get_model_name(args)})*\n\n"
    
    for i, finding in enumerate(findings, 1):
        output += f"#### Finding {i}: {finding.get('title', 'Untitled')}\n"
        output += f"**File:** `{finding.get('file', 'Unknown')}`\n\n"
        
        output += "**Current Implementation:**\n"
        lang = detect_language(finding.get('file', ''))
        output += f"```{lang}\n"
        output += finding.get('current_code', '').strip()
        output += "\n```\n\n"
        
        output += "**Suggested Improvement:**\n"
        output += f"```{lang}\n"
        output += finding.get('improved_code', '').strip()
        output += "\n```\n\n"
        
        output += f"**Explanation:** {finding.get('explanation', '')}\n\n"
        output += "---\n"
    
    return output


def detect_language(filename: str) -> str:
    """Detect programming language from filename"""
    ext_map = {
        '.py': 'python',
        '.js': 'javascript',
        '.ts': 'typescript',
        '.php': 'php',
        '.rb': 'ruby',
        '.go': 'go',
        '.java': 'java',
        '.c': 'c',
        '.cpp': 'cpp',
        '.rs': 'rust',
        '.sh': 'bash',
        '.yaml': 'yaml',
        '.yml': 'yaml',
        '.json': 'json',
        '.md': 'markdown',
    }
    
    for ext, lang in ext_map.items():
        if filename.endswith(ext):
            return lang
    return ''


def update_markdown_file(filename: str, content: str) -> None:
    """Update markdown file with new content"""
    path = Path(filename)
    
    # Read existing content
    existing_content = ""
    if path.exists():
        try:
            with open(path, 'r') as f:
                existing_content = f.read()
        except Exception as e:
            print_warning(f"Failed to read {filename}: {e}")
    
    # Find or create Code Quality section
    if "## Code Quality" in existing_content:
        # Append to existing section
        # Find the end of the Code Quality section
        match = re.search(r'(## Code Quality.*?)(\n##|\Z)', existing_content, re.DOTALL)
        if match:
            before = existing_content[:match.end(1)]
            after = existing_content[match.end(1):]
            new_content = before + content + after
        else:
            # Fallback: just append
            new_content = existing_content + content
    else:
        # Create new section
        if existing_content and not existing_content.endswith('\n\n'):
            existing_content += '\n\n'
        new_content = existing_content + "## Code Quality\n" + content
    
    # Write updated content
    try:
        with open(path, 'w') as f:
            f.write(new_content)
        print_success(f"Updated {filename}")
    except Exception as e:
        print_error(f"Failed to update {filename}: {e}")


def main():
    parser = argparse.ArgumentParser(
        description='AI-powered code review for git commits',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  mentor                    # Review most recent commit
  mentor abc123def          # Review specific commit
  mentor abc123 def456      # Review commit range
  mentor --model gpt-4      # Use specific model
        """
    )
    
    parser.add_argument('commits', nargs='*', 
                       help='Commit hash(es) to review')
    parser.add_argument('--model', 
                       help='OpenAI model to use (default: o3 or OPENAI_MODEL env var)')
    
    global args
    args = parser.parse_args()
    
    # Check if we're in a git repo
    if not check_git_repo():
        print_error("Not in a git repository")
        sys.exit(1)
    
    # Load .env file
    load_env_file()
    
    # Get API key
    api_key = get_api_key()
    model = get_model_name(args)
    
    # Determine which commits to review
    commits_to_review = []
    
    if len(args.commits) == 0:
        # Review most recent commit
        commits_to_review.append(get_commit_hash("HEAD"))
    elif len(args.commits) == 1:
        # Review specific commit
        commits_to_review.append(get_commit_hash(args.commits[0]))
    elif len(args.commits) == 2:
        # Review commit range
        start_hash = get_commit_hash(args.commits[0])
        end_hash = get_commit_hash(args.commits[1])
        commits_to_review = get_commit_range(start_hash, end_hash)
    else:
        print_error("Too many arguments. Provide 0, 1, or 2 commit hashes.")
        sys.exit(1)
    
    print_info(f"Reviewing {len(commits_to_review)} commit(s)...")
    
    # Read existing guidelines once
    existing_agents, existing_claude = read_existing_guidelines()
    
    # Collect all findings
    all_markdown_output = ""
    
    # Review each commit
    for commit_hash in commits_to_review:
        print(f"\n{Colors.BOLD}Analyzing commit {commit_hash[:8]}...{Colors.RESET}")
        
        # Get commit info and diff
        commit_info = get_commit_info(commit_hash)
        diff = get_commit_diff(commit_hash)
        
        # Filter third-party files
        filtered_diff = filter_third_party_files(diff)
        
        if not filtered_diff.strip():
            print_warning(f"Commit {commit_hash[:8]} contains only third-party code changes")
            continue
        
        # Create prompt
        prompt = create_analysis_prompt(commit_info, filtered_diff, 
                                      existing_agents, existing_claude)
        
        # Call OpenAI API
        findings = call_openai_api(prompt, api_key, model)
        
        if findings is None:
            continue
        
        # Format and display output
        format_terminal_output(findings, commit_info)
        
        # Collect markdown output
        markdown_output = format_markdown_output(findings, commit_info)
        if markdown_output:
            all_markdown_output += markdown_output
    
    # Update markdown files if we have findings
    if all_markdown_output:
        update_markdown_file("AGENTS.md", all_markdown_output)
        update_markdown_file("CLAUDE.md", all_markdown_output)
    
    print_success("\n✨ Code review complete!")


if __name__ == "__main__":
    main()
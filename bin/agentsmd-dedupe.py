#!/usr/bin/env python3
"""
agentsmd-dedupe - Remove duplicate text from AGENTS.md using OpenAI

This tool uses OpenAI's API to identify and remove exact duplicate text blocks
from AGENTS.md files, helping keep AI guidance files clean and concise.
"""

import argparse
import json
import os
import re
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

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


def print_verbose(message: str, verbose: bool) -> None:
    """Print message only if verbose mode is enabled"""
    if verbose:
        print(f"{Colors.CYAN}[VERBOSE] {message}{Colors.RESET}")


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


def read_agents_file() -> Optional[str]:
    """Read AGENTS.md file content"""
    agents_path = Path("AGENTS.md")
    if not agents_path.exists():
        print_error("AGENTS.md file not found in current directory")
        return None
    
    try:
        with open(agents_path, 'r') as f:
            return f.read()
    except Exception as e:
        print_error(f"Failed to read AGENTS.md: {e}")
        return None


def create_dedupe_prompt(content: str) -> str:
    """Create prompt for OpenAI to identify duplicates"""
    prompt = f"""You are an expert text analyzer tasked with identifying EXACT duplicate text blocks in an AGENTS.md file.

Your task is to:
1. Identify text blocks that appear MULTIPLE times in the file (exact duplicates only)
2. For each duplicate, return the first occurrence line number and all duplicate line numbers
3. Consider only meaningful text blocks (ignore single words or very short phrases)
4. A text block is duplicate only if it appears word-for-word identical, including whitespace

IMPORTANT RULES:
- Only identify EXACT duplicates (identical character-by-character)
- Ignore case differences - treat them as different
- Minimum duplicate length: 20 characters
- Include the entire duplicate block in your response
- If no duplicates exist, return an empty array

FILE CONTENT:
{content}

Return a JSON array where each element represents a duplicate text block:
{{
  "duplicate_text": "The exact text that is duplicated",
  "first_occurrence_line": <line number of first occurrence>,
  "duplicate_lines": [<array of line numbers where duplicates appear>],
  "occurrences": <total number of times this text appears>
}}

Only include blocks that appear 2 or more times."""
    
    return prompt


def call_openai_api(prompt: str, api_key: str, model: str, 
                   max_retries: int, timeout: int, verbose: bool) -> Optional[List[Dict]]:
    """Call OpenAI API with retry logic"""
    try:
        import openai
    except ImportError:
        print_error("OpenAI package not installed")
        print_info("Install it with: pip install openai")
        sys.exit(1)
    
    client = openai.OpenAI(api_key=api_key)
    
    retry_count = 0
    while retry_count < max_retries:
        try:
            print_info(f"Analyzing with {model}...")
            
            if verbose:
                print_verbose(f"Sending request to OpenAI API (attempt {retry_count + 1}/{max_retries})", verbose)
            
            # Build parameters conditionally based on model
            params = {
                "model": model,
                "messages": [
                    {"role": "system", "content": "You are a text analysis expert. Always respond with valid JSON."},
                    {"role": "user", "content": prompt}
                ],
                "response_format": {"type": "json_object"},
                "timeout": timeout
            }
            
            # Only add temperature for non-o3 models
            if not model.startswith('o3'):
                params["temperature"] = 0.1
            
            response = client.chat.completions.create(**params)
            
            # Parse the response
            content = response.choices[0].message.content
            if verbose:
                print_verbose(f"Raw API response:\n{content}", verbose)
            
            try:
                data = json.loads(content)
                # Handle both array and object with duplicates key
                if isinstance(data, list):
                    return data
                elif isinstance(data, dict) and 'duplicates' in data:
                    return data['duplicates']
                else:
                    print_warning("Unexpected response format")
                    return []
            except json.JSONDecodeError:
                print_error("Failed to parse API response as JSON")
                return None
                
        except openai.APITimeoutError:
            retry_count += 1
            if retry_count < max_retries:
                wait_time = 2 ** retry_count
                print_warning(f"Request timed out, retrying in {wait_time}s...")
                time.sleep(wait_time)
            else:
                print_error(f"Request timed out after {max_retries} attempts")
                return None
                
        except Exception as e:
            retry_count += 1
            if retry_count < max_retries:
                wait_time = 2 ** retry_count
                print_warning(f"API error: {e}, retrying in {wait_time}s...")
                time.sleep(wait_time)
            else:
                print_error(f"OpenAI API error after {max_retries} attempts: {e}")
                return None
    
    return None


def remove_duplicates(content: str, duplicates: List[Dict]) -> str:
    """Remove duplicate text blocks from content"""
    if not duplicates:
        return content
    
    # Split content into lines for line-based removal
    lines = content.split('\n')
    lines_to_remove = set()
    
    # Process each duplicate
    for dup in duplicates:
        duplicate_lines = dup.get('duplicate_lines', [])
        
        # Mark duplicate lines for removal (keep first occurrence)
        for line_num in duplicate_lines:
            # Convert to 0-based index
            if 1 <= line_num <= len(lines):
                lines_to_remove.add(line_num - 1)
    
    # Create new content without duplicate lines
    new_lines = []
    for i, line in enumerate(lines):
        if i not in lines_to_remove:
            new_lines.append(line)
    
    return '\n'.join(new_lines)


def show_duplicates(duplicates: List[Dict]) -> None:
    """Display found duplicates to user"""
    if not duplicates:
        print_success("No duplicates found in AGENTS.md")
        return
    
    print(f"\n{Colors.BOLD}Found {len(duplicates)} duplicate text block(s):{Colors.RESET}\n")
    
    for i, dup in enumerate(duplicates, 1):
        print(f"{Colors.YELLOW}Duplicate #{i}:{Colors.RESET}")
        print(f"  First occurrence: line {dup.get('first_occurrence_line', 'unknown')}")
        print(f"  Duplicate locations: lines {', '.join(map(str, dup.get('duplicate_lines', [])))}")
        print(f"  Total occurrences: {dup.get('occurrences', 'unknown')}")
        
        # Show preview of duplicate text (truncated if too long)
        text = dup.get('duplicate_text', '')
        if len(text) > 100:
            preview = text[:97] + "..."
        else:
            preview = text
        
        print(f"  Text preview: {Colors.CYAN}{repr(preview)}{Colors.RESET}")
        print()


def write_agents_file(content: str) -> bool:
    """Write updated content back to AGENTS.md"""
    agents_path = Path("AGENTS.md")
    
    try:
        # Create backup
        backup_path = Path("AGENTS.md.backup")
        if agents_path.exists():
            with open(agents_path, 'r') as f:
                backup_content = f.read()
            with open(backup_path, 'w') as f:
                f.write(backup_content)
        
        # Write new content
        with open(agents_path, 'w') as f:
            f.write(content)
        
        print_success("Updated AGENTS.md successfully")
        print_info(f"Backup saved as {backup_path}")
        return True
        
    except Exception as e:
        print_error(f"Failed to write AGENTS.md: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description='Remove duplicate text from AGENTS.md using OpenAI',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  agentsmd-dedupe                   # Remove duplicates
  agentsmd-dedupe --dry-run         # Preview without changes
  agentsmd-dedupe --verbose         # Show detailed progress
  agentsmd-dedupe --model gpt-4     # Use specific model
        """
    )
    
    parser.add_argument('--dry-run', action='store_true',
                       help='Preview changes without applying them')
    parser.add_argument('--verbose', action='store_true',
                       help='Show detailed progress and API interactions')
    parser.add_argument('--timeout', type=int, default=600,
                       help='Timeout for API calls in seconds (default: 600)')
    parser.add_argument('--model', 
                       help='OpenAI model to use (default: o3 or OPENAI_MODEL env var)')
    parser.add_argument('--max-retries', type=int, default=3,
                       help='Maximum retry attempts for API calls (default: 3)')
    
    args = parser.parse_args()
    
    # Load .env file
    load_env_file()
    
    # Get API key and model
    api_key = get_api_key()
    model = get_model_name(args)
    
    # Read AGENTS.md
    content = read_agents_file()
    if not content:
        sys.exit(1)
    
    print_info(f"Analyzing AGENTS.md ({len(content.split())} words, {len(content.split(chr(10)))} lines)")
    
    # Create prompt
    prompt = create_dedupe_prompt(content)
    
    if args.verbose:
        print_verbose(f"Using model: {model}", args.verbose)
        print_verbose(f"Timeout: {args.timeout}s", args.verbose)
        print_verbose(f"Max retries: {args.max_retries}", args.verbose)
        if args.verbose:
            print_verbose("Prompt preview (first 500 chars):", args.verbose)
            print(prompt[:500] + "...\n")
    
    # Call OpenAI API
    duplicates = call_openai_api(prompt, api_key, model, 
                                args.max_retries, args.timeout, args.verbose)
    
    if duplicates is None:
        print_error("Failed to analyze duplicates")
        sys.exit(1)
    
    # Show duplicates found
    show_duplicates(duplicates)
    
    if not duplicates:
        print_info("No changes needed")
        sys.exit(0)
    
    # Remove duplicates
    if args.dry_run:
        print_info("\n--dry-run mode: No changes will be made")
        print_info(f"Would remove {sum(len(d.get('duplicate_lines', [])) for d in duplicates)} duplicate occurrences")
    else:
        new_content = remove_duplicates(content, duplicates)
        
        # Calculate statistics
        original_lines = len(content.split('\n'))
        new_lines = len(new_content.split('\n'))
        removed_lines = original_lines - new_lines
        
        print_info(f"\nRemoving {removed_lines} duplicate lines...")
        
        # Write updated content
        if write_agents_file(new_content):
            print_success(f"\n✅ Deduplication complete! Removed {removed_lines} lines")
        else:
            sys.exit(1)


if __name__ == "__main__":
    main()
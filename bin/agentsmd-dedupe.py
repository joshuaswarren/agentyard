#!/usr/bin/env python3
"""
agentsmd-dedupe - Remove duplicate text from AGENTS.md using OpenAI

This tool uses OpenAI's API to identify and remove exact duplicate text blocks
from AGENTS.md files, helping keep AI guidance files clean and concise.

Enhanced features:
- Multi-line duplicate detection (2+ consecutive lines)
- LLM-based compression after deduplication
- Configurable compression levels
- Backup to ~/agentyard/backups/<project-name>/
"""

import argparse
import json
import os
import re
import sys
import time
from datetime import datetime
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


def get_project_name() -> str:
    """Get project name from current git repository"""
    try:
        # Try to get the remote origin URL
        result = os.popen('git config --get remote.origin.url').read().strip()
        if result:
            # Extract project name from URL
            # Handle both SSH and HTTPS URLs
            if result.endswith('.git'):
                result = result[:-4]
            project = result.split('/')[-1]
            return project
    except:
        pass
    
    # Fallback to directory name
    return Path.cwd().name


def estimate_tokens(text: str) -> int:
    """Estimate token count (roughly 1 token per word)"""
    return len(text.split())


def create_compression_prompt(content: str, level: str) -> str:
    """Create prompt for LLM-based compression"""
    level_instructions = {
        'light': """Light compression: Remove only obvious redundancy and wordiness while maintaining full clarity.
- Keep all essential information and context
- Simplify verbose explanations
- Remove repeated ideas within sections
- Maintain readability and structure""",
        'moderate': """Moderate compression: Balance between conciseness and completeness.
- Condense explanations to their core points
- Remove redundant examples when pattern is clear
- Combine related points when possible
- Keep critical details and context""",
        'aggressive': """Aggressive compression: Maximum reduction while preserving exact meaning.
- Keep only essential information
- Use most concise phrasing possible
- Remove all redundancy
- Maintain technical accuracy"""
    }
    
    prompt = f"""You are an expert technical writer tasked with compressing an AGENTS.md file.

COMPRESSION LEVEL: {level.upper()}
{level_instructions[level]}

IMPORTANT REQUIREMENTS:
1. Preserve ALL technical information and exact meaning
2. Maintain the file's structure and organization
3. Keep the content readable and understandable for AI coding assistants
4. Do not remove critical implementation details, API references, or configuration
5. Preserve all code blocks, commands, and technical specifications exactly

FILE CONTENT:
{content}

Return the compressed version of the file. The output should be a valid AGENTS.md file that:
- Contains all the same information in fewer words
- Remains perfectly clear to an AI coding assistant
- Preserves all technical accuracy
"""
    
    return prompt


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
3. Consider only text blocks that consist of AT LEAST 2 CONSECUTIVE LINES (not counting blank lines)
4. A text block is duplicate only if it appears word-for-word identical, including whitespace

IMPORTANT RULES:
- Only identify EXACT duplicates (identical character-by-character)
- Ignore case differences - treat them as different
- MULTI-LINE REQUIREMENT: A duplicate must contain at least 2 consecutive non-blank lines
- Single-line duplicates should NOT be flagged (e.g., "**Current Implementation:**" headers)
- Blank lines don't count toward the consecutive line requirement
- Include the entire duplicate block in your response
- If no duplicates exist, return an empty array

FILE CONTENT:
{content}

Return a JSON array where each element represents a duplicate text block:
{{
  "duplicate_text": "The exact text that is duplicated (multi-line)",
  "first_occurrence_line": <line number of first occurrence>,
  "duplicate_lines": [<array of line numbers where duplicates appear>],
  "occurrences": <total number of times this text appears>
}}

Only include blocks that:
1. Appear 2 or more times
2. Contain at least 2 consecutive non-blank lines"""
    
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


def create_backup(content: str, stage: str) -> Optional[Path]:
    """Create backup in ~/agentyard/backups/<project-name>/"""
    project_name = get_project_name()
    timestamp = datetime.now().strftime("%Y-%m-%d-%H%M%S")
    
    # Create backup directory
    backup_dir = Path.home() / "agentyard" / "backups" / project_name
    backup_dir.mkdir(parents=True, exist_ok=True)
    
    # Create backup filename
    backup_file = backup_dir / f"AGENTS.md.{timestamp}.{stage}.backup"
    
    try:
        with open(backup_file, 'w') as f:
            f.write(content)
        print_info(f"Backup saved: {backup_file}")
        return backup_file
    except Exception as e:
        print_error(f"Failed to create backup: {e}")
        return None


def write_agents_file(content: str, backup_stage: str = "final") -> bool:
    """Write updated content back to AGENTS.md"""
    agents_path = Path("AGENTS.md")
    
    try:
        # Create backup
        if create_backup(content, backup_stage) is None:
            return False
        
        # Write new content
        with open(agents_path, 'w') as f:
            f.write(content)
        
        print_success("Updated AGENTS.md successfully")
        return True
        
    except Exception as e:
        print_error(f"Failed to write AGENTS.md: {e}")
        return False


def compress_content(content: str, api_key: str, model: str, level: str, 
                    max_retries: int, timeout: int, verbose: bool) -> Optional[str]:
    """Compress content using LLM"""
    print_info(f"Compressing with {level} level...")
    
    prompt = create_compression_prompt(content, level)
    
    try:
        import openai
    except ImportError:
        print_error("OpenAI package not installed")
        return None
    
    client = openai.OpenAI(api_key=api_key)
    
    retry_count = 0
    while retry_count < max_retries:
        try:
            if verbose:
                print_verbose(f"Sending compression request (attempt {retry_count + 1}/{max_retries})", verbose)
            
            # Build parameters conditionally based on model
            params = {
                "model": model,
                "messages": [
                    {"role": "system", "content": "You are a technical writing expert. Compress the content while preserving all information."},
                    {"role": "user", "content": prompt}
                ],
                "timeout": timeout
            }
            
            # Only add temperature for non-o3 models
            if not model.startswith('o3'):
                params["temperature"] = 0.3
            
            response = client.chat.completions.create(**params)
            
            compressed = response.choices[0].message.content
            return compressed
                
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


def main():
    parser = argparse.ArgumentParser(
        description='Remove duplicate text from AGENTS.md using OpenAI',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  agentsmd-dedupe                   # Remove duplicates + moderate compression
  agentsmd-dedupe --dry-run         # Preview without changes
  agentsmd-dedupe --verbose         # Show detailed progress
  agentsmd-dedupe --model gpt-4     # Use specific model
  agentsmd-dedupe --skip-compression  # Only deduplicate, no compression
  agentsmd-dedupe --compression-level aggressive  # Maximum compression
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
    parser.add_argument('--skip-compression', action='store_true',
                       help='Skip compression step after deduplication')
    parser.add_argument('--compression-level', 
                       choices=['light', 'moderate', 'aggressive'],
                       default='moderate',
                       help='Compression level (default: moderate)')
    
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
    
    # Check file size
    token_count = estimate_tokens(content)
    if token_count > 200000:
        print_error(f"AGENTS.md exceeds maximum size of 200,000 tokens (estimated: {token_count:,} tokens)")
        print_info("Please reduce file size before deduplication.")
        sys.exit(1)
    
    print_info(f"Analyzing AGENTS.md ({len(content.split())} words, {len(content.split(chr(10)))} lines, ~{token_count:,} tokens)")
    
    # Create initial backup
    if not args.dry_run:
        create_backup(content, "pre-dedupe")
    
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
        
        # Show compression preview if not skipped
        if not args.skip_compression:
            print_info(f"\nWould then apply {args.compression_level} compression")
    else:
        new_content = remove_duplicates(content, duplicates)
        
        # Calculate deduplication statistics
        original_lines = len(content.split('\n'))
        new_lines = len(new_content.split('\n'))
        removed_lines = original_lines - new_lines
        original_tokens = estimate_tokens(content)
        deduped_tokens = estimate_tokens(new_content)
        
        print_info(f"\nRemoving {removed_lines} duplicate lines...")
        print_info(f"Token reduction from deduplication: {original_tokens:,} → {deduped_tokens:,} ({original_tokens - deduped_tokens:,} tokens saved)")
        
        # Save post-dedupe backup
        if duplicates:
            create_backup(new_content, "post-dedupe")
        
        # Apply compression unless skipped
        final_content = new_content
        if not args.skip_compression:
            compressed_content = compress_content(
                new_content, api_key, model, args.compression_level,
                args.max_retries, args.timeout, args.verbose
            )
            
            if compressed_content:
                final_content = compressed_content
                compressed_tokens = estimate_tokens(final_content)
                print_info(f"\nToken reduction from compression: {deduped_tokens:,} → {compressed_tokens:,} ({deduped_tokens - compressed_tokens:,} tokens saved)")
                print_info(f"Total token reduction: {original_tokens:,} → {compressed_tokens:,} ({(1 - compressed_tokens/original_tokens)*100:.1f}% reduction)")
            else:
                print_warning("Compression failed, keeping deduplicated content")
        
        # Write final content
        if write_agents_file(final_content, "final"):
            if args.skip_compression:
                print_success(f"\n✅ Deduplication complete! Removed {removed_lines} lines")
            else:
                print_success(f"\n✅ Deduplication and compression complete!")
                print_success(f"Removed {removed_lines} duplicate lines and compressed content")
        else:
            sys.exit(1)


if __name__ == "__main__":
    main()
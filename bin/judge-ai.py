#!/usr/bin/env python3
"""
judge-ai.py - AI helper for the judge command
Handles LLM loading and inference for PR reviews
"""

import sys
import json
import yaml
import os
from pathlib import Path
from typing import Dict, Any, Optional
import argparse

try:
    from llama_cpp import Llama
except ImportError:
    print("Error: llama-cpp-python not installed", file=sys.stderr)
    sys.exit(1)


def load_config(config_path: str) -> Dict[str, Any]:
    """Load configuration from YAML file"""
    try:
        config_path = os.path.expanduser(config_path)
        with open(config_path, 'r') as f:
            return yaml.safe_load(f)
    except Exception as e:
        print(f"Error loading config: {e}", file=sys.stderr)
        # Return default config
        return {
            "model": {
                "name": "mistral-small-2409",
                "path": "~/.agentyard/models/mistral-small-2409.gguf",
                "context_size": 32768,
                "gpu_layers": -1,
                "temperature": 0.1,
                "max_tokens": 4096
            },
            "review": {
                "max_diff_lines": 1000,
                "include_pr_description": True,
                "output_format": "markdown"
            }
        }


def create_review_prompt(pr_data: Dict[str, Any], diff_content: str) -> str:
    """Create the prompt for code review"""
    system_prompt = """You are an expert code reviewer called "Judge". Your role is to:
1. Identify bugs, security issues, and logic errors
2. Suggest improvements for code quality and maintainability
3. Acknowledge good practices and well-written code
4. Focus on actionable, specific feedback
5. Be constructive and professional in tone

Review the following pull request and provide detailed feedback."""

    pr_title = pr_data.get('title', 'Untitled PR')
    pr_description = pr_data.get('body', 'No description provided')
    
    user_prompt = f"""PR Title: {pr_title}
Description: {pr_description}

Changed Files:
{', '.join(pr_data.get('files', []))}

Diff:
{diff_content}

Please provide a comprehensive code review with:
- Summary of critical issues, important concerns, and suggestions
- Detailed file-by-file analysis with line references
- Positive feedback on well-written code
- Actionable recommendations for improvements"""

    return system_prompt, user_prompt


def format_review_output(response: str) -> str:
    """Format the AI response into structured markdown"""
    # The model should already return well-formatted markdown,
    # but we can add additional formatting if needed
    
    if not response.strip().startswith("#"):
        # Add header if missing
        response = f"## AI Code Review\n\n{response}"
    
    return response


def run_review(config_path: str, pr_data_json: str, diff_content: str, 
               model_override: Optional[str] = None) -> None:
    """Run the AI review on the PR"""
    try:
        # Load configuration
        config = load_config(config_path)
        model_config = config['model']
        
        # Override model if specified
        if model_override:
            model_config['name'] = model_override
        
        # Expand model path
        model_path = os.path.expanduser(model_config['path'])
        
        # Check if model file exists
        if not os.path.exists(model_path):
            print(f"Error: Model file not found at {model_path}", file=sys.stderr)
            print("Please download the model or update the path in your config.", file=sys.stderr)
            print("\nTo download models:", file=sys.stderr)
            print("  1. Visit https://huggingface.co/", file=sys.stderr)
            print("  2. Search for GGUF models (e.g., 'mistral-small gguf')", file=sys.stderr)
            print("  3. Download a quantized version (e.g., Q4_K_M)", file=sys.stderr)
            print(f"  4. Save to {model_path}", file=sys.stderr)
            sys.exit(1)
        
        # Parse PR data
        pr_data = json.loads(pr_data_json)
        
        # Create prompt
        system_prompt, user_prompt = create_review_prompt(pr_data, diff_content)
        
        # Initialize model with progress indicator
        print("🤖 Loading AI model...", file=sys.stderr)
        llm = Llama(
            model_path=model_path,
            n_ctx=model_config.get('context_size', 32768),
            n_gpu_layers=model_config.get('gpu_layers', -1),
            verbose=False
        )
        
        # Run inference
        print("🔍 Analyzing code changes...", file=sys.stderr)
        response = llm.create_chat_completion(
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=model_config.get('temperature', 0.1),
            max_tokens=model_config.get('max_tokens', 4096),
            stream=False
        )
        
        # Extract and format the response
        review_text = response['choices'][0]['message']['content']
        formatted_review = format_review_output(review_text)
        
        # Output the review
        print(formatted_review)
        
    except Exception as e:
        print(f"Error during AI review: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description='AI helper for judge PR reviewer')
    parser.add_argument('config_path', help='Path to configuration file')
    parser.add_argument('pr_data', help='PR data as JSON')
    parser.add_argument('diff_content', help='Diff content')
    parser.add_argument('--model', help='Model override', default=None)
    
    args = parser.parse_args()
    
    run_review(args.config_path, args.pr_data, args.diff_content, args.model)


if __name__ == '__main__':
    main()

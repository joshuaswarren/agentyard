# Judge Command Guide

The `judge` command provides AI-powered pull request reviews using a local LLM. It analyzes code changes and provides actionable feedback on bugs, security issues, code quality, and best practices.

## Overview

Judge integrates seamlessly with the agentyard workflow, using the GitHub CLI to fetch PR data and a local LLM (like Mistral or similar) to perform code reviews. It's designed to run entirely locally, keeping your code private while providing high-quality reviews.

## Installation

### Prerequisites

1. **GitHub CLI (`gh`)**: Install from https://cli.github.com/
   ```bash
   # macOS
   brew install gh
   
   # Linux
   # See https://github.com/cli/cli/blob/trunk/docs/install_linux.md
   ```

2. **Python 3.7+**: Required for LLM integration
   ```bash
   python3 --version  # Check if installed
   ```

3. **Authenticate with GitHub**:
   ```bash
   gh auth login
   ```

### First Run

The `judge` command will automatically:
- Install required Python packages (`llama-cpp-python`, `PyYAML`, `requests`, `psutil`)
- Install `llama-cpp-python` with Metal support on macOS
- Prompt you to create a configuration file if one doesn't exist

### Initial Setup

1. **Create Configuration**:
   ```bash
   judge --init-config
   ```
   This creates a default configuration file at `~/.agentyard/judge.yaml`

2. **Set Model Path** (optional):
   ```bash
   # Option 1: Environment variable (affects all models)
   export AGENTYARD_MODELS_PATH="/path/to/models"
   
   # Option 2: Edit config file
   # See Configuration section below
   ```

3. **Download a Model**:
   When you first run `judge`, it will:
   - Check if the specified model exists locally
   - Search HuggingFace for available GGUF versions
   - Recommend a quantization based on your system specs
   - Offer to download the model automatically

## Basic Usage

### Review a Pull Request by Number
```bash
judge 45
```

### Review a Pull Request by Branch Name
```bash
judge feature/new-login-system
```

### Use a Specific Model
```bash
judge 45 --model mistral-small-2409
```

### Use a Custom Configuration
```bash
judge 45 --config ~/my-judge-config.yaml
```

### Create a Configuration File
```bash
# Create default config in current directory
judge --init-config

# Create config at specific location
judge --init-config ~/custom-judge.yaml
```

## Configuration

Judge uses a YAML configuration file located at `~/.agentyard/judge.yaml` by default. See `docs/judge-config-sample.yaml` for a complete example with all options.

### Model Path Resolution

Judge resolves model paths in the following order:
1. **Per-model path** in config file (highest priority)
2. **Environment variable**: `$AGENTYARD_MODELS_PATH/<model>.gguf`
3. **Config file setting**: `models_dir` value
4. **Default**: `~/.agentyard/models/<model>.gguf`

### Basic Configuration
```yaml
# Judge AI PR Reviewer Configuration

model:
  name: "mistral-small-2409"
  context_size: 32768
  gpu_layers: -1  # Use all GPU layers on Metal
  temperature: 0.1
  max_tokens: 4096

# Global models directory
models_dir: "~/.agentyard/models"

# Per-model overrides (optional)
models:
  "codellama-7b":
    path: "/custom/path/to/codellama.gguf"

review:
  max_diff_lines: 1000
  include_pr_description: true
  output_format: "markdown"

github:
  default_remote: "origin"
```

### Model Management

#### Automatic Model Download
Judge can automatically download models from HuggingFace:

1. **Run judge with any model name**:
   ```bash
   judge 45 --model mistralai/Mistral-7B-Instruct-v0.2
   ```

2. **Judge will**:
   - Search HuggingFace for GGUF versions
   - Detect your system specs (RAM, GPU)
   - Recommend the best quantization
   - Download with progress indicator

#### Manual Model Setup
1. **Download a Model**: 
   - Visit https://huggingface.co/
   - Search for GGUF format models (e.g., "mistral-small gguf")
   - Download a quantized version based on your system:
     - High-end (32GB+ RAM): Q8_0, Q6_K
     - Mid-range (16-24GB): Q5_K_M, Q4_K_M
     - Low-end (<16GB): Q4_K_M, Q3_K_M

2. **Configure Model Path**:
   ```bash
   # Option 1: Environment variable
   export AGENTYARD_MODELS_PATH="/path/to/models"
   
   # Option 2: Edit config file
   # Add to models section for specific model
   ```

### Performance Tuning

- **context_size**: Larger values allow reviewing bigger PRs but use more memory
- **gpu_layers**: Control GPU memory usage by limiting layers
- **max_tokens**: Maximum length of the review output
- **temperature**: Lower values (0.1-0.3) for more focused, deterministic reviews

## Output Format

Judge provides structured markdown output with:

- **Summary Section**: High-level overview of issues found
- **Severity Levels**:
  - 🔴 Critical: Bugs, security issues, data loss risks
  - 🟡 Important: Performance issues, missing tests, bad practices
  - 🟢 Suggestions: Code improvements, refactoring opportunities
  - ✅ Positive: Well-written code acknowledgments
- **File-by-File Analysis**: Detailed feedback with line references
- **Actionable Recommendations**: Specific fixes and improvements

### Example Output
```markdown
## AI Code Review for PR #45: "Add payment processing"

### Summary
- 🔴 **1 Critical Issue**: SQL injection vulnerability
- 🟡 **2 Important**: Missing error handling, no tests
- 🟢 **3 Suggestions**: Use type hints, simplify logic
- ✅ **2 Positive**: Good logging, follows style guide

### Detailed Review

#### `payments.py`
**Line 23** 🔴 Critical
\```python
query = f"SELECT * FROM payments WHERE id = {payment_id}"
\```
**Issue**: SQL injection vulnerability
**Fix**: Use parameterized queries:
\```python
query = "SELECT * FROM payments WHERE id = ?"
cursor.execute(query, (payment_id,))
\```
...
```

## Advanced Usage

### Large Pull Requests

For PRs with more than 1000 lines of changes, judge will automatically truncate the diff. You can adjust this limit in the configuration:

```yaml
review:
  max_diff_lines: 2000  # Increase limit
```

### Saving Reviews

To automatically save reviews to disk:
```bash
export JUDGE_SAVE_REVIEWS=1
judge 45
# Saves to ~/.agentyard/reviews/pr-45-YYYYMMDD-HHMMSS.md
```

### Integration with Agentyard Workflow

Judge works well within the starttask/finishtask workflow:

```bash
# Start working on a PR
starttask myproject pr-45-fixes

# Review the PR you're working on
judge 45

# Use the feedback to improve your changes
# ... make changes based on review ...

# Review again before pushing
judge 45

# Complete the task
finishtask
```

## Troubleshooting

### "Model file not found"
- Run `judge --init-config` to create configuration
- Judge will offer to download the model automatically
- Or manually download a GGUF model and set the path

### "gh not authenticated"
```bash
gh auth login
```

### "llama-cpp-python installation failed"
On macOS:
```bash
# Ensure Xcode command line tools are installed
xcode-select --install

# Try manual installation with Metal support
CMAKE_ARGS="-DLLAMA_METAL=on" pip3 install llama-cpp-python --upgrade --force-reinstall --no-cache-dir
```

On Linux:
```bash
# For CPU only
pip3 install llama-cpp-python

# For CUDA support
CMAKE_ARGS="-DLLAMA_CUDA=on" pip3 install llama-cpp-python --upgrade --force-reinstall --no-cache-dir
```

### "No open PR found for branch"
- Ensure the PR exists and is open
- Check you're using the correct branch name
- Try using the PR number instead

### Performance Issues
- Reduce `context_size` in configuration
- Use a smaller quantized model (Q4_K_S instead of Q4_K_M)
- Limit `gpu_layers` if running out of GPU memory
- Increase `max_diff_lines` to handle larger PRs

## Model Recommendations

### Code-Focused Models
1. **Mistral Small**: Good balance of speed and quality
2. **CodeLlama**: Specialized for code understanding
3. **DeepSeek Coder**: Strong code analysis capabilities
4. **Qwen 2.5 Coder**: Excellent for multi-language projects

### Quantization Levels
- **Q8_0**: Best quality, largest size
- **Q4_K_M**: Recommended - good quality/size balance
- **Q4_K_S**: Smaller, slightly lower quality
- **Q3_K_M**: Fastest, acceptable for quick reviews

## Best Practices

1. **Review Early and Often**: Run judge on draft PRs to catch issues early
2. **Focus on Critical Issues**: Address 🔴 and 🟡 items first
3. **Combine with Human Review**: Use as a first pass before human review
4. **Customize Prompts**: Modify the system prompt in `judge-ai.py` for specific needs
5. **Keep Models Updated**: Newer models often provide better reviews

## Privacy and Security

- **Fully Local**: All processing happens on your machine
- **No Data Sharing**: Your code never leaves your system
- **Secure Storage**: Model files are stored locally
- **GitHub Token**: Only used to fetch PR data via official gh CLI

## Contributing

To improve the judge command:

1. Test with various PR types and sizes
2. Report issues with false positives/negatives
3. Suggest prompt improvements
4. Add support for more models
5. Contribute model configuration presets

## See Also

- [Agentyard Starttask/Finishtask Guide](starttask-finishtask-guide.md)
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [llama.cpp Documentation](https://github.com/ggerganov/llama.cpp)
- [Mistral AI Models](https://docs.mistral.ai/)
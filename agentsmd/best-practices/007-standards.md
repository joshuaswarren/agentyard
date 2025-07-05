## Standards You Must Follow When Working on This Repository

### General Formatting
- You must ensure all lines are 120 characters or less.

### Testing
- Add test coverage for all functions/code. Ideally in a Test Driven Development manner - i.e., defining tests based on the specification for the feature you're about to implement, then implement the feature and make sure the test passes. Please ensure we have 90% test coverage of all code.
- Before attempting to finish your work or commit your work, please run the pre-commit hooks and ensure you resolve any errors.
- All tests MUST pass before you submit a pull request. Pull requests cannot be merged with a failing test. 

#### A quick gut-check: **“Will I care if this fails?”**
1. **Picture tomorrow’s you** opening a failing GitHub run.
   *If that red X pops up, would you stop what you’re doing to fix it, or just shrug and hit “re-run”?*
   If you’d fix it, the test is valuable. If you’d ignore it, delete it or don’t write it.

2. **Ask three fast questions (30 seconds total):**
   1. **Does it protect money or reputation?**  (prices, payments, emails, security, data loss)
   2. **Could this fail silently in production?**  A silent failure (wrong numbers, hidden data loss, broken edge-case path) hurts more than a loud crash you’ll notice right away. If the answer is “yes,” write the test.
   3. **Has this broken before—or is it easy to break?**  Risky or flaky code earns a test.
   Two “yes” answers → write the test. Fewer → reconsider.

#### What to test first

| Priority                 | Examples                                                             | Why                                       |
| ------------------------ | -------------------------------------------------------------------- | ----------------------------------------- |
| **1. Public contracts**  | Function/class that other modules call, CLI entry points, API routes | Breakage here breaks *users*.             |
| **2. Business rules**    | Tax calc, discount logic, authorization checks                       | Silent errors cost money & trust.         |
| **3. Edge cases**        | Empty list, None, max int, weird encodings                         | These fail in production first.           |
| **4. Regression ghosts** | Anything that has ever 500’d, NPE’d, or woken you at 2 AM            | History repeats unless you lock the door. |

(Lower-level helpers often ride for free because higher-level tests cover them.)

#### Write tests that don’t annoy future you

* **FAST**: < 100 ms each. Skip the DB unless you really need it.
* **ISOLATED**: Set up exactly what the test needs, nothing else.
* **REPEATABLE**: No randomness, no time-of-day surprises—freeze time, seed RNGs.
* **SELF-VALIDATING**: assert once, no print debugging.
* **TIMELY**: Write it while the code is fresh; tomorrow you’ll forget the edge cases.

(Yes, that spells **F.I.R.S.T.**—easy mnemonic.)

#### Practical workflow (5-minute micro-actions)

1. **Before coding a new feature**
   * Jot one sentence: “It should *do X when Y*.”
   * Convert that sentence into a test name test_does_x_when_y.
   * Write the assertion stub (assert …) and leave it failing.

2. **After the code is green locally**
   * Run pytest -q (seconds).
   * Commit, push, let GitHub run the full suite.

3. **If the suite drags (>60 s)**
   * Profile; anything slow moves behind a marker (@pytest.mark.slow) and runs only in CI.

4. **When a bug slips through**
   * Reproduce it with a new failing test **first**, then fix the code.
   * This turns every production bug into a future guardrail.

#### Tiny habits to level-up testing

* **Name tests as documentation**: reading the file should tell a story.
* **Use fixtures sparingly**: over-abstracted fixtures hide intent; prefer inline setup until you repeat it thrice.
* **One assert per logical idea**: multiple asserts are fine if they validate the same behavior; otherwise split.
* **Kill flaky tests immediately**: nothing erodes trust faster. Fix or delete.
* **Review tests like code**: a bad test is technical debt.

Write tests that **protect value, catch real bugs, and stay out of the way**.
If a failing test would make you care, it’s worth the 5 minutes to write it—future you (and your CI runs) will thank you.

### Python Code
- Follow Python best practices
- Utilize Python 3.12
- Follow PEP 8 
- Make sure all of the code you write follows PEP8, and that it will pass black, isort, mypy tests.

### PHP Code
- Follow PHP best practices
- Follow PSR-12

### Bash Scripts

### Documentation
- The docs folder contains important documentation. 
- Please keep documentation written for users and human developers in docs/humans/
- Please keep documentation written for LLMs in docs/ai/

### Roadmap File
- See @docs/Roadmap.md for current status and next steps. 

### Progress Files
- Create individual progress files in the docs/progress/ directory after completing work, following the below format. Use today's actual UTC date and time in the filename.
- Use individual progress files to record changes, which are then compiled into progress.md. This system prevents merge conflicts and maintains a clear development history.
- These files will be merged into @docs/progress.md automatically. 

#### When to Create a Progress File
- Read the current progress.md before starting work to avoid duplicate efforts
- After completing a task, bug fix, or feature, create a new progress file
- Use today's UTC date and current time in the filename

File Naming Convention

Format: YYYY-MM-DD-HH-MM-SS-brief-description.md
Example: 2025-06-29-14-30-00-fix-node-exporter-error.md

File Content Format

### YYYY-MM-DD - Short description of the change
- **Issue**: Brief description of the problem (if applicable)
- **Root cause**: Why the issue occurred (if applicable)
- **Fix**: What was done to resolve it
- **Files changed**: List of modified files
- **Result**: The outcome of the change
Example Progress File

File: progress/2025-07-01-10-15-00-add-progress-system.md

### 2025-07-01 - Implemented individual progress file system
- **Issue**: Frequent merge conflicts in progress.md when multiple PRs modify it
- **Root cause**: All contributors editing the same file simultaneously
- **Fix**: Created individual progress files that compile into progress.md
- **Files changed**: 
  - `progress/` directory structure
  - `docs/progress-guide.md`
  - `scripts/compile_progress.py`
  - `AGENTS.md`
- **Result**: Contributors can record progress without merge conflicts

#### Progress File Best Practices
- One progress file per logical change or PR
- Keep descriptions concise but informative
- Include issue numbers when applicable (e.g., "Fixes #123")

### Libraries

- Don't reinvent the wheel. Use libraries and open source projects where possible. 
- Make sure to use the latest stable version (don't assume your knowledge is accurate, search the web for the latest version). 


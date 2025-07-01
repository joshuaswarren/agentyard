Please implement Github issue $ARGUMENTS: review the issue and any comments on the issue or linked issues, think through a plan, then iterate in this loop —
1) post a progress comment with your plan and decisions on the GitHub issue;  
2) implement the feature;  
3) write tests for it;  
4) add any relevant documentation for it;
4) run pre-commit hooks and the full test suite locally and ensure all pass;  
5) push your work to a new feature branch and open a pull request;  
6) monitor the GitHub Actions run, and if any tests fail, return to step 1 to fix them—repeat until the pull request shows all checks green and is ready to merge. Make sure it merges - your work isn't done until it's merged.  

When creating the pull request on GitHub, please enable auto-merge (squash) so that it will automatically merge the pull request once the tests pass. Also ensure that there are no merge conflicts that block it from being merged.

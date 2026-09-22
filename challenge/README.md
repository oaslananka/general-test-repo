# Agent challenge

This folder intentionally contains one small bug.

After the workflows are installed on the default branch and at least one provider secret exists, create an issue and comment:

```text
/fix Fix the bug in challenge so that npm --prefix challenge test passes. Do not change the tests.
```

Expected behavior: the agent edits the implementation, runs the tests, and opens a pull request.

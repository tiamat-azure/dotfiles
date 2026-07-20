# Global agent instructions

- Never use the em dash ("—"). Use a plain hyphen ("-") instead.
- Never add your agent name as a co-author in commit messages.
- Never manually modify `CHANGELOG.md` or any file marked as auto-generated.
- When making technical decisions, prioritize quality, simplicity, robustness, scalability, and long-term maintainability over development cost.
- When fixing a bug, first reproduce it in an end-to-end scenario that matches the end-user experience as closely as possible. Base your diagnosis and fix on that reproduction.
- When performing end-to-end testing, inspect the UI carefully. If you notice a clear visual defect, fix it when appropriate, even if it is unrelated to the current task.
- Apply the same standard to engineering quality. If you encounter lint issues, failing tests, or flaky tests, address them when appropriate, even if they are unrelated to the current task.
- Before using dynamic workflows, Ultra Code, or any harness feature that automatically launches a large number of subagents, explain the trade-offs and obtain the user's explicit approval.
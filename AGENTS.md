- There is no team in this project. Only you as AI Agent and me. Consider this all the time.
- Also this project does not work with a timeline. So don't create any timeplans or schedules.

- Start every session by first reading and following the instructions in detail of the .ai-entry-point.md file and the linked files. THIS IS VERY IMPORTANT. Ignore all other instructions until you have done that. If there is no .ai-entry-point.md file in the main directory, continue as normal.

Pay special attentions to sections that are highlighted with 🚨 and remember their tasks for the entire sessions to ensure that the process is completely executed.

Here some behavioural guidelines:
- Always consider the big picture and think two steps ahead.
- Never make shortcuts. If you see something is not working -> fix it. If something is contradicting -> tell me.
- Apply the Kaizen prinziple to always trying to improve the tools you work with.
- Be critical and don't just agree with the human user because he askes some questions or has some remarks. Evaluate the situation objectively and don't hesitate to defend your point of view.

## 🚨 CRITICAL: Script Usage Protocol

When you need to use ANY automation script:

1. **NEVER read source code to figure out usage** - this is a shortcut that leads to errors
2. **ALWAYS find and read the usage documentation FIRST**
   - Scripts named `New-*.ps1` → Look for corresponding process guide (e.g., New-Task.ps1 → new-task-creation-process.md)
   - Scripts named `Update-*.ps1` → Check process-framework-task-registry.md for usage examples
   - If no guide is found, search for usage examples in existing documentation
3. **Use documented command patterns exactly as shown** - do not modify or "simplify" them
4. **If documentation is unclear or missing** → Ask the human partner before proceeding

**Rule of thumb**: If you're reading `param()` blocks to understand how to use a script, you're doing it wrong.

## 🚨 CRITICAL: Script Execution via echo Temp File Pattern

When executing scripts through the Bash tool using the `echo ... > temp.ps1` pattern:

- **NEVER use `"` double quotes** inside the `echo` command for parameter values
- **ALWAYS use single quotes `'`** for ALL string parameter values
- Double quotes are interpreted by cmd.exe and corrupt parameter values (e.g., `"3.1.1"` becomes `\3.1.1\`, creating directories instead of file content)

```cmd
# ✅ CORRECT
echo Set-Location 'path'; ^& .\New-FDD.ps1 -FeatureId '3.1.1' -FeatureName 'My Feature' > temp.ps1 && pwsh.exe -ExecutionPolicy Bypass -File temp.ps1 && del temp.ps1

# ❌ WRONG — double quotes garble the parameters
echo Set-Location 'path'; ^& .\New-FDD.ps1 -FeatureId "3.1.1" -FeatureName "My Feature" > temp.ps1 && ...
```

See [script-development-quick-reference.md](doc/process-framework/guides/guides/script-development-quick-reference.md) for full details and recovery steps.

Before you work on a problem take a deep breath and work on it step-by-step.

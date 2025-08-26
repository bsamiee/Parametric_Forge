# Context Window Prime

IMPORTANT: Do not skip any step in the task list, follow it EXACTLY, you will complete all steps, and learn along the way
IMPORTANT: CRITICAL: Proactively use mcp_filesystem, ripgrep, and fd to find tool usage
IMPORTANT: CRITICAL: Proactively use perplexity, exa, context7 and github mcp's for research related steps

**ARGUMENTS PARSING:**
Extract from "$ARGUMENTS":
1. `package_file` - Required: Path to nix file in 01.home/01.packages/
2. `target_tool` - Required: Specific tool to focus on

**MODALITY**
- This command will be used either for tool refactoring and sanity checking OR tool implementation

## NOTES
- Tool ocnfigs are spread across 01.home/xdg.nix, 01.home/environment.nix, 01.home/file-management.nix, 01.home/tokens.nix files
- Tool configs can exist in either dirs: 01.home/00.core/configs (as a file to be deployed by file-management.nix) or 01.home/00.core/programs as .nix file to be configured and deployed by home-manager (only tools viable for this are here)
- Tool aliases ALWAYS must be placed in 01.home/00.core/aliases in appropriate existing file or justified new file

## TASKS

**PHASE 1 - RESEARCH**

- 1. RUN: mcp__perplexity-ask__perplexity_ask for broad research on tool
- 2. RUN: mcp__tavily__tavily-search for specific targeted information query's
- 3. RUN: mcp__tavily__tavily-crawl and/or mcp__exa__crawling_exa for expanded search
- 4. RUN: mcp__tavily__tavily-extract, for extraction of information
- 5. RUN: mcp__context7__resolve-library-id + mcp__context7__get-library-docs for documentation
- 6. RUN: mcp__github__search_repositories + mcp__github__search_code + mcp__github__get_file_contents for github information (potentially)

**PHASE 2 - ACTION**

IMPORTANT: First identify all files to place or refactor settings (xdg's, file-management, environments, configs/ programs/) relevant to the tool - if refactoring search for existing settings, if new implementation, identify appropriate place to insert.

ORDER OF CONFIG SETTING REFACTOR OR IMPLEMENTATION:
- 1. FIRST: ENV Variables in 01.home/environment.nix
- 2. SECOND: XDG configuration in 01.home/environment.nix
- 3. THIRD: Configurations ettings EITHER in: 01.home/00.core/configs and/OR 01.home/00.core/programs (some tools may be in both places)
- 4. FOURTH: File deployment (if relevant) in 01.home/file-management.nix
- 5. FIFTH: Final sanity check - IMPORTANT: do another quick research of tool configuration and settings - review all prior work done, ensure no fake settings, missed env variables, settings, or file deployment

IMPORTANT: Always verify findings, never assume or guess anything - WITHOUT VERIFICATION YOU WILL NOT SUGGEST SOMETHING - NEVER FORGET THIS
IMPORTANT: CRITICAL: Aggresively cache earlier directory knowledge, retain a minimum of 75% context window by the end of priming


**PARAMETRIC TOOL CONFIGURATION ORCHESTRATOR**

Think deeply about this multi-phase tool configuration pipeline. You are orchestrating a sophisticated parallel agent workflow to properly integrate tools into Parametric Forge.

**Variables:**

package_file: $ARGUMENTS
tool_filter: $ARGUMENTS (optional, defaults to all)
wave_size: $ARGUMENTS (optional, defaults to 5)

**ARGUMENTS PARSING:**
Parse the following from "$ARGUMENTS":
1. `package_file` - Path to nix file in 01.home/01.packages/ containing tools
2. `tool_filter` - Optional regex pattern to filter specific tools
3. `wave_size` - Number of parallel agents per wave (1-10, default 5)

**PHASE 0: CONFIGURATION RECONNAISSANCE**
Before any agent deployment, the orchestrator MUST:
1. Read the specified package_file to extract all tool names
2. Apply tool_filter if provided to narrow scope
3. **CRITICAL**: Scan existing configurations to identify already-configured tools:
   - Check 01.home/00.core/programs/*.nix for existing tool configurations
   - Check 01.home/00.core/configs/* for existing config files
   - Check 01.home/xdg.nix for existing XDG entries
   - Check 01.home/environment.nix for existing env vars
   - Check 01.home/file-management.nix for deployed configs
4. Create exclusion list of already-configured tools
5. Generate final tool list (requested tools - configured tools)

**PHASE 1: PARALLEL RESEARCH WAVE**
Deploy Research Agents to gather comprehensive tool information:

**Research Agent Distribution:**
- Deploy up to `wave_size` agents simultaneously
- Each agent assigned 1-3 tools based on total tool count
- Agents work completely in parallel for maximum speed

**Research Agent Task Specification:**
```
TASK: Research configuration requirements for [TOOL_NAME]

You are Research Agent [X] investigating [TOOL_NAME].

THINKING DIRECTIVE: Before executing, think deeply about:
- Which research sources will yield the most relevant information
- How to efficiently parallelize searches
- What configuration patterns this tool likely follows

RESEARCH PRIORITIES:
1. Configuration file formats and locations (check --help, man pages, docs)
2. XDG Base Directory support (does it respect XDG_CONFIG_HOME?)
3. Environment variables (both required and optional)
4. Home-manager module availability (search nixpkgs for home.programs.toolname)
5. File locations and naming conventions
6. Dependencies and integration points
7. Platform-specific requirements (Darwin vs Linux differences)

SURGICAL TOOL SELECTION:
- For CLI tools: perplexity-ask (overview) + github (dotfiles)
- For complex tools: tavily (official docs) + exa (deep configuration)
- For documentation: context7 (library docs) + github (examples)
- For nix integration: github (search "home.programs.TOOLNAME")

SUCCESS CRITERIA:
- Found concrete configuration file format ✓
- Identified XDG compliance (yes/no) ✓
- Located at least 3 example configs ✓
- Determined home-manager support ✓

DELIVERABLE: Comprehensive report with:
- Configuration file format (TOML/YAML/JSON/custom)
- XDG compliance status
- Complete env var list
- Home-manager support status
- Example configurations
- Platform differences
- Confidence score (1-10) for each finding
```

**PHASE 2: PARALLEL PLANNING WAVE**
Deploy Planning Agents to design integration strategy:

**Planning Agent Task Specification:**
```
TASK: Design Parametric Forge integration for [TOOL_NAME]

You are Planning Agent [Y] processing research for [TOOL_NAME].

INPUT: Research report from Phase 1

THINKING DIRECTIVE: Before planning, think deeply about:
- Does this tool justify its own file or belong in existing file?
- What's the minimal viable configuration?
- Which platform conditionals are necessary?

PLANNING REQUIREMENTS:
1. Determine configuration location following separation of concerns:
   - programs/ if home-manager module exists
   - configs/ for manual configuration files
   - Both if tool needs custom configs beyond home-manager

2. File placement strategy:
   - Existing file (shell-tools.nix, dev-tools.nix) vs new file
   - Justification: >10 options OR unique domain = new file

3. XDG deployment planning:
   - xdg.configFile entries for ~/.config/
   - home.file entries for ~/.*

4. Environment variable organization:
   - Group with related tools in environment.nix
   - Use mkIf for conditional platform vars

5. File management entries:
   - Asset deployment via myLib.build.deployDir
   - Individual config files via xdg/home.file

SUCCESS CRITERIA:
- Clear file placement decision ✓
- Valid nix syntax in drafts ✓
- No conflicting definitions ✓
- Platform conditionals identified ✓

DELIVERABLE: Implementation plan with:
- Target files and sections
- Exact nix expressions (draft)
- Integration points
- Platform conditionals
- Confidence score (1-10) for placement decision
```

**PHASE 3: PARALLEL VALIDATION WAVE**
Deploy Validation Agents to verify and correct plans:

**Validation Agent Task Specification:**
```
TASK: Validate and correct configuration for [TOOL_NAME]

You are Validation Agent [Z] reviewing plans for [TOOL_NAME].

INPUT: Planning documents from Phase 2

THINKING DIRECTIVE: Before validating, think deeply about:
- Are the nix expressions actually valid?
- Will this conflict with existing configurations?
- Is the separation of concerns properly followed?

VALIDATION CHECKLIST:
1. Configuration accuracy:
   - Verify all option names against official docs
   - Validate nix syntax and attribute paths
   - Check home-manager option compatibility

2. Path correctness:
   - Ensure XDG paths follow spec
   - Verify file deployment targets exist
   - Check platform-specific path differences

3. Integration safety:
   - No duplicate definitions
   - No conflicting environment variables
   - Proper mkIf conditionals for platform

4. Separation of concerns compliance:
   - Programs in programs/
   - Configs in configs/
   - XDG in xdg.nix
   - Env vars in environment.nix
   - Files in file-management.nix

CORRECTIONS: Fix any issues found:
- Invalid option names
- Incorrect paths
- Missing platform conditionals
- Duplicate definitions

SUCCESS CRITERIA:
- All nix syntax validated ✓
- No path conflicts found ✓
- Platform conditionals verified ✓
- Separation of concerns confirmed ✓

DELIVERABLE: Validated configuration with all corrections applied
```

**PHASE 4: PARALLEL ENFORCEMENT WAVE**
Deploy Enforcement Agents for final standardization:

**Enforcement Agent Task Specification:**
```
TASK: Enforce Parametric Forge standards for [TOOL_NAME] configs

You are Enforcement Agent [W] standardizing [TOOL_NAME] integration.

INPUT: Validated configurations from Phase 3

THINKING DIRECTIVE: Before enforcement, think deeply about:
- Which comments are truly essential vs noise?
- Is the code organization optimal?
- Are all imports actually used?

ENFORCEMENT STANDARDS:
1. File headers (MUST match exactly):
   # Title         : [filename]
   # Author        : Bardia Samiee
   # Project       : Parametric Forge
   # License       : MIT
   # Path          : /[relative-path]
   # ----------------------------------------------------------------------------

2. Section dividers (consistent spacing):
   # --- Section Name --------------------------------------------------------

3. Comment discipline:
   - Remove ALL unnecessary comments
   - Keep only essential explanatory comments
   - No inline comments unless critical

4. Code organization:
   - Alphabetical ordering within sections
   - Consistent indentation (2 spaces)
   - Proper attribute set formatting
   - Platform conditionals at top of blocks

5. Import optimization:
   - Only required imports
   - Proper inherit patterns
   - No unused bindings

DELIVERABLE: Production-ready configuration files
```

**WAVE COORDINATION PROTOCOL:**

**Sequential Wave Execution:**
```
FOR each wave in [Research, Planning, Validation, Enforcement]:
    1. Prepare wave context from previous wave outputs
    2. Calculate agent count: min(tool_count, wave_size)
    3. Distribute tools evenly across agents
    4. Launch all wave agents in parallel
    5. Monitor agent completion
    6. Aggregate wave outputs
    7. Verify all tools processed
    8. Proceed to next wave with aggregated data
```

**Parallel Agent Management:**
- Each agent receives isolated tool assignments
- No cross-agent dependencies within waves
- Complete parallelism for maximum speed
- Failed agents trigger reassignment in same wave

**Context Optimization:**
- Main orchestrator maintains minimal state
- Each wave uses fresh agent instances
- Progressive summarization between waves:
  * Research → Extract only: format, XDG status, env vars, home-manager support
  * Planning → Extract only: target files, nix expressions
  * Validation → Extract only: corrections made, final paths
  * Enforcement → Extract only: files modified
- Only essential data passed forward

**EXECUTION SAFEGUARDS:**

**Duplication Prevention:**
- Phase 0 exclusion list strictly enforced
- No modifications to already-configured tools
- Skip tools with existing entries silently

**Quality Gates:**
- Research must find concrete configuration info
- Planning must follow separation of concerns
- Validation must confirm all paths/options
- Enforcement must match exact standards

**Error Handling:**
- Agent failures logged and tools reassigned
- Missing research data skips tool (with notice)
- Invalid configurations blocked from proceeding
- File write conflicts resolved by serialization

**FINAL ORCHESTRATION:**

**Summary Generation:**
After all waves complete, generate summary:
- Tools successfully configured: [list]
- Tools skipped (already configured): [list]
- Tools skipped (insufficient info): [list]
- Configuration files modified: [list]
- Next steps for manual verification

**Commit Preparation:**
Suggest git commands for review:
- git status to see all changes
- git diff for detailed review
- Commit message suggestion following standards

**ULTRA-THINKING DIRECTIVE:**
Before execution, consider:
- Tool complexity and configuration diversity
- Optimal agent distribution for tool count
- Wave sizing for context efficiency
- Potential configuration conflicts
- Platform-specific edge cases
- Integration testing requirements

Begin with Phase 0 reconnaissance to build exclusion list, then orchestrate parallel waves systematically.
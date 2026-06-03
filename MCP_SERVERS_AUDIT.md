# Claude Code MCP Server Definitions - Complete Audit

**Generated:** 2026-02-28  
**System:** /sessions/compassionate-kind-heisenberg  
**Project:** Parametric Forge

---

## Executive Summary

This document catalogs ALL Claude Code MCP (Model Context Protocol) server definitions found on the system. These define how external services and tools are integrated into Claude Code's LSP and tool ecosystem.

**Key Findings:**
- **51 unique MCP servers** across multiple service categories
- **21 .mcp.json configuration files** discovered
- **Primary configuration locations** identified and mapped
- **Service categories** include productivity, development, data, and specialized tools

---

## Configuration Locations

### Primary Configuration Files

#### 1. Main Claude Config
**Location:** `/sessions/compassionate-kind-heisenberg/mnt/.claude/.claude.json`  
**Purpose:** User account settings, feature flags, tool usage tracking  
**Contains:** User authentication info, cached feature flags, telemetry

#### 2. Parametric Forge Project Settings
**Location:** `/sessions/compassionate-kind-heisenberg/mnt/Parametric_Forge/.claude/settings.json`  
**Purpose:** Project-specific Claude configuration  
**Key Settings:**
- Model: claude-opus-4-5-20251101
- Hooks: SessionStart, PostToolUse
- Tool permissions for Bash, Git, Playwright, etc.
- Commands, agents, skills, custom output styles

#### 3. Parametric Forge Local Settings
**Location:** `/sessions/compassionate-kind-heisenberg/mnt/Parametric_Forge/.claude/settings.local.json`  
**Purpose:** Extended permissions and MCP server blacklisting  
**Contains:**
- Specific bash command permissions
- Web fetch domain allowlists
- Disabled MCP servers (e.g., playwright-test)

#### 4. MCP Authentication Cache
**Location:** `/sessions/compassionate-kind-heisenberg/mnt/.claude/mcp-needs-auth-cache.json`  
**Purpose:** Tracks which plugins require authentication  
**Cached Plugins:**
- plugin:design:linear
- plugin:engineering:gmail
- plugin:engineering:linear
- plugin:engineering:google-calendar
- plugin:design:gmail
- plugin:design:google-calendar
- plugin:design:notion
- plugin:design:atlassian
- plugin:design:intercom
- plugin:engineering:notion
- plugin:engineering:atlassian
- plugin:design:figma
- plugin:data:atlassian
- plugin:data:amplitude
- plugin:data:hex

---

## MCP Server Definitions by Source

### Cache Directory: /sessions/compassionate-kind-heisenberg/mnt/.local-plugins/cache/

#### Design Plugin (v1.1.0)
**File:** `/sessions/compassionate-kind-heisenberg/mnt/.local-plugins/cache/knowledge-work-plugins/design/1.1.0/.mcp.json`  
**Servers (9):**
- slack: https://mcp.slack.com/mcp
- figma: https://mcp.figma.com/mcp
- linear: https://mcp.linear.app/mcp
- asana: https://mcp.asana.com/v2/mcp
- atlassian: https://mcp.atlassian.com/v1/mcp
- notion: https://mcp.notion.com/mcp
- intercom: https://mcp.intercom.com/mcp
- google-calendar: https://gcal.mcp.claude.com/mcp
- gmail: https://gmail.mcp.claude.com/mcp

#### Data Plugin (v1.0.0)
**File:** `/sessions/compassionate-kind-heisenberg/mnt/.local-plugins/cache/knowledge-work-plugins/data/1.0.0/.mcp.json`  
**Servers (6):**
- snowflake: (empty URL)
- databricks: (empty URL)
- bigquery: https://bigquery.googleapis.com/mcp
- hex: https://app.hex.tech/mcp
- amplitude: https://mcp.amplitude.com/mcp
- atlassian: https://mcp.atlassian.com/v1/mcp

#### Engineering Plugin (v1.1.0)
**File:** `/sessions/compassionate-kind-heisenberg/mnt/.local-plugins/cache/knowledge-work-plugins/engineering/1.1.0/.mcp.json`  
**Servers (10):**
- slack: https://mcp.slack.com/mcp
- linear: https://mcp.linear.app/mcp
- asana: https://mcp.asana.com/v2/mcp
- atlassian: https://mcp.atlassian.com/v1/mcp
- notion: https://mcp.notion.com/mcp
- github: https://api.github.com/mcp
- pagerduty: https://mcp.pagerduty.com/mcp
- datadog: https://mcp.datadoghq.com/mcp
- google-calendar: https://gcal.mcp.claude.com/mcp
- gmail: https://gmail.mcp.claude.com/mcp

### Marketplace Directory: /sessions/compassionate-kind-heisenberg/mnt/.local-plugins/marketplaces/

#### Customer Support Plugin
**File:** `.../marketplaces/knowledge-work-plugins/customer-support/.mcp.json`  
**Servers (9):**
- slack, intercom, hubspot, guru, atlassian, notion, ms365, google-calendar, gmail

#### Sales Plugin
**File:** `.../marketplaces/knowledge-work-plugins/sales/.mcp.json`  
**Servers (14):**
- slack, hubspot, close, clay, zoominfo, notion, atlassian, fireflies, ms365, apollo, outreach, google-calendar, gmail, similarweb

#### Bio-Research Plugin
**File:** `.../marketplaces/knowledge-work-plugins/bio-research/.mcp.json`  
**Servers (8):**
- pubmed, biorender, biorxiv, c-trials, chembl, ot, owkin, synapse, wiley

#### Human Resources Plugin
**File:** `.../marketplaces/knowledge-work-plugins/human-resources/.mcp.json`  
**Servers (12):**
- slack, asana, notion, ms365, google-calendar, gmail, linkedin, servicenow, pendo, granola, clickup, outreach

#### Operations Plugin
**File:** `.../marketplaces/knowledge-work-plugins/operations/.mcp.json`  
**Servers:**
- slack, asana, notion, github, monday, ms365, servicenow, datadog, pagerduty, google-calendar, gmail

#### Product Management Plugin
**File:** `.../marketplaces/knowledge-work-plugins/product-management/.mcp.json`  
**Servers:**
- slack, linear, asana, notion, github, pagerduty, ms365, google-calendar, gmail, amplitude

#### Marketing Plugin
**File:** `.../marketplaces/knowledge-work-plugins/marketing/.mcp.json`  
**Servers:**
- slack, linear, asana, hubspot, notion, klaviyo, ahrefs, canva, ms365, google-calendar, gmail

#### Finance Plugin
**File:** `.../marketplaces/knowledge-work-plugins/finance/.mcp.json`  
**Servers:**
- slack, asana, notion, servicenow, ms365, google-calendar, gmail

#### Legal Plugin
**File:** `.../marketplaces/knowledge-work-plugins/legal/.mcp.json`  
**Servers:**
- slack, asana, notion, docusign, egnyte, box, ms365, servicenow, google-calendar, gmail

#### Productivity Plugin
**File:** `.../marketplaces/knowledge-work-plugins/productivity/.mcp.json`  
**Servers:**
- slack, asana, notion, ms365, google-calendar, gmail

#### Partner Built: Brand Voice
**File:** `.../partner-built/brand-voice/.mcp.json`

#### Partner Built: Apollo
**File:** `.../partner-built/apollo/.mcp.json`

#### Partner Built: Slack
**File:** `.../partner-built/slack/.mcp.json`

#### Partner Built: Common Room
**File:** `.../partner-built/common-room/.mcp.json`

---

## Complete MCP Server Catalog

### All 51 Unique Servers (Alphabetically)

| Server Name | URL | Type |
|---|---|---|
| ahrefs | https://api.ahrefs.com/mcp/mcp | HTTP |
| amplitude | https://mcp.amplitude.com/mcp | HTTP |
| apollo | https://api.apollo.io/mcp | HTTP |
| apollo | https://mcp.apollo.io/mcp | HTTP (alt) |
| asana | https://mcp.asana.com/v2/mcp | HTTP |
| atlassian | https://mcp.atlassian.com/v1/mcp | HTTP |
| benchling | (empty) | HTTP |
| bigquery | https://bigquery.googleapis.com/mcp | HTTP |
| biorender | https://mcp.services.biorender.com/mcp | HTTP |
| biorxiv | https://mcp.deepsense.ai/biorxiv/mcp | HTTP |
| box | https://mcp.box.com | HTTP |
| c-trials | https://mcp.deepsense.ai/clinical_trials/mcp | HTTP |
| canva | https://mcp.canva.com/mcp | HTTP |
| chembl | https://mcp.deepsense.ai/chembl/mcp | HTTP |
| clay | https://api.clay.com/v3/mcp | HTTP |
| clickup | https://mcp.clickup.com/mcp | HTTP |
| close | https://mcp.close.com/mcp | HTTP |
| common-room | https://mcp.commonroom.io/mcp | HTTP |
| databricks | (empty) | HTTP |
| datadog | https://mcp.datadoghq.com/mcp | HTTP |
| docusign | https://mcp.docusign.com/mcp | HTTP |
| egnyte | https://mcp-server.egnyte.com/mcp | HTTP |
| figma | https://mcp.figma.com/mcp | HTTP |
| fireflies | https://api.fireflies.ai/mcp | HTTP |
| github | https://api.github.com/mcp | HTTP |
| gmail | https://gmail.mcp.claude.com/mcp | HTTP |
| gong | https://mcp.gong.io/mcp | HTTP |
| google-calendar | https://gcal.mcp.claude.com/mcp | HTTP |
| granola | https://mcp.granola.ai/mcp | HTTP |
| guru | https://mcp.api.getguru.com/mcp | HTTP |
| hex | https://app.hex.tech/mcp | HTTP |
| hubspot | https://mcp.hubspot.com/anthropic | HTTP |
| intercom | https://mcp.intercom.com/mcp | HTTP |
| klaviyo | https://mcp.klaviyo.com/mcp | HTTP |
| linear | https://mcp.linear.app/mcp | HTTP |
| microsoft-365 | https://microsoft365.mcp.claude.com/mcp | HTTP |
| monday | https://mcp.monday.com/mcp | HTTP |
| ms365 | https://microsoft365.mcp.claude.com/mcp | HTTP |
| notion | https://mcp.notion.com/mcp | HTTP |
| ot | https://mcp.platform.opentargets.org/mcp | HTTP |
| outreach | https://mcp.outreach.io/mcp | HTTP |
| owkin | https://mcp.k.owkin.com/mcp | HTTP |
| pagerduty | https://mcp.pagerduty.com/mcp | HTTP |
| pendo | https://app.pendo.io/mcp/v0/shttp | HTTP |
| pubmed | https://pubmed.mcp.claude.com/mcp | HTTP |
| servicenow | https://mcp.servicenow.com/mcp | HTTP |
| similarweb | https://mcp.similarweb.com | HTTP |
| similarweb | https://mcp.similarweb.com/mcp | HTTP (alt) |
| slack | https://mcp.slack.com/mcp | HTTP |
| snowflake | (empty) | HTTP |
| synapse | https://mcp.synapse.org/mcp | HTTP |
| wiley | https://connector.scholargateway.ai/mcp | HTTP |
| zoominfo | https://mcp.zoominfo.com/mcp | HTTP |

---

## Service Categories

### Communication & Collaboration (8 servers)
- slack, intercom, common-room, gmail, google-calendar, gong, outreach, pendo

### Project & Task Management (8 servers)
- asana, linear, notion, github, jira/atlassian, clickup, monday, servicenow

### Sales & Business Intelligence (7 servers)
- hubspot, salesforce/outreach, apollo, clay, zoominfo, similarweb, ahrefs

### Development & DevOps (6 servers)
- github, datadog, pagerduty, servicenow, linear, atlassian

### Data Analytics & Visualization (6 servers)
- bigquery, hex, amplitude, databricks, snowflake, datadog

### Design & Content (4 servers)
- figma, canva, docusign, egnyte, box

### Biomedical & Research (9 servers)
- pubmed, biorender, biorxiv, c-trials, chembl, owkin, synapse, wiley, ot

### HR & People (4 servers)
- servicenow, pendo, granola, outreach

### Document & File Management (3 servers)
- box, egnyte, docusign

### Cloud Productivity (2 servers)
- ms365/microsoft-365, klaviyo

---

## System Integration Points

### 1. Nix Configuration
**File:** `/sessions/compassionate-kind-heisenberg/mnt/Parametric_Forge/modules/home/programs/languages/dev-tools.nix`

The system includes .NET SDK configuration to support OmniSharp and other LSP servers:
```nix
# DOTNET_ROOT required for omnisharp and other SDK-discovery tools.
home.sessionVariables.DOTNET_ROOT = "${dotnet-combined}";
```

**Relevant Packages:**
- dotnet-sdk_8, dotnet-sdk_9, dotnet-sdk_10
- shellcheck, shfmt, yamlfmt, yamllint, jq, yq-go, miller

### 2. Session Hooks
**Location:** `/sessions/compassionate-kind-heisenberg/mnt/Parametric_Forge/.claude/hooks/`

**setup-env.sh:**
- Persists environment variables (API keys, tokens) for sub-agents
- Sources token cache from home-manager activation
- Handles: ANTHROPIC_API_KEY, EXA_API_KEY, PERPLEXITY_API_KEY, TAVILY_API_KEY, SONAR_TOKEN, GH_TOKEN, GITHUB_TOKEN, GH_PROJECTS_TOKEN, HOSTINGER_TOKEN

**load-skill-index.py:**
- Loads Claude Code skill index on session start
- Enables custom skills and tools

**webhook-emit.py:**
- PostToolUse hook
- 5-second timeout
- Emits webhooks for tool execution tracking

### 3. Plugin System
**Location:** `/sessions/compassionate-kind-heisenberg/mnt/.local-plugins/`

**Structure:**
- `/cache/` - Cached plugin installations
- `/marketplaces/` - Available plugin marketplace
- `.claude-plugin/` - Plugin metadata
- `.mcpb-cache` - MCP bundled cache

**Auth Cache Status:**
15 plugins tracked for authentication requirements

---

## Permission Configuration

### Allowed Tools (from settings.json)
```
Read, Write, Edit, Glob, Grep, Task, TodoWrite, NotebookEdit,
WebSearch, WebFetch, Skill, SlashCommand, Bash, 
Bash(pnpm:*), Bash(nx:*), Bash(git:*), Bash(gh:*), Bash(node:*), Bash(uv:*),
mcp__playwright-test__*,
mcp__playwright__browser_*
```

### Denied/Disabled Servers
- `playwright-test` (disabled in local settings)

### Web Fetch Allowlist (Partial)
- github.com, arxiv.org, anthropic.com, platform.claude.com
- theagentarchitect.substack.com, aclanthology.org, youngleaders.tech
- vellum.ai, dev.to, leehanchung.github.io, emergentmind.com
- medium.com, skywork.ai, flowable.com, databricks.com
- microsoft.github.io, microsoft.com, raw.githubusercontent.com
- developers.google.com, api.github.com, mikhail.io, support.claude.com
- vtrivedy.com, gist.github.com, kirshatrov.com

---

## Findings Summary

### Comprehensive MCP Coverage
The system has access to 51 unique MCP servers covering:
- Every major productivity platform (Slack, Notion, Asana, GitHub, etc.)
- Specialized biomedical research tools (PubMed, BioRender, clinical trials)
- Data analytics platforms (BigQuery, Hex, Amplitude)
- Development tools (GitHub, Datadog, PagerDuty)
- Document management (Box, Egnyte, DocuSign)

### Configuration Hierarchy
1. **System-level:** Nix expressions define available packages
2. **User-level:** `/sessions/compassionate-kind-heisenberg/mnt/.claude/.claude.json`
3. **Project-level:** `/sessions/compassionate-kind-heisenberg/mnt/Parametric_Forge/.claude/settings.json`
4. **Plugin-level:** Individual plugin `.mcp.json` files
5. **Local-level:** `settings.local.json` for overrides

### Authentication Management
- 15 plugins tracked in auth cache
- API keys persisted via session hooks
- Token caching system via home-manager

### No Local LSP/MCP Bundles
- No custom `.mcpb` files found in Parametric_Forge
- All servers are HTTP-based remote connections
- OmniSharp support ready via .NET SDK configuration

---

## Recommendations

1. **Audit MCP Server Usage:** Not all 51 servers may be actively used
2. **Review Plugin Auth:** Check which of the 15 cached plugins are actively authenticated
3. **Monitor URLs:** Some servers have empty URLs (snowflake, databricks, benchling)
4. **Local LSP Servers:** Consider bundled MCP servers for offline development
5. **Security Review:** Ensure all plugin permissions align with security policies

---

## Files Referenced

### Main Configuration
- `/sessions/compassionate-kind-heisenberg/mnt/.claude/.claude.json`
- `/sessions/compassionate-kind-heisenberg/mnt/.claude/.credentials.json`
- `/sessions/compassionate-kind-heisenberg/mnt/.claude/mcp-needs-auth-cache.json`
- `/sessions/compassionate-kind-heisenberg/mnt/Parametric_Forge/.claude/settings.json`
- `/sessions/compassionate-kind-heisenberg/mnt/Parametric_Forge/.claude/settings.local.json`

### Plugin Directories
- `/sessions/compassionate-kind-heisenberg/mnt/.local-plugins/cache/`
- `/sessions/compassionate-kind-heisenberg/mnt/.local-plugins/marketplaces/`

### Nix Configuration
- `/sessions/compassionate-kind-heisenberg/mnt/Parametric_Forge/modules/home/programs/languages/dev-tools.nix`

### Hooks & Scripts
- `/sessions/compassionate-kind-heisenberg/mnt/Parametric_Forge/.claude/hooks/setup-env.sh`
- `/sessions/compassionate-kind-heisenberg/mnt/Parametric_Forge/.claude/hooks/load-skill-index.py`
- `/sessions/compassionate-kind-heisenberg/mnt/Parametric_Forge/.claude/hooks/webhook-emit.py`

---

**End of Report**

# [HISTORY]

Draw how branches diverge, commit, and merge. The template bakes in the history discipline an unassisted attempt fabricates — every commit id names real landed work, a branch exists before its checkout, merges record the true integration direction, and tags land on main at release points, so the subway map stays auditable against `git log`. Use `gitGraph LR:` with 2-4 branches ordered main-first, 6-12 commits, and at least one merge chain; `rotateCommitLabel: false` keeps ids horizontal on their recessed chips, the `.arrow` stamp pulls the engine's 8px rails to the standing 2px, the commit-dot transform holds the −25% circle law while preserving merge-ring ratios, and a canvas-valued `primaryColor` renders merges as hollow rings. The tag is the yellow-law chip, stamped through `.tag-label-bkg`/`.tag-label` CSS so the translucent gold survives hosts that strip theme-variable alpha, and the genuinely unmerged track — here the `next` branch cut after the release — carries the `6 6` planned rhythm through its `.arrowN` class (N indexes branch declaration order) while every merged track runs solid, so the dash states repository truth rather than decoration. History that matches no repository state is the defect this archetype exists to prevent.

```mermaid
---
config:
  theme: base
  look: classic
  gitGraph:
    rotateCommitLabel: false
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    mainBkg: "#282A36"
    primaryColor: "#282A36"
    git0: "#BD93F9"
    git1: "#FF79C6"
    git2: "#8BE9FD"
    git3: "#50FA7B"
    gitBranchLabel0: "#282A36"
    gitBranchLabel1: "#282A36"
    gitBranchLabel2: "#282A36"
    gitBranchLabel3: "#282A36"
    commitLabelColor: "#F8F8F2"
    commitLabelBackground: "#21222C"
    commitLabelFontSize: "11px"
    tagLabelFontSize: "11px"
  themeCSS: ".arrow{stroke-width:2px}.arrow3{stroke-dasharray:6 6}.commit-bullets circle{transform-box:fill-box;transform-origin:center;transform:scale(.75)}.tag-label-bkg{fill:#FFD86654;stroke:#FFD866}.tag-label{fill:#F8F8F2}.tag-hole{fill:#282A36}"
---
gitGraph LR:
  accTitle: Release branch history
  accDescr: A develop branch cut from main, a feature merged into develop, develop merged back for a tagged release followed by a tagged hotfix, and an in-flight next branch cut after the release.
  commit id: "boot"
  commit id: "tokens"
  branch develop
  checkout develop
  commit id: "rails"
  branch feature
  checkout feature
  commit id: "elk"
  commit id: "markers"
  checkout develop
  merge feature
  commit id: "floors"
  checkout main
  merge develop tag: "v1.0"
  commit id: "hotfix" tag: "v1.0.1"
  branch next
  checkout next
  commit id: "canon"
```

Refill by renaming branches and commit ids to repository truth — ids stay unique, a branch predates its checkout, and a cherry-picked merge names its `parent:`. The 2px rails, scaled dots, hollow merge rings, recessed commit chips, and gold tag chips are fixed law — a refill renames history, never strips the fidelity surface.

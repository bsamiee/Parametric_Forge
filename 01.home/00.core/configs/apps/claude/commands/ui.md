---
allowed-tools: ["Read"]
---

# UI Screenshot Analysis

Take a screenshot and analyze it for UI/UX improvements.

First, I'll take a screenshot, then analyze it for you.

**Step 1**: Taking screenshot...
!python3 ~/.claude/tools/screenshot.py -c ui_analysis

**Step 2**: Please run the screenshot tool above, then use the Read tool on the output path to analyze the image.

Focus areas based on arguments:
- `accessibility` - WCAG compliance, inclusive design
- `responsive` - Mobile/responsive design analysis  
- `performance` - Visual performance optimization
- No arguments - General UI/UX analysis

**Analysis Framework**:
- **Visual Design**: Layout, typography, color, spacing
- **User Experience**: Navigation, interaction patterns, usability
- **Technical Implementation**: Code improvements, framework suggestions
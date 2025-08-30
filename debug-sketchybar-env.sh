#!/bin/bash
# Test script to diagnose SketchyBar environment and PATH

echo "=== SketchyBar Environment Diagnostic ==="
echo

echo "1. Current Environment Variables:"
echo "SKETCHYBAR_STATS_BINARY: ${SKETCHYBAR_STATS_BINARY:-NOT_SET}"
echo "SKETCHYBAR_CONFIG_DIR: ${SKETCHYBAR_CONFIG_DIR:-NOT_SET}" 
echo "SKETCHYBAR_ICON_MAP: ${SKETCHYBAR_ICON_MAP:-NOT_SET}"
echo

echo "2. PATH Analysis:"
echo "Current PATH: $PATH"
echo

echo "3. Package Availability Test:"
echo "- sketchybar location: $(which sketchybar 2>/dev/null || echo 'NOT FOUND')"
echo "- sbarlua location: $(which sbarlua 2>/dev/null || echo 'NOT FOUND')"
echo "- sketchybar-system-stats location: $(which sketchybar-system-stats 2>/dev/null || echo 'NOT FOUND')"
echo

echo "4. Expected vs Actual Paths:"
if [[ -n "$SKETCHYBAR_STATS_BINARY" ]]; then
  if [[ -f "$SKETCHYBAR_STATS_BINARY" ]]; then
    echo "✅ SKETCHYBAR_STATS_BINARY exists at: $SKETCHYBAR_STATS_BINARY"
  else
    echo "❌ SKETCHYBAR_STATS_BINARY not found at: $SKETCHYBAR_STATS_BINARY"
  fi
fi

echo "5. Service vs PATH Availability:"
STATS_IN_PATH=$(which sketchybar-system-stats 2>/dev/null)
if [[ -n "$STATS_IN_PATH" ]]; then
  echo "✅ sketchybar-system-stats available in PATH: $STATS_IN_PATH"
  if [[ -n "$SKETCHYBAR_STATS_BINARY" && "$STATS_IN_PATH" == "$SKETCHYBAR_STATS_BINARY" ]]; then
    echo "ℹ️  Environment variable matches PATH location"
  else
    echo "⚠️  Environment variable differs from PATH location"
  fi
else
  echo "❌ sketchybar-system-stats NOT in PATH"
fi

echo "6. Configuration Directory Test:"
if [[ -n "$SKETCHYBAR_CONFIG_DIR" ]]; then
  if [[ -d "$SKETCHYBAR_CONFIG_DIR" ]]; then
    echo "✅ SKETCHYBAR_CONFIG_DIR exists: $SKETCHYBAR_CONFIG_DIR"
    echo "   Contents: $(ls -la "$SKETCHYBAR_CONFIG_DIR" 2>/dev/null | wc -l) files"
  else
    echo "❌ SKETCHYBAR_CONFIG_DIR not found: $SKETCHYBAR_CONFIG_DIR"
  fi
fi

echo 
echo "=== Test Results ==="
if [[ -n "$(which sketchybar)" && -n "$(which sbarlua)" ]]; then
  echo "✅ Core packages available via service"
else
  echo "❌ Core packages missing from PATH" 
fi
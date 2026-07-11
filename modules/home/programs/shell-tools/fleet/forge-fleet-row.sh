#!/usr/bin/env bash
# Per-subagent row renderer for the Claude Code subagentStatusLine: replaces the default `name · description · tokens` agent-panel row with
# `<provider-icon> <model:6> · <label:22> · M:SS · ctx%`, sourced purely from the tasks payload (per-task `model`, `startTime`, `tokenCount`,
# `contextWindowSize`). Provider resolves from the label's worker prefix first (terra:/sol:/luna:/gemini: name the real external worker behind a
# sonnet wrapper), then the model: Claude ✳, OpenAI ⬡, Gemini ✦. Fixed-width model and label columns keep every row's separators vertically
# aligned in the panel. One JSON line per task on stdout; pure and stateless — no ledger read, so it stays well under the refresh tick.
set -Eeuo pipefail
trap 'exit 0' ERR

jq -c --argjson now "$EPOCHSECONDS" '
  def short($m): if $m == null then null
    elif ($m | test("opus"; "i")) then "Opus" elif ($m | test("sonnet"; "i")) then "Sonnet"
    elif ($m | test("haiku"; "i")) then "Haiku" elif ($m | test("fable"; "i")) then "Fable"
    elif ($m | test("terra"; "i")) then "Terra" elif ($m | test("sol"; "i")) then "Sol"
    elif ($m | test("luna"; "i")) then "Luna"
    elif ($m | test("gpt"; "i")) then "GPT" elif ($m | test("gemini"; "i")) then "Gemini"
    else ($m | split("-") | .[0]) end;
  def provider($name; $lbl): ($lbl // "" | ascii_downcase) as $l
    | if ($l | test("^(terra|sol|luna|gpt)")) then "openai"
      elif ($l | test("^(gemini|agy)")) then "gemini"
      elif $name == null then "unknown"
      elif ($name | IN("Opus","Sonnet","Haiku","Fable")) then "claude"
      elif ($name | IN("Terra","Sol","Luna","GPT")) then "openai"
      elif $name == "Gemini" then "gemini"
      else "unknown" end;
  def icon($p): {claude: "✳", openai: "⬡", gemini: "✦", unknown: "⛭"}[$p];
  def pad($s; $w): (($s // "") + "                      ")[0:$w];
  def secs($st): ($st | tostring | tonumber?) as $n
    | if $n == null then null elif $n > 1000000000000 then (($now - ($n / 1000)) | floor)
      elif $n > 1000000000 then (($now - $n) | floor) else null end;
  def two($n): ("0" + ($n | tostring))[-2:];
  def elx($s): if $s == null or $s < 0 then ""
    elif $s < 3600 then "\(($s / 60) | floor):\(two($s % 60))"
    else "\(($s / 3600) | floor):\(two((($s % 3600) / 60) | floor))h" end;
  def ctx($tc; $cw): ($tc | tonumber?) as $t | ($cw | tonumber?) as $c
    | if $t == null or $c == null or $c == 0 then "" else "\((100 * $t / $c) | floor)%" end;
  .tasks[]? | (.label // .name // .description // "agent" | tostring) as $lbl | short(.model) as $m | {id: .id, content: (
    [ pad($m; 6), pad($lbl | .[0:22]; 22), elx(secs(.startTime)), ctx(.tokenCount; .contextWindowSize) ]
    | map(select(. != "" and . != null)) | icon(provider($m; $lbl)) + " " + join(" · ") )}
'

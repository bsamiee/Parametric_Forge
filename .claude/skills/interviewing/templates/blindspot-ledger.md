# [<target-token>_BLINDSPOTS]

<one-sentence-naming-the-target-and-the-pass-that-produced-the-ledger>

[AXES]: <axis-tokens-probed>; clean: <axis-tokens-that-returned-empty>
[STATUS]: `[OPEN]` `[FOLDED]` `[REFUSED]`

## [01]-[FINDINGS]

- [<id>]-[<AXIS>]-[<STATUS>]: <finding-title>
  - Anchor: <path-and-line-plus-the-observed-fact>
  - Consequence: <why-it-bites-and-how-far-the-blast-reaches>
  - Fold-back: <the-copyable-prompt-that-lands-the-fix-in-the-owning-task>
  - Route: <the-owner-that-receives-the-fold-back>

Binding: findings rank by blast radius — the entry order is the severity order. Every finding survived on-disk verification before entry; a candidate that failed verification never appears, and a clean axis is recorded in the `[AXES]` clean list rather than as an empty section. A finding spanning several owners repeats `Anchor`, one path-and-line per owner; a fix landing at both ends of a seam repeats `Route`, one owner per endpoint, so a mirrored-seam repair reads as two landings rather than one unilateral note. `[FOLDED]` marks a finding whose fold-back landed; `[REFUSED]` marks one the owner ruled against, kept with the ruling's anchor. The `[AXES]` line is mandatory and its tokens resolve in the axis catalog; zero findings is a legal ledger — the `[AXES]` line with a nonempty clean list carries the whole result.

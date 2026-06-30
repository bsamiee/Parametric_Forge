# Transcript Reading

## Common Usage Pattern

1. Find audio and video card IDs:

```bash
heptabase card list --card-types audio,video --limit 20
heptabase card list -q "<keyword>" --card-types audio,video --limit 20
```

2. Read metadata before transcript content:

```bash
heptabase audio metadata <audioCardId>
heptabase video metadata <videoCardId>
```

3. Read small time ranges:

```bash
heptabase audio read <audioCardId> --start-seconds 0 --end-seconds 300
heptabase video read <videoCardId> --start-seconds 0 --end-seconds 300
```

## Pagination Guidance

- Always call `audio metadata` or `video metadata` first.
- `audio read` and `video read` return entries that overlap the requested inclusive range, not only entries that start inside it. For example, with `--start-seconds 60 --end-seconds 120`, an entry from 55s to 65s is returned.
- Read 10-minute windows by default to avoid burning through tokens.
- Ask the user before requesting significantly more than 1 hour at once.

## When To Use Transcript Read Vs File Export

- Use `audio read` or `video read` for textual analysis. It returns Heptabase's parsed transcript entries, ready for the LLM.
- Use `file export` for raw media inspection. It returns the local audio/video file path for native tools. This is rarely needed.

## Troubleshooting

- `transcriptStatus: "processing"`: wait and retry later.
- `transcriptStatus: "failed"`: parsed transcript content is not available for this media card.
- `transcriptStatus: null`: this media card has not been transcribed yet. Ask the user to generate a transcript in Heptabase first.

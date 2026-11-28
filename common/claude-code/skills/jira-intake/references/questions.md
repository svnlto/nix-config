# PO question formats

## Jira comment (on the epic)

```markdown
Questions for refinement (<date>). Please answer by updating the story
description or acceptance criteria; replies here are not picked up.

1. <STORY-KEY>: <question>
   Unblocks: <what the answer decides>
2. <EPIC-KEY>: <question>
   Unblocks: <what the answer decides>
```

## Refinement doc (one section per epic)

```markdown
### <EPIC-KEY> <summary>

| # | Story | Question | Open since | Blocks Ready |
|---|-------|----------|------------|--------------|
| 1 | <KEY> | <question> | <date> | yes |
```

A question is resolved when its story was edited after the question date and
the next intake no longer raises it. Drop resolved rows; do not record the
answers here.

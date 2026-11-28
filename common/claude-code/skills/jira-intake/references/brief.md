# Brief format and readiness signals

## Readiness signals

Report each; they become questions or tasks, not silent assumptions:

- Empty or stub descriptions.
- Acceptance criteria that list steps instead of an outcome.
- Stories that prescribe the implementation: these are tasks, not user
  stories.
- An open question left in a title.
- A decision that exists only in a comment.
- Levels that contradict each other, e.g. a parent decision the stories
  ignore.
- A persona that names no real user.

## The brief

One block any lane skill can take as input (for `spex-feature`, the
brainstorm seed):

```markdown
## Brief: <KEY> <summary>
- Parent: <KEY> <summary> · status · planning
- Objective: <from the parent>
- Ready: yes | no — <reason>
- Suggested lane: <lane>
- Description / repro: <for a bug, the reported behaviour verbatim>
- Stories: <KEY> <summary> · status (one line each)
- Decisions from comments: <decision> (<KEY>, comment by <role>, <date>)
- Readiness signals: <list>
- Open business questions: <numbered, for the PO>
- Open technical questions: <for the tech lead>
```

Keep every Jira key: the spec carries them onto its requirements.

# Chapter 11: Projects Are Hard

## Core Idea

Your true test as a manager is how you handle bad situations, not good
ones. When deadlines loom and pressure spikes, lean on transparent
trade-offs across scope, resources, and time rather than working people
harder — and always engineer recovery time afterward.

## Frameworks Introduced

- **The Eye of Sauron**: The feeling that the entire business is staring
  at you and your team during a high-stakes or catastrophic delivery.
  - When to use: Recognize it early via warning signs so you can manage
    the pressure deliberately instead of being swept along by it.
  - How: Watch for the cues (stakeholders suddenly interested, senior
    people probing in hallways, your feature being hyped beyond its
    original scope, or everything on fire). Then apply the "Under the
    Gaze" principles daily until the gaze is averted.

- **Under the Gaze principles**: Six behaviors to apply daily while
  under intense delivery pressure.
  - When to use: Any crunch period — anticipated launch or catastrophe.
  - How: Align the team around the goal; over-communicate with weekly
    (or more frequent) written or video updates; invite responses via a
    dedicated channel; release frequently with feature toggles; be
    pragmatic about quality while noting every hack for later; lead from
    the front by putting in the work yourself.

- **The fallow period (When the Gaze Is Averted)**: Deliberate recovery
  time after a hard project, like a dairy farm letting land recover.
  - When to use: Immediately after any crunch delivery.
  - How: Celebrate and say thank you; spend a sprint tidying and clearing
    technical debt; allow self-guided project time to create mental
    space; run a project retrospective; then plan and regroup for what's
    next.

- **Brooks' Law**: "Adding manpower to a late software project makes it
  later" (from The Mythical Man Month, 1975), generalized to: adding
  people anywhere increases communication overhead and complicates
  everything.
  - When to use: Whenever someone assumes headcount scales output
    linearly, or demands to "add more people" to a slipping project.
  - How: Explain that knowledge work can't be cleanly split without
    added communication; expect sub-linear return on added headcount.

- **Scope, Resources, and Time (the three levers)**: The three
  adjustable dimensions of any project, a reframing of the Triple
  Constraint. Quality is not a lever — never compromise it.
  - When to use: Framing a new project, or when a project is in trouble.
  - How: Adjust scope (what you deliver), resources (how many engineers),
    or time (duration). You may have flexibility over all three or none.
    Make the trade-offs transparent so debate targets the right things.

- **MoSCoW method**: Categorize features into Must, Should, Could, and
  Won't to make scope negotiable.
  - When to use: Backlog prioritization, especially against a deadline.
  - How: Musts absolutely ship; Shoulds are important but deferrable;
    Coulds are desirable not necessary; Won'ts are consciously excluded
    but recorded. Under pressure, commit to only the Musts and defer the
    rest. Revisit categories as the project progresses.

## Key Concepts

- **Warning signs**: Escalating cues (hallway probing, sudden senior
  interest, external hype, growing ticket queue) that the Eye has turned
  onto your team.
- **Productivity per head**: The accurate framing of "we've slowed down"
  — a natural side effect of growth, not individuals being lazy.
- **Communication channels**: n(n-1)/2 potential channels in a group; a
  400-person company has 79,800 of them, which is why growth adds
  overhead.
- **Stretch goals**: Milestone planning that assigns Musts plus a handful
  of Shoulds to a first release, giving buffers to drop under delay.
- **Task parallelism**: How much scope is sequential versus concurrent —
  determines whether adding people can actually help.
- **Code vicinity**: Avoid multiple engineers editing the same code
  ("four spanners over the same nut") to prevent merge conflicts.
- **Campsite rule**: Leave each area of code you touch better than you
  found it.

## Mental Models

- Think of a crunch project as the Eye of Sauron's gaze: the whole
  business is watching, so increase vigilance and over-communicate until
  the gaze moves on.
- Think of recovery as a fallow field: a farm rests land after heavy use,
  and a team needs the same after crunch or it burns out.
- Use the three levers (scope, resources, time) as your negotiation
  vocabulary — when you can't bend one, you must bend another; quality is
  off the table.
- Time is neither created nor destroyed, merely allocated (Andy Hunt) —
  you can't make more, only spend it wisely.

## Anti-patterns

- **Working the team harder as the answer**: Effort is not the lever;
  scope, resources, and time are. "Just work harder" invites ungrounded
  criticism and burns people out.
- **Holding code back until the deadline**: The mega-merge and big-bang
  release create last-minute bugs exactly when you can least afford them.
- **Skipping the fallow period**: Stress after stress after stress causes
  burnout and attrition; not fighting for recovery time is a failure of
  management.
- **Throwing more people at a late project**: Brooks' Law — it makes it
  later unless the added work is genuinely parallelizable.
- **Treating slowdown as an ad hominem performance problem**: It's a
  structural effect of growth (productivity per head), not lazy
  individuals.

## Worked Example

A feature launches tomorrow. The team did everything right — nailed
sprints, shipped daily — yet last-minute failures appear: intermittent
service comms, spurious log errors, data corruption. Product marketing
(Alex) pushes back on delay because the press release is already out and
asks whether the team can "just work harder." The product owner (Jo)
questions how this happened on a "surely easy" feature. Both responses
trigger the manager.

The effective move is not to argue effort. It's to reach for the levers.
Investigate the deadline first: does slipping merely delay an email
campaign, or is a CEO unveiling it on stage to thousands? Even Apple
reveals things at WWDC and ships "in a few months," so most dates move
more than they appear to. If the date is truly fixed, revisit scope via
MoSCoW — commit only to the Musts, defer Shoulds and Coulds to a first
increment behind feature toggles — and check whether any parallelizable
piece could be sped up by borrowing an engineer, knowing a sequential
critical path won't speed up "by drinking ever more coffee." Ship the
pragmatic fix, note every hack, and schedule the tidy-up sprint after.

## Key Takeaways

1. Detect the Eye early through its warning signs, then over-communicate
   relentlessly and release frequently so stakeholders follow along.
2. After any crunch, fight for a fallow period — celebrate, clear debt,
   allow self-guided time, retro, and regroup — or you invite burnout.
3. Reframe "we're slow" as "productivity per head decreases with growth";
   expose hidden complexity and always show progress.
4. Treat quality as non-negotiable and adjust only scope, resources, and
   time; make every trade-off transparent.
5. Use MoSCoW to make scope a real lever: pre-decide what can be dropped
   so you have a safety net when things go wrong.
6. Adding people rarely rescues a late project (Brooks' Law) unless the
   work is genuinely parallelizable and free of code-vicinity conflicts.
7. Investigate every deadline before accepting it — most can move further
   than stakeholders first claim.

## Connects To

- **Ch 12**: Over-communicating under pressure is an application of
  gatekeeping — deciding what to share, when, and how — from The
  Information Stock Exchange.
- **Ch 4 (Join Us! / hiring)**: The Triple Constraint reappears here,
  reused from hiring to frame project trade-offs.
- **The Mythical Man Month (Brooks, 1975)**: Direct source of Brooks'
  Law and the communication-channels formula.
- **The Pragmatic Programmer (Hunt & Thomas)**: Echoed in "develop
  software pragmatically," the campsite rule, and time allocation.

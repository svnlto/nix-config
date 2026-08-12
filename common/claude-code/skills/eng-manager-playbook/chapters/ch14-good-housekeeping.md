# Chapter 14: Good Housekeeping

## Core Idea

Communication structure dictates software design (Conway's Law), so a
manager who instills lightweight, bottom-up practices for sharing
information, learning from mistakes, and clarifying ownership can tidy an
entire department without waiting for top-down permission.

## Frameworks Introduced

- **Guilds**: a group of people from different teams who share a common
  skill set or interest, formed to prevent silos.
  - When to use: when teams reinvent the wheel, tech choices diverge,
    integrations surprise everyone, or engineers feel disconnected.
  - How: announce intentions and where the guild sits on the
    sharing-to-delivery spectrum; pick a balanced small core across many
    teams; choose a leader (no formal power); set a meeting cadence (even
    monthly); create open comms channels; decide where to document. A
    multicast pattern; disband or split guilds as they outlive purpose.

- **Lightning talks and department talks**: a graduated culture of
  internal talks that builds speaking skill and cross-team visibility.
  - When to use: to spread knowledge and give people low-risk speaking
    practice, starting inside your team.
  - How: run five-minute lightning talks on a rotation (end of sprint),
    allow prep time as a ticket, keep slides minimal (Takahashi /
    PechaKucha methods), practice, and collect one praise + one
    criticism per talk. Graduate popular ones into 20-30 minute
    department talks with an owner, a booked slot, and recordings.

- **Five Whys**: repeatedly ask "Why?" (about five times) until you
  reach the root cause of an incident or a contested assumption.
  - When to use: after any production incident or downtime, and to
    stress-test status-quo decisions.
  - How: gather the team at a whiteboard right after the fix, chain
    why-questions from symptom to root cause, write up Q&A and outcome,
    create action tickets, and share the doc in a common folder.

- **Management Bugs**: a suggestion box run through your ticket-tracking
  system so process problems get raised, discussed, and resolved in the
  open.
  - When to use: when process or organizational pain is wider than one
    team and morale suffers because change feels out of reach.
  - How: assign a point of contact; anyone raises a "management bug"
    ticket; move it through a Kanban workflow; solicit comments; on
    completion write a summary, broadcast if relevant, archive it.

- **Architecture Decision Record (ADR)**: a short document capturing why
  a design decision was made.
  - When to use: at any design decision point (framework, style,
    infrastructure) so future readers know the reasoning.
  - How: record the date, status (proposed/accepted/rejected), the
    context and business priorities, the decision, and its consequences.
    Check it into a top-level folder in the codebase and raise it as a
    pull request.

- **Squad Health Checks**: periodic team self-assessment across
  perspectives, rated with a traffic-light system.
  - When to use: quarterly, to see whether the team is trending toward
    healthier, more mature, and happier over time.
  - How: run a workshop discussing ten Spotify-model perspectives (ease
    of releasing, processes, codebase health, value, speed, mission
    clarity, fun, learning, support, pawns-vs-players), vote
    crappy/neutral/awesome per perspective, color each red/yellow/green,
    graph it, and act on the reds.

- **Directly Responsible Individual (DRI)**: name one person the buck
  stops with for a given area or initiative.
  - When to use: when important things (monitoring, docs, usage
    tracking) fall through the cracks with no clear owner.
  - How: assign a named DRI per area; they champion and move it forward
    without necessarily doing all the work; a stripped-back, easily
    shared alternative to a full RACI matrix.

## Key Concepts

- **Conway's Law**: organizations are constrained to design systems that
  copy their own communication structures.
- **Communication as routing**: unicast (DM/email), broadcast
  (all-hands), multicast (a #backend channel or guild), anycast (asking
  whoever walks past).
- **Skill-set team**: concentrates one discipline's expertise but silos
  into a physical manifestation of the software stack.
- **Cross-functional team**: owns a feature's whole lifecycle but,
  without communication, becomes just another kind of silo.
- **Root-cause analysis**: uncovering the real reason for a problem so
  it does not recur, rather than patching the symptom.
- **RACI**: responsible/accountable/consulted/informed matrix — often
  overkill and forgotten, which is why DRIs exist.
- **Bottom-up improvement**: starting a practice in your team and
  letting it gain momentum across the department, no CTO mandate needed.

## Mental Models

- Think of your department as a network: match each message to the right
  delivery scheme instead of broadcasting everything or DMing everyone.
- Use Conway's Law as a diagnostic — if the software looks fragmented,
  look first at how the teams that built it talk (or don't).
- Treat a mistake as a horror story worth telling: others learn from it
  without having to make it themselves.
- Ask "Why?" not just after outages but of any comfortable assumption —
  abstractions let teams stop thinking about details that may no longer
  hold.

## Anti-patterns

- **Assuming cross-functional teams are silo-proof**: two feature teams
  building the same thing twice, or divergent variants that breed tech
  debt, is Conway's Law biting again.
- **Fixing a bug and moving on**: skipping root-cause analysis means the
  same incident returns; the missed config default cost the team days,
  three times over.
- **Slide-heavy talks**: audiences can read or listen, not both;
  overloaded slides defeat concise delivery.
- **Full RACI matrices for a small team**: confusing, heavy, and quickly
  ignored — a named DRI communicates accountability instantly.

## Worked Example

The team burns days chasing a phantom bug: a storage quorum keeps
retrying a crashed instance instead of electing a new leader. A passing
principal engineer, Emma, spots that a connection-timeout default is
missing — the team never knew a shared parent config existed, and the
same gap had silently caused a month of outages. This is Conway's Law in
miniature: the knowledge lived in another team and never routed across.
The remedy is a five-whys session run right after the fix: Why did the
app go down? The API stopped serving. Why? The deploy deadlocked on
startup. Why? Production has far more concurrent requests than test, and
a non-thread-safe structure was used. Why? Nobody considered it; tests
passed. Why? The automated tests cover no high-throughput scenarios. Root
cause reached — the action is to add load simulation to the test suite —
and the write-up is shared so the whole team, not just the debuggers,
learns.

## Key Takeaways

1. Read fragmented software as a communication symptom (Conway's Law)
   and fix the routing, not just the code.
2. Break silos with guilds — cross-team groups around a shared skill or
   interest — which you can seed bottom-up without any mandate.
3. Grow a talks culture from five-minute team lightning talks up to
   recorded department talks; it builds skill and cross-team visibility.
4. After every incident run a five-whys to reach and document the root
   cause, then create action tickets and share the write-up.
5. Turn process pain into open tickets with a management-bugs initiative
   so anyone can raise, discuss, and track organizational issues.
6. Capture design decisions in ADRs, run quarterly health checks to spot
   trends, and name a DRI for any area that keeps falling through the
   cracks.

## Connects To

- **Projects Are Hard**: extends its point that communication channels
  explode as an org grows — here you get the routing schemes to manage
  it.
- **Ch 13 (Letting Go of Control)**: guilds and DRIs are delegation at
  department scale — spreading ownership and influence beyond your team.
- **The Modern Workplace**: cultural guilds (diversity, inclusion) and
  well-being talks feed forward into that chapter's themes.
- **The Spotify model & Apple's DRI**: external sources the chapter
  adapts — squads/tribes/chapters/guilds and directly responsible
  individuals.

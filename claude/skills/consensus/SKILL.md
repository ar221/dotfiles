---
name: consensus
description: Run a design question or ambiguous decision through N sonnet subagents with role variations (conservative / contrarian / first-principles / outlier-hunter / pragmatist), then opus-synthesize the mode + outliers. For genuine design forks only — NOT routine work. Invoke with "use consensus on <question>" or "/consensus <question>".
disable-model-invocation: false
---

# Consensus — Stochastic Multi-Agent Debate

You are running a consensus pass on a **design question where the right answer is not obvious**. Your job is to surface the range of sensible answers, the mode, and the outliers Ayaz might not think to consider. Then let him decide.

## When this skill fires

- The user says "use consensus on X" or "/consensus X"
- The user presents a genuine fork in a design decision (architecture, approach, tool choice, tradeoff)

## When this skill should NOT fire

- Routine implementation work
- Questions with a clear right answer
- Requests for speed (this skill is deliberately expensive)
- Anything where Ayaz just wants *you* to commit to a call — in that case, be opinionated directly; don't hide behind a panel

If fired inappropriately, say so in one sentence and ask the user whether they want the consensus pass or a direct recommendation.

## Procedure

### 1. Sharpen the question (≤50 words)

Before spawning anything, restate the question in a form the panel can answer independently. Strip context only the user/you share in this session — the subagents start cold. Flag any constraints that MUST hold (budget, timeline, non-negotiables from CLAUDE.md).

Show Ayaz the sharpened question. If he pushes back, revise. Don't spawn until the question is tight.

### 2. Spawn 5 sonnet subagents in parallel

Use the Agent tool, `subagent_type: general-purpose`, `model: sonnet`. Fire all 5 in one message block for parallelism.

Each gets the **same sharpened question** plus a **role prefix** that biases its lens. Use these roles:

| Role | Prefix |
|------|--------|
| Pragmatist | "You are a senior engineer whose instinct is to ship the simplest thing that works. Favor existing tools, minimize new surface area, discount hypothetical future needs." |
| First-principles | "You are a systems thinker who reasons from fundamentals. Ignore convention. Ask what the problem really is and what the minimum viable solution actually requires." |
| Contrarian | "You are deliberately skeptical of the framing. Assume the premise might be wrong. Look for the answer that the user is likely to dismiss but which might be correct." |
| Conservative | "You are optimizing for maintainability, reversibility, and blast radius. Assume this decision will be lived with for years. Favor proven patterns over novel ones." |
| Outlier-hunter | "You are explicitly tasked with finding the non-obvious answer. Propose something the other panelists won't. Be specific and defensible — weird-for-weird's-sake is not useful." |

Each subagent returns (under 250 words):
- **Recommendation** (one sentence)
- **Reasoning** (≤4 bullets)
- **Top risk of this path** (one sentence)
- **Top risk of the user's default** (one sentence — even if unsure what the default is, speculate)

### 3. Synthesize (opus, you — the main/harness model)

Read all 5 responses. Produce a single markdown block:

```markdown
## Consensus: <sharpened question>

**Panel:** 5 sonnet subagents × 5 role lenses

### Mode (what ≥3 converged on)
<Single recommendation + 2-3 bullets of shared reasoning>

### Split
<If the panel split 3/2 or 2/2/1, name the camps and their core disagreement. If unanimous, say so and move on.>

### Outliers worth reading
- **<role>**: <their take in one sentence — the *specific* thing they saw that others missed>
- **<role>**: ...

### My read (opus synthesis)
<2-3 sentences. Where you land, and why. Weight the panel but don't hide behind it — commit.>

### What I'd do next
<One concrete action, stated in the form "I'll do X unless you push back" — ready for Ayaz to green-light or redirect.>
```

### 4. Do NOT auto-execute

After the synthesis, stop. Wait for Ayaz's call. Consensus is a decision aid, not a trigger to ship.

## Calibration

- **5 agents is enough.** Don't fan out to 10 — diminishing returns and expensive.
- **Use sonnet for the panel, opus for synthesis.** The variance comes from role prompts, not model capability.
- **Role prompts should bias, not brainwash.** If every panelist gives the same answer with different framing, the question wasn't hard enough — apologize and offer a direct opinion.
- **Budget:** Expect ~5–10 minutes end to end, plus tokens. Don't fire this lightly.

## What consensus is for (examples)

Good fits:
- "Should iNiR's settings daemon be a single binary or per-domain sockets?"
- "Which of three approaches to cross-domain theming should I standardize on?"
- "Is the auto-research loop better as a systemd timer or a one-shot script invoked manually?"

Bad fits:
- "Fix this typo" — just fix it
- "What color should this button be?" — matugen already decided
- "Is this bug reproducible?" — investigate, don't vote
- "Write me a script that does X" — be opinionated directly

# GAMS design: CEV.TickPath

Stochastic tick-path generator consuming the static RE strike tables from [`CEV.md`](CEV.md) / `model/CEV.TickStrikes.draft1.gms`.

## Context

`CEV.TickStrikes` emits cross-sectional tables on `TickStrikes`:

- `tickStrikeVal` — strike levels  
- `localTickVol` — \(\sigma(i)\)  
- `localTickDrift` — \(\mu(i)\)  

Path length equals `nStrikes` (same cardinality). This module adds Wiener noise and produces a new set `TickPath`.

## Inputs

| Symbol | Source |
|--------|--------|
| `nStrikes`, `TickStrikes`, `strikeIdx` | TickStrikes factory |
| `localTickVol(strikeIdx)`, `localTickDrift(strikeIdx)` | TickStrikes factory |
| `tickStrikeVal(strikeIdx)` | initial level (first active strike) |
| `Window` | \(24\times 60\times 60\) (math spec) |
| \(\bar dt\) | `Window / max(nStrikes-1, 1)` |
| \(\epsilon_j\sim\mathcal N(0,\sqrt{\Delta_i})\) | GAMS `normal(0, sqrt(TickSpacing))` — Var(ε)=TickSpacing |

## Dynamics

From TickDynamics / WeinerGenerator in [`CEV.md`](CEV.md):

\[
\Delta W_j = \sqrt{\bar dt}\,\epsilon_j
\]

\[
\Delta i_j = \texttt{toTickSpace}(\mu_j)\,\bar dt + \sigma_j\,\Delta W_j
\]

\[
i_j \leftarrow \mathrm{clip}\big(i_{j-1}+\Delta i_j\big)\in[\texttt{MIN_TICK},\texttt{MAX_TICK}]
\]

with \(\mu_j=\texttt{localTickDrift}(j)\), \(\sigma_j=\texttt{localTickVol}(j)\).  
At each active `strikeIdx` in order: record `pathTickVal`, then step.

## Outputs

| Symbol | Role |
|--------|------|
| `Set TickPath(strikeIdx)` | dynamic path support (size `nStrikes`) |
| `pathTickVal(strikeIdx)` | realized tick level along the path |

## Files

- Spec: this document  
- Model: `model/CEV.TickPath.draft1.gms` (`$include CEV.TickStrikes.draft1.gms`)  
- Math: `spec/models/sets/CEV.md` (Window, Wiener, TickDynamics)

# GAMS design: TickPath moments

Generic mean and realized volatility over a tick **path**. Not CEV-specific: any controlling set \(S\) and level parameter \(v(S)\) can feed the macros. Draft1 wires [`CEV.TickPath.md`](CEV.TickPath.md) / `model/CEV.TickPath.draft1.gms` as the path source.

## Inputs

Only a tick path — the pair \(\big(\texttt{TickPath},\; \texttt{pathTickVal}\big)\).  
Draft1 obtains it via `$include CEV.TickPath.draft1.gms`.

| Symbol | Role |
|--------|------|
| `TickPath` | dynamic path set |
| `pathTickVal` | tick level along the path |

## Macros

Algebra matches numopt `model/RealizedVolatility.draft1.gms` (`TickAverage` / `RealizedVolatility` with window \(\mathrm{card}-1\)) and the stub naming in `PricingKernelMoments.gms`.

\[
\texttt{mean\_tickPath}(S,v)=\frac{1}{\mathrm{card}(S)}\sum_{t\in S} v(t)
\]

\[
\texttt{realized\_volatility}(S,v,m)=\frac{1}{\mathrm{card}(S)-1}\sum_{t\in S}\big(v(t)-m\big)^2
\]

## Outputs

Tuple \(\big(\mu,\; \sigma_{\mathrm{RV}}\big)
\equiv \big(\texttt{meanTickPath},\; \texttt{realizedVolatility}\big)\) (Scalars):

| Symbol | Role | Assignment |
|--------|------|------------|
| `meanTickPath` | \(\mu\) | `mean_tickPath(TickPath, pathTickVal)` |
| `realizedVolatility` | \(\sigma_{\mathrm{RV}}\) | `realized_volatility(TickPath, pathTickVal, meanTickPath)` |

Require \(\mathrm{card}(\texttt{TickPath})\ge 2\).

## Files

- Spec: this document
- Model: `model/TickPathMoments.draft1.gms`
- Path source (draft1 include): `model/CEV.TickPath.draft1.gms`

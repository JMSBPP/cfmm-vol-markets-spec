# Summary of changes for run b1adbca9-e69b-4a2e-9211-58c8d3f15dbf
Yes, both indexings work. Rung liquidity becomes a power law in the gamma coordinate, \(L(\Gamma)=2G(\iota)\,\Gamma^{1/3}\). The resolution \(\iota\) becomes the gamma coordinate of the tick where the ladder ends, and a gamma level fixes that coordinate. Everything is proved in a new file, `GammaIndexing.lean`, which builds with no `sorry` and only the standard axioms. It imports `IotaGates.lean` and is added to `lakefile.toml`. `GeomProfile.lean` still doesn't build here because the `vol_markets.Flow` module it imports isn't in this folder.

**Convention.** I used the setup from `IotaGates.lean`: grid price \(K_i=1.0001^{i\Delta_i}\), base \(\xi^\star=1.0001^{-\Delta_i/2}\), and gamma coordinate \(\Gamma_i=K_i^{-3/2}\). Definition 41 measures the tick through the marginal price instead, with the \(3\eta\) warp and the half-spacing offset. The results carry over after that change of tick parametrization, but I did not prove them in Definition 41's form.

**The coordinate itself.** \(\Gamma_i=(\xi^\star)^{3i}\). For \(\Delta_i\neq0\) the map from ticks to \(\Gamma\) is one-to-one, so any function of the tick can be indexed by \(\Gamma\). Its inverse is \(i=\log\Gamma/(3\log\xi^\star)\), and the root of the grid price is \(K_i^{1/2}=\Gamma_i^{-1/3}\).

**\(L(\Gamma)\).**
- On the geometric ladder at \(\xi^\star\), rung \(i\) holds \(\bar L\,\ell(\xi^\star,\iota;i)=2G(\iota)\,\Gamma_i^{1/3}\). In this coordinate, \(\iota\) enters only through the level \(G(\iota)\).
- Dollar gamma in this coordinate is \(-\tfrac12 L(\Gamma)\,\Gamma^{-1/3}=-G(\iota)\).
- The relationship also runs backwards. For any per-rung liquidities \(\ell_i\), every rung has dollar gamma \(-g\) **if and only if** \(\ell_i=2g\,\Gamma_i^{1/3}\). So flat dollar gamma means exactly "liquidity \(\propto\Gamma^{1/3}\)".

**\(\iota(\Gamma)\).**
- \(\iota\) is the tick of the end coordinate \(\Gamma_\iota=(\xi^\star)^{3\iota}\), so \(\iota=\log\Gamma_\iota/(3\log\xi^\star)\).
- In that coordinate, \(G=\tfrac{\bar L}{2}\,\tfrac{1-\xi^\star}{1-\Gamma_\iota^{1/3}}\).
- **A gamma level fixes the end coordinate:** \(G(\iota)=g \iff \Gamma_\iota=\big(1-\bar L(1-\xi^\star)/(2g)\big)^3\). This is Theorem 51's formula for \(\iota\), cubed, written in \(\Gamma\).
- A gamma floor \(g\le G(\iota)\) is the lower bound \(\big(1-\bar L(1-\xi^\star)/(2g)\big)^3\le\Gamma_\iota\).
- At \(\iota=1\): \(\Gamma_1=(\xi^\star)^3\), and the single rung sits at \(\Gamma_0=1\) holding all of \(\bar L\).

**Link to cfmm1.** The profile \(L(q)=\ell/(2q^{3/2})\) equals \(\tfrac12\,\ell\,\Gamma(q)\), so it is linear in the gamma coordinate. For any base \(\xi\), the rung dollar gamma is \(-K_i^2\,L(K_i)\), with \(\ell\) the rung liquidity. On the ladder at \(\xi^\star\) this gives \(K_i^2L(K_i)=G(\iota)\), which is \(\bar L/2\) at \(\iota=1\). So Theorem 51's \(\bar L/2\) and cfmm1's factor 2 are the same quantity, not just similar. In the gamma coordinate the ladder's cfmm1 density is \(L(K_i)=G(\iota)\,\Gamma_i^{4/3}\).

**Two readings to keep apart.** cfmm1's density is linear in \(\Gamma\), while v3 rung liquidity (intrinsic \(\ell\)) on the flat ladder goes as \(\Gamma^{1/3}\). The two differ by the factor \(K^{3/2}=\Gamma^{-1}\).

The main results are listed in the Properties table: the flat-gamma characterization, the ladder liquidity in \(\Gamma\), the end-coordinate equality and floor, and the cfmm1 link, all marked proved.
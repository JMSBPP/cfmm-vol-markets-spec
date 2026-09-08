# Research index

| Doc | Role |
|-----|------|
| [SUMMARY.md](./SUMMARY.md) | Executive synthesis + roadmap implications |
| [STACK.md](./STACK.md) | hevm / TickMath / FullMath stack notes |
| [FEATURES.md](./FEATURES.md) | Table stakes / anti-features |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Component boundaries |
| [PITFALLS.md](./PITFALLS.md) | Critical mistakes |
| [HEVM-FORGE-TICKMATH.md](./HEVM-FORGE-TICKMATH.md) | **Session refinement:** Forge evm/, Seaport TickMath diff, hevm.call stdcheats |

## research-store key

```
ecosystem: foundry-hevm
library: evm-spec-bridge
version: feat/2-hevm-call-stdcheats
query: TickMath Seaport differential test via hevm.call for cfmm-vol-markets-spec
kind: integration
key: 94f589a201314887165e235b459eec30e5abbb06058a87bdd3f4db9670ba148b
```

Retrieve:
```bash
gsd-tools research-store get 94f589a201314887165e235b459eec30e5abbb06058a87bdd3f4db9670ba148b
```

## Submodule failure protocol

See [HEVM-FORGE-TICKMATH.md](./HEVM-FORGE-TICKMATH.md) § Bridge — issue on `evm-spec-bridge` + notify user (forward to bridge agent).

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title HevmTickMathHarness
/// @notice Phase 2 oracle seam; Phase 3 replaces only this body with live HEVM wiring.
contract HevmTickMathHarness {
    function getSqrtPriceAtTick(int24) external pure returns (uint160) {
        revert("hevm.call not wired");
    }
}

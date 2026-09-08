// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {TickMath} from "v4-core/src/libraries/TickMath.sol";

/// @notice Compile-time delegation seam to the pinned Uniswap v4 TickMath oracle.
contract TickMathHarness {
    function getSqrtPriceAtTick(int24 tick) external pure returns (uint160) {
        return TickMath.getSqrtPriceAtTick(tick);
    }

    function getTickAtSqrtPrice(uint160 sqrtPriceX96) external pure returns (int24) {
        return TickMath.getTickAtSqrtPrice(sqrtPriceX96);
    }
}

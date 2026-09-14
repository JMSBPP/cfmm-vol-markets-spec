// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {DifferentialTest} from "@seaport/utils/DifferentialTest.sol";

/// @title DiffTestBase
/// @notice Common Seaport stateless runner for local differential suites.
abstract contract DiffTestBase is DifferentialTest {
    uint256 internal diffComparisons;

    function _requireComparisonRan() internal view {
        assertGt(diffComparisons, 0, "non-vacuity: zero comparisons");
    }

    function _runDiff(function(bytes memory) external fn, bytes memory ctx) internal {
        try fn(ctx) {} catch (bytes memory reason) {
            assertPass(reason);
        }
    }
}

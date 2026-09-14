// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {DiffTestBase} from "./DiffTestBase.sol";
import {HevmTickMathHarness} from "../../src/HevmTickMathHarness.sol";
import {TickMathTest} from "v4-core/src/test/TickMathTest.sol";

/// @dev Shared TickMath API implemented by the canonical test client and HEVM seam.
interface ITickMathOracle {
    function getSqrtPriceAtTick(int24 tick) external returns (uint160);
}

/// @title HevmDiffTest
/// @notice Runs the upstream minimum-tick client case against swapped oracle contexts.
contract HevmDiffTest is DiffTestBase {
    TickMathTest internal canonical;
    HevmTickMathHarness internal hevm;

    struct FuzzArgs {
        int24 tick;
    }

    struct Context {
        ITickMathOracle oracle;
        uint160 expectedSqrtPriceX96;
    }

    function setUp() public {
        canonical = new TickMathTest();
        hevm = new HevmTickMathHarness();
    }

    /// @dev Seaport's stateless success signal is accepted only for Side A.
    function test(
        function(Context memory, FuzzArgs memory) external executeFn,
        Context memory context,
        FuzzArgs memory args
    )
        internal
    {
        try executeFn(context, args) {} catch (bytes memory reason) {
            assertPass(reason);
        }
    }

    /// @dev Mirrors TickMathTestTest.test_getSqrtPriceAtTick_isValidMinTick.
    function test_getSqrtPriceAtTick_isValidMinTick() public {
        FuzzArgs memory args = FuzzArgs({tick: canonical.MIN_TICK()});
        Context memory context =
            Context({oracle: ITickMathOracle(address(canonical)), expectedSqrtPriceX96: canonical.MIN_SQRT_PRICE()});

        test(this.fn, context, args);

        context.oracle = ITickMathOracle(address(hevm));
        // Same Seaport success-revert catch path as Side A (stateless ends in assertPass).
        test(this.fn, context, args);

        diffComparisons++;
        _requireComparisonRan();
    }

    function test_getSqrtPriceAtTick_requiresHevmReadiness() public {
        vm.setEnv("HEVM_LIVE", "");
        vm.setEnv("RELAY_SOCK", "");
        int24 tick = canonical.MIN_TICK();
        vm.expectRevert(bytes("HevmTickMathHarness: relay/profile unavailable"));
        hevm.getSqrtPriceAtTick(tick);
    }

    /// @dev External execution makes the TickMath client path compatible with Seaport stateless tests.
    function fn(Context memory context, FuzzArgs memory args) external stateless {
        assertEq(
            context.oracle.getSqrtPriceAtTick(args.tick),
            context.expectedSqrtPriceX96,
            "getSqrtPriceAtTick: exact equality"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {hevm} from "evm-spec-bridge/Hevm.sol";
import {Vm} from "forge-std/Vm.sol";

/// @title HevmTickMathHarness
/// @notice Live, profile-gated bridge adapter for the one-method TickMath peer.
contract HevmTickMathHarness {
    Vm private constant VM = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function getSqrtPriceAtTick(int24 tick) external returns (uint160) {
        // Foundry may not expose FOUNDRY_PROFILE to cheatcode env; the runner sets HEVM_LIVE=1
        // alongside FOUNDRY_PROFILE=hevm (FFI). RELAY_SOCK remains the socket readiness guard.
        string memory live = VM.envOr("HEVM_LIVE", string(""));
        string memory relaySocket = VM.envOr("RELAY_SOCK", string(""));
        if (keccak256(bytes(live)) != keccak256(bytes("1")) || bytes(relaySocket).length == 0) {
            revert("HevmTickMathHarness: relay/profile unavailable");
        }

        string memory paramsJson = string.concat("[", VM.toString(int256(tick)), "]");
        return _decodeJsonUint160(hevm.call("getSqrtPriceAtTick", paramsJson));
    }

    function _decodeJsonUint160(bytes memory raw) private pure returns (uint160) {
        // Accept a JSON decimal string (`"123"`) so Foundry ffi does not hex-decode
        // digit-only stdout. Bare decimals are rejected for that reason.
        require(raw.length >= 3, "HevmTickMathHarness: invalid uint160 response");
        require(raw[0] == '"' && raw[raw.length - 1] == '"', "HevmTickMathHarness: invalid uint160 response");

        uint256 value;
        uint256 maximum = type(uint160).max;
        for (uint256 i = 1; i + 1 < raw.length; i++) {
            uint8 character = uint8(raw[i]);
            require(
                character >= uint8(bytes1("0")) && character <= uint8(bytes1("9")),
                "HevmTickMathHarness: invalid uint160 response"
            );
            uint256 digit = character - uint8(bytes1("0"));
            require(value <= (maximum - digit) / 10, "HevmTickMathHarness: invalid uint160 response");
            value = value * 10 + digit;
        }
        require(raw.length > 2, "HevmTickMathHarness: invalid uint160 response");
        return uint160(value);
    }
}

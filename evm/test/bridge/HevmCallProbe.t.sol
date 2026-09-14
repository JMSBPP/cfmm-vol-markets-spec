// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {hevm} from "evm-spec-bridge/Hevm.sol";

/// @notice Consumer-owned transport probe for the bridge's raw JSON result contract.
contract HevmCallProbe {
    function test_hevmCall_returnsRawJsonResultBytes() public {
        bytes memory result = hevm.call("echo", "[1]");

        require(keccak256(result) == keccak256(bytes("[1]")), "expected raw JSON bytes [1]");
    }
}

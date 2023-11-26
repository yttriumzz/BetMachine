// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {TossCoin} from "../src/TossCoin.sol";

contract TossCoinTest is Test {
    TossCoin public tossCoin;

    function setUp() public {
        tossCoin = new TossCoin(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    function testRun() public {
    }
}

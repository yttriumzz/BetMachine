// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/TossCoin.sol";

address constant ChainlinkETHUSD_ETHSepolia = address(0x694AA1769357215DE4FAC081bf1f309aDC325306);
address constant ChainlinkETHUSD_ARB = address(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);
address constant ChainlinkETHUSD_ARBSepolia = address(0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165);
address constant ChainlinkETHUSD_POL = address(0xF9680D99D6C9589e2a93a78A04A279e509205945);

contract DeployToETHSepolia is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new TossCoin(address(ChainlinkETHUSD_ETHSepolia));
        vm.stopBroadcast();
    }
}

contract DeployToARB is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new TossCoin(address(ChainlinkETHUSD_ARB));
        vm.stopBroadcast();
    }
}

contract DeployToARBSepolia is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new TossCoin(address(ChainlinkETHUSD_ARBSepolia));
        vm.stopBroadcast();
    }
}

contract DeployToPOL is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new TossCoin(address(ChainlinkETHUSD_POL));
        vm.stopBroadcast();
    }
}
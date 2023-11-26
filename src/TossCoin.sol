// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interface/IAggregatorV3Interface.sol";

/// @title TossCoin
/// @author https://twitter.com/yttriumzz
/// @notice This is just a game that uses the price (from Chainlink) 
/// of ETH/USD 10 minutes after `run` as the randomness.
/// Each bet cannot exceed 1/10 of the balance of this address 
/// and there can only be one bet per block.
contract TossCoin {
    enum Status {
        UNKNOWN, // not drawn yet
        FRONT,   // win
        BACK     // lost
    }

    struct Coin {
        address owner;
        uint256 timestamp;
        uint256 value;
        bool redeemed;
    }

    event Donate(address from, uint256 amount);
    event Run(address owner, uint256 timestamp, uint256 value, uint256 nonce);
    event Redeem(address owner, uint256 prize);
    event WithdrawFee(address protocol, uint256 fee);
    event SetDelay(uint256 delay);
    event Pause(bool paused);
    event InitShutdown(uint256 timestamp);
    event FinishShutdown(address protocol, uint256 amount);

    IAggregatorV3Interface public aggregator;
    address public protocol;
    uint256 public protocolFee;
    uint256 public shutdown;
    uint256 public delay;
    bool public paused;

    uint256 public nonce;
    mapping (uint256 => Coin) public coins;
    mapping (uint256 => bool) public already;

    modifier onlyProtocol {
        require(msg.sender == protocol, "op");
        _;
    }

    modifier onlyNotPaused {
        require(!paused, "rp");
        _;
    }

    constructor(address _aggregator) {
        protocol = msg.sender;   
        aggregator = IAggregatorV3Interface(_aggregator);

        delay = 10 minutes;
    }

    /* ----- user ----- */

    function run() external payable onlyNotPaused returns (uint256) {
        require(!already[block.number], "ra");
        require((msg.value > 0) && (msg.value <= address(this).balance / 10), "rz");

        already[block.number] = true;

        // fee maybe 0
        uint256 fee = msg.value / 100;
        protocolFee += fee;

        coins[++nonce] = Coin(
            msg.sender,
            block.timestamp,
            msg.value - fee,
            false
        );

        emit Run(coins[nonce].owner, coins[nonce].timestamp, coins[nonce].value, nonce);
        return nonce;
    }

    function redeem(uint256 _nonce, uint256 roundId) external {
        require(!coins[_nonce].redeemed, "ra");
        require(status(_nonce, roundId) == Status.FRONT, "rn");

        coins[_nonce].redeemed == true;
        (bool success, ) = coins[_nonce].owner.call{value: coins[_nonce].value * 2}("");
        require(success, "rc");

        emit Redeem(coins[_nonce].owner, coins[_nonce].value * 2);
    }

    /* ----- user view ----- */

    function getFeed(uint256 _nonce, uint256 timestamp, uint256 roundId) private view returns (Status) {
        // TODO: aggregator phase may update
        ( , , , uint preTimestamp, ) = aggregator.getRoundData(uint80(roundId) - 1);
        ( , int answer, , uint roundTimestamp, ) = aggregator.getRoundData(uint80(roundId));

        require(preTimestamp < timestamp, "Round ID too big");
        require(timestamp <= roundTimestamp, "Round ID too small");

        uint256 random = uint256(keccak256(abi.encode(_nonce, timestamp, roundId, answer, roundTimestamp)));

        if (random % 2 == 1) {
            return Status.FRONT;
        } else {
            return Status.BACK;
        }
    }

    function status(uint256 _nonce, uint256 roundId) public view returns (Status) {
        if (block.timestamp < coins[_nonce].timestamp + delay) {
            return Status.UNKNOWN;
        }

        return getFeed(_nonce, coins[_nonce].timestamp + delay, roundId);
    }

    /* ----- admin ----- */

    function donate() external payable {
        emit Donate(msg.sender, msg.value);
    }

    function withdrawFee() external {
        payable(protocol).transfer(protocolFee);
        emit WithdrawFee(protocol, protocolFee);

        protocolFee = 0;
    }

    function setDelay(uint256 _delay) external onlyProtocol {
        delay = _delay;

        emit SetDelay(delay);
    }

    function pause(bool _paused) external onlyProtocol {
        require(shutdown == 0, "ps");
        paused = _paused;

        emit Pause(paused);
    }

    function initShutdown() external onlyProtocol {
        paused = true;
        shutdown = block.timestamp;

        emit InitShutdown(shutdown);
    }

    function finishShutdown() external {
        // 30 days for users to redeem
        require((shutdown != 0) && (block.timestamp > shutdown + 30 days), "ft");

        emit FinishShutdown(protocol, address(this).balance);

        (bool success, ) = protocol.call{value: address(this).balance}("");
        require(success, "fc");
    }
}

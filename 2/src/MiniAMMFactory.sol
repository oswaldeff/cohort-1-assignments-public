// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {IMiniAMMFactory} from "./IMiniAMMFactory.sol";
import {MiniAMM} from "./MiniAMM.sol";

// Add as many variables or functions as you would like
// for the implementation. The goal is to pass `forge test`.
contract MiniAMMFactory is IMiniAMMFactory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 pairNumber);
    
    constructor() {}
    
    // implement
    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }
    
    // implement
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        // Check for zero addresses
        if (tokenA == address(0) || tokenB == address(0)) {
            revert("Zero address");
        }
        
        // Check for identical addresses
        if (tokenA == tokenB) {
            revert("Identical addresses");
        }
        
        // Order tokens (token0 < token1)
        address token0 = tokenA < tokenB ? tokenA : tokenB;
        address token1 = tokenA < tokenB ? tokenB : tokenA;
        
        // Check if pair already exists
        if (getPair[token0][token1] != address(0)) {
            revert("Pair exists");
        }
        
        // Deploy new MiniAMM pair
        pair = address(new MiniAMM(token0, token1));
        
        // Store pair in mapping (both directions)
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        
        // Add to allPairs array
        allPairs.push(pair);
        
        // Emit event
        emit PairCreated(token0, token1, pair, allPairs.length);
        
        return pair;
    }
}

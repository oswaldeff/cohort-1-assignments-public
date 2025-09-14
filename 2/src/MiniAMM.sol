// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {IMiniAMM, IMiniAMMEvents} from "./IMiniAMM.sol";
import {MiniAMMLP} from "./MiniAMMLP.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Add as many variables or functions as you would like
// for the implementation. The goal is to pass `forge test`.
contract MiniAMM is IMiniAMM, IMiniAMMEvents, MiniAMMLP {
    uint256 public k = 0;
    uint256 public xReserve = 0;
    uint256 public yReserve = 0;

    address public tokenX;
    address public tokenY;

    // implement constructor
    constructor(address _tokenX, address _tokenY) MiniAMMLP(_tokenX, _tokenY) {
        if (_tokenX == address(0)) {
            revert("tokenX cannot be zero address");
        }
        if (_tokenY == address(0)) {
            revert("tokenY cannot be zero address");
        }

        if (_tokenX == _tokenY) {
            revert("Tokens must be different");
        }
        
        // Ensure tokenX < tokenY for consistent ordering
        if (_tokenX < _tokenY) {
            tokenX = _tokenX;
            tokenY = _tokenY;
        } else {
            tokenX = _tokenY;
            tokenY = _tokenX;
        }
    }

    // Helper function to calculate square root
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    // add parameters and implement function.
    // this function will determine the 'k'.
    function _addLiquidityFirstTime(uint256 xAmountIn, uint256 yAmountIn) internal returns (uint256 lpMinted) {
        // Transfer tokens from user to contract
        IERC20(tokenX).transferFrom(msg.sender, address(this), xAmountIn);
        IERC20(tokenY).transferFrom(msg.sender, address(this), yAmountIn);
        
        // Update reserves
        xReserve = xAmountIn;
        yReserve = yAmountIn;
        
        // Set initial k
        k = xReserve * yReserve;
        
        // Mint LP tokens using geometric mean (sqrt(x * y))
        lpMinted = sqrt(xAmountIn * yAmountIn);
        _mintLP(msg.sender, lpMinted);
        
        emit AddLiquidity(xAmountIn, yAmountIn);
    }

    // add parameters and implement function.
    // this function will increase the 'k'
    // because it is transferring liquidity from users to this contract.
    function _addLiquidityNotFirstTime(uint256 xAmountIn) internal returns (uint256 lpMinted) {
        // Calculate required y amount to maintain ratio
        uint256 yRequired = (xAmountIn * yReserve) / xReserve;
        
        // Transfer tokens from user to contract
        IERC20(tokenX).transferFrom(msg.sender, address(this), xAmountIn);
        IERC20(tokenY).transferFrom(msg.sender, address(this), yRequired);
        
        // Update reserves
        xReserve += xAmountIn;
        yReserve += yRequired;
        
        // Update k
        k = xReserve * yReserve;
        
        // Calculate LP tokens to mint based on proportion of liquidity added
        // LP tokens = (amount added / total) * current total supply
        lpMinted = (xAmountIn * totalSupply()) / (xReserve - xAmountIn);
        _mintLP(msg.sender, lpMinted);
        
        emit AddLiquidity(xAmountIn, yRequired);
    }

    // complete the function. Should transfer LP token to the user.
    function addLiquidity(uint256 xAmountIn, uint256 yAmountIn) external returns (uint256 lpMinted) {
        if (xAmountIn == 0 || yAmountIn == 0) {
            revert("Amounts must be greater than 0");
        }

        if (k == 0) {
            // First time adding liquidity
            lpMinted = _addLiquidityFirstTime(xAmountIn, yAmountIn);
        } else {
            // Additional liquidity - must maintain ratio
            uint256 yRequired = (xAmountIn * yReserve) / xReserve;
            if (yAmountIn != yRequired) {
                revert("Must maintain token ratio");
            }
            lpMinted = _addLiquidityNotFirstTime(xAmountIn);
        }
    }

    // Remove liquidity by burning LP tokens
    function removeLiquidity(uint256 lpAmount) external returns (uint256 xAmount, uint256 yAmount) {
        if (lpAmount == 0) {
            revert("LP amount must be greater than 0");
        }
        
        if (balanceOf(msg.sender) < lpAmount) {
            revert("Insufficient LP tokens");
        }
        
        if (totalSupply() == 0) {
            revert("No liquidity to remove");
        }
        
        // Calculate proportional amounts to return
        xAmount = (lpAmount * xReserve) / totalSupply();
        yAmount = (lpAmount * yReserve) / totalSupply();
        
        // Burn LP tokens
        _burnLP(msg.sender, lpAmount);
        
        // Update reserves
        xReserve -= xAmount;
        yReserve -= yAmount;
        
        // Update k
        k = xReserve * yReserve;
        
        // Transfer tokens back to user
        IERC20(tokenX).transfer(msg.sender, xAmount);
        IERC20(tokenY).transfer(msg.sender, yAmount);
    }

    // complete the function
    function swap(uint256 xAmountIn, uint256 yAmountIn) external {
        if (k == 0) revert("No liquidity in pool");
        if (xAmountIn > 0 && yAmountIn > 0) revert("Can only swap one direction at a time");
        if (xAmountIn == 0 && yAmountIn == 0) revert("Must swap at least one token");

        if (xAmountIn > 0) {
            // Swap X for Y
            require(xAmountIn <= xReserve, "Insufficient liquidity");
            
            // Apply 0.3% fee (997/1000 of input goes to pool)
            uint256 xAmountInWithFee = (xAmountIn * 997) / 1000;
            
            IERC20(tokenX).transferFrom(msg.sender, address(this), xAmountIn);

            uint256 newXReserve = xReserve + xAmountInWithFee;
            uint256 yOut = (yReserve * xAmountInWithFee) / newXReserve;

            require(yOut < yReserve, "Insufficient liquidity");
            yReserve -= yOut;
            xReserve = newXReserve;

            IERC20(tokenY).transfer(msg.sender, yOut);

            emit Swap(xAmountIn, 0, 0, yOut);

        } else {
            // Swap Y for X
            require(yAmountIn <= yReserve, "Insufficient liquidity");
            
            // Apply 0.3% fee (997/1000 of input goes to pool)
            uint256 yAmountInWithFee = (yAmountIn * 997) / 1000;
            
            IERC20(tokenY).transferFrom(msg.sender, address(this), yAmountIn);

            uint256 newYReserve = yReserve + yAmountInWithFee;
            uint256 xOut = (xReserve * yAmountInWithFee) / newYReserve;

            require(xOut < xReserve, "Insufficient liquidity");
            xReserve -= xOut;
            yReserve = newYReserve;

            IERC20(tokenX).transfer(msg.sender, xOut);

            emit Swap(0, yAmountIn, xOut, 0);
        }
    }
}

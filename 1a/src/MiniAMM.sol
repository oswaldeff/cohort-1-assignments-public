// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {IMiniAMM, IMiniAMMEvents} from "./IMiniAMM.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Add as many variables or functions as you would like
// for the implementation. The goal is to pass `forge test`.
contract MiniAMM is IMiniAMM, IMiniAMMEvents {
    uint256 public k = 0;
    uint256 public xReserve = 0;
    uint256 public yReserve = 0;

    address public tokenX;
    address public tokenY;

    // implement constructor
    constructor(address _tokenX, address _tokenY) {
        if (_tokenX == address(0)) {
            revert("tokenX cannot be zero address");
        }
        if (_tokenY == address(0)) {
            revert("tokenY cannot be zero address");
        }

        if (_tokenX == _tokenY) {
            revert("Tokens must be different");
        }
        
        if (_tokenX < _tokenY) {
            tokenX = _tokenX;
            tokenY = _tokenY;
        } else {
            tokenX = _tokenY;
            tokenY = _tokenX;
        }
    }

    // add parameters and implement function.
    // this function will determine the initial 'k'.
    function _addLiquidityFirstTime(uint256 xAmountIn, uint256 yAmountIn) internal {
        IERC20(tokenX).transferFrom(msg.sender, address(this), xAmountIn);
        IERC20(tokenY).transferFrom(msg.sender, address(this), yAmountIn);
        
        xReserve = xAmountIn;
        yReserve = yAmountIn;
        
        k = xReserve * yReserve;

        emit AddLiquidity(xAmountIn, yAmountIn);
    }

    // add parameters and implement function.
    // this function will increase the 'k'
    // because it is transferring liquidity from users to this contract.
    function _addLiquidityNotFirstTime(uint256 xAmountIn, uint256 yAmountIn) internal {
        uint256 yRequired = (xAmountIn * yReserve) / xReserve;
        
        require(yAmountIn == yRequired);

        IERC20(tokenX).transferFrom(msg.sender, address(this), xAmountIn);
        IERC20(tokenY).transferFrom(msg.sender, address(this), yAmountIn);

        xReserve += xAmountIn;
        yReserve += yAmountIn;

        k = xReserve * yReserve;

        emit AddLiquidity(xAmountIn, yAmountIn);

    }

    // complete the function
    function addLiquidity(uint256 xAmountIn, uint256 yAmountIn) external {

        if (xAmountIn == 0 || yAmountIn == 0) {
            revert("Amounts must be greater than 0");
        }

        if (k == 0) {
            // add params
            _addLiquidityFirstTime(xAmountIn, yAmountIn);
        } else {
            // add params
            _addLiquidityNotFirstTime(xAmountIn, yAmountIn);
        }
    }

    // complete the function
    function swap(uint256 xAmountIn, uint256 yAmountIn) external {
        if (k == 0) revert("No liquidity in pool");
        if (xAmountIn > 0 && yAmountIn > 0) revert("Can only swap one direction at a time");
        if (xAmountIn == 0 && yAmountIn == 0) revert("Must swap at least one token");

        if (xAmountIn > 0) {
            require(xAmountIn <= xReserve, "Insufficient liquidity");
            
            IERC20(tokenX).transferFrom(msg.sender, address(this), xAmountIn);

            uint256 newXReserve = xReserve + xAmountIn;
            uint256 yOut = yReserve - (k / newXReserve);

            require(yOut < yReserve, "Insufficient liquidity");
            yReserve -= yOut;
            xReserve = newXReserve;

            IERC20(tokenY).transfer(msg.sender, yOut);

            emit Swap(xAmountIn, yOut);

        } else {
            require(yAmountIn <= yReserve, "Insufficient liquidity");
            
            IERC20(tokenY).transferFrom(msg.sender, address(this), yAmountIn);

            uint256 newYReserve = yReserve + yAmountIn;
            uint256 xOut = xReserve - (k / newYReserve);

            require(xOut < xReserve, "Insufficient liquidity");
            xReserve -= xOut;
            yReserve = newYReserve;

            IERC20(tokenX).transfer(msg.sender, xOut);

            emit Swap(xOut, yAmountIn);
        }
    }
}

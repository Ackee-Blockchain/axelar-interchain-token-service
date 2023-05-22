// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { TokenManager } from '../TokenManager.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

contract TokenLinkerMintBurn is TokenManager {
    address public tokenAddress;

    constructor(
        address interchainTokenService_
    )
        // solhint-disable-next-line no-empty-blocks
        TokenManager(interchainTokenService_) // solhint-disable-next-line no-empty-blocks
    {}

    function _setup(bytes calldata params) internal override {
        //the first argument is reserved for the admin.
        (, tokenAddress) = abi.decode(params, (address, address));
    }

    function _takeToken(address from, uint256 amount) internal override returns (uint256) {
        address token = tokenAddress;
        uint256 balance = IERC20(token).balanceOf(address(this));

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, address(this), amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || token.code.length == 0) revert TakeTokenFailed();

        return balance - IERC20(token).balanceOf(address(this));
    }

    function _giveToken(address to, uint256 amount) internal override returns (uint256) {
        address token = tokenAddress;
        uint256 balance = IERC20(token).balanceOf(to);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || token.code.length == 0) revert GiveTokenFailed();
        return IERC20(token).balanceOf(to) - balance;
    }
}

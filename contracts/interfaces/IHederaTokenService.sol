// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable-next-line interface-starts-with-i
interface IHederaTokenService {
    function associateToken(
        address account,
        address token
    ) external returns (int64);
}

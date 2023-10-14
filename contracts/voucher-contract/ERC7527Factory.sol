// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721Enumerable, ERC721, IERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import {IERC7527App} from "./IERC7527App.sol";
import {IERC7527Agency, Asset} from "./IERC7527Agency.sol";
import {IERC7527Factory} from "./IERC7527Factory.sol";

contract ERC7527Factory is IERC7527Factory {
    using ClonesWithImmutableArgs for address;

    uint256 public salt;
    constructor(
    ) {
        salt = 1;
    }

    function createWrap(
        address payable agencyImplementation,
        Asset calldata asset,
        bytes calldata immutableAgencyData,
        bytes calldata agencyInitData,
        address appImplementation,
        bytes calldata immutableAppData,
        bytes calldata appInitData
    ) external override returns(address agencyInstance){
        address appInstance = appImplementation.clone(immutableAppData);
        {
            bytes memory assetPacked = abi.encodePacked(abi.encodePacked(asset.currency, asset.amount, asset.feeRecipient), asset.mintFeePercent, asset.burnFeePercent);
            agencyInstance = address(agencyImplementation).clone(
                abi.encodePacked(
                    appInstance,
                    assetPacked,
                    immutableAgencyData
                )
            );
        }

        IERC7527App(appInstance).setAgency(payable(agencyInstance));
        if (agencyInitData.length != 0) {
            (bool success, bytes memory result) = agencyInstance.call(agencyInitData);

            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }
        }

        if (appInitData.length != 0) {
            (bool success, bytes memory result) = appInstance.call(appInitData);

            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }
        }
        ++salt;
    }
}


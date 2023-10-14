// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721Enumerable, ERC721, IERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import {IERC7527App} from "./IERC7527App.sol";
import {IERC7527Agency, Asset} from "./IERC7527Agency.sol";
import {IERC7527Factory} from "./IERC7527Factory.sol";

contract ERC7527Agency is IERC7527Agency{
    using Address for address payable;

    modifier onlyApp() {
        uint256 offset = _getImmutableArgsOffset();
        address app;
        assembly {
            app := shr(0x60, calldataload(add(offset,  76)))
        }
        require(msg.sender == app, "ERC7527Agency: caller is not the app");
        _;
    }

    receive() external payable {}

    function unwrap(
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable override {
        (address _app, Asset memory _asset,) = getStrategy();
        require(_isApprovedOrOwner(_app, msg.sender, tokenId), "LnModule: not owner");
        IERC7527App(_app).burn(tokenId, data);
        uint256 _sold = IERC721Enumerable(_app).totalSupply();
        (uint256 swap, uint256 burnFee) = getUnwrapOracle(abi.encode(_sold));
        _transfer(address(0), payable(to), swap - burnFee);
        _transfer(address(0), _asset.feeRecipient, burnFee);
        emit Unwrap(to, tokenId, swap, burnFee);
    }

    function wrap(
        address to,
        bytes calldata data
    ) external payable override returns (uint256) {
        (address _app, Asset memory _asset,) = getStrategy();
        uint256 _sold = IERC721Enumerable(_app).totalSupply();
        (uint256 swap, uint256 mintFee) = getWrapOracle(abi.encode(_sold));
        require(msg.value >= swap + mintFee, "ERC7527Agency: insufficient funds");
        _transfer(address(0), _asset.feeRecipient, mintFee);
        if(msg.value > swap + mintFee){
            _transfer(address(0), payable(msg.sender), msg.value - swap - mintFee);
        }
        uint256 id_ = IERC7527App(_app).mint(to, data);
        emit Wrap(to, id_, swap, mintFee);
        return id_;
    }

    function getStrategy() public pure override returns(address app, Asset memory asset, bytes memory attributeData){
        uint256 offset = _getImmutableArgsOffset();
        address currency;
        uint256 amount;
        address payable awardFeeRecipient;
        uint16 mintFeePercent;
        uint16 burnFeePercent;
        assembly {
            app := shr(0x60, calldataload(add(offset,  0)))
            currency := shr(0x60, calldataload(add(offset, 20)))
            amount := calldataload(add(offset, 40))
            awardFeeRecipient := shr(0x60, calldataload(add(offset,  72)))
            mintFeePercent := shr(0xf0, calldataload(add(offset,  92)))
            burnFeePercent := shr(0xf0, calldataload(add(offset,  94)))
        }
        asset = Asset(currency, amount, awardFeeRecipient, mintFeePercent, burnFeePercent);
        attributeData= "";
    }

    function getUnwrapOracle(bytes memory data) public pure override returns (uint256 swap, uint256 fee) {
        uint256 input = abi.decode(data, (uint256));
        (, Asset memory _asset,) = getStrategy();
        swap = _asset.amount + input * _asset.amount / 100;
        fee = swap * _asset.burnFeePercent / 10000;
    }

    function getWrapOracle(bytes memory data) public pure override returns (uint256 swap, uint256 fee) {
        uint256 input = abi.decode(data, (uint256));
        (, Asset memory _asset,) = getStrategy();
        swap = _asset.amount + input * _asset.amount / 100;
        fee = swap * _asset.mintFeePercent / 10000;
    }

    function _transfer(address currency, address payable recipient, uint256 amount) internal {
        if(currency == address(0)){
            recipient.sendValue(amount);
        } else {
            IERC20(currency).transfer(recipient, amount);
        }
    }

    function _isApprovedOrOwner(address app, address spender, uint256 tokenId) internal view virtual returns (bool) {
        IERC721Enumerable _app = IERC721Enumerable(app);
        address _owner = _app.ownerOf(tokenId);
        return (spender == _owner || _app.isApprovedForAll(_owner, spender) || _app.getApproved(tokenId) == spender);
    }
    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(
            calldatasize(),
            add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
    }
}

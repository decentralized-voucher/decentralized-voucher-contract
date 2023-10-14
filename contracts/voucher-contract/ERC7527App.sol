// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721Enumerable, ERC721, IERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import {IERC7527App} from "./IERC7527App.sol";
import {IERC7527Agency, Asset} from "./IERC7527Agency.sol";
import {IERC7527Factory} from "./IERC7527Factory.sol";


contract ERC7527App is ERC721Enumerable, IERC7527App{
    constructor() ERC721("ERC7527App", "EA") {}

    address payable private _oracle;

    modifier onlyAgency() {
        require(msg.sender == _getAgency(), "only agency");
        _;
    }

    function getName(uint256) external pure returns (string memory) {
        return "App";
    }

    function getMaxSupply() public pure override returns (uint256) {
        return 100;
    }

    function getAgency() external view override returns (address payable) {
        return _getAgency();
    }

    function setAgency(address payable oracle) external override {
        require(_getAgency() == address(0), "already set");
        _oracle = oracle;
    }

    function mint(address to, bytes calldata data) external override onlyAgency returns (uint256 tokenId){
        require(totalSupply() < getMaxSupply(), "max supply reached");
        tokenId = abi.decode(data, (uint256));
        require(!_exists(tokenId), "ERC721: token already minted");
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId, bytes calldata) external override onlyAgency {
        _burn(tokenId);
    }

    function _getAgency() internal view returns (address payable) {
        return _oracle;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "erc721a/contracts/ERC721A.sol";

contract TheLittleSurfers is ERC721A, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    bool public preSaleActive = true;
    bool public publicSaleActive = false;

    bool public paused = true;
    bool public revealed = false;

    uint256 public maxSupply; 
    uint256 public preSalePrice; 
    uint256 public publicSalePrice; 

    uint256 public maxPreSale;
    uint256 public maxPreSaleOg;
    uint256 public maxPublicSale;

    string private _baseURIextended;
    
    string public NETWORK_PROVENANCE = "";
    string public notRevealedUri;

    mapping(address => bool) public isWhiteListed;
    mapping(address => bool) public isOgListed;

    constructor(string memory name, string memory symbol, uint256 _preSalePrice, uint256 _publicSalePrice, uint256 _maxSupply, uint256 _maxPreSale, uint256 _maxPreSaleOg, uint256 _maxPublicSale) ERC721A(name, symbol) ReentrancyGuard() {
        preSalePrice = _preSalePrice;
        publicSalePrice = _publicSalePrice;
        maxSupply = _maxSupply;
        maxPreSale = _maxPreSale;
        maxPreSaleOg = _maxPreSaleOg;
        maxPublicSale = _maxPublicSale;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function preSaleMint(uint256 _amount) external payable nonReentrant{
        require(preSaleActive, "TLS Pre Sale is not Active");
        require(isWhiteListed[msg.sender] || isOgListed[msg.sender], "TLS User is not White/OG Listed");
        if(isOgListed[msg.sender])
        {
            require(balanceOf(msg.sender).add(_amount) <= maxPreSaleOg, "TLS Maximum Pre Sale OG Minting Limit Reached");
        }
        else{
            require(balanceOf(msg.sender).add(_amount) <= maxPreSale, "TLS Maximum Pre Sale Minting Limit Reached");
        }
        mint(_amount, true);
    }

    function publicSaleMint(uint256 _amount) external payable nonReentrant {
        require(publicSaleActive, "TLS Public Sale is not Active");
        require(balanceOf(msg.sender).add(_amount) <= maxPublicSale, "TLS Maximum Minting Limit Reached");
        mint(_amount, false);
    }

    function mint(uint256 amount,bool state) internal {
        require(!paused, "TLS Minting is Paused");
        require(totalSupply().add(amount) <= maxSupply, "TLS Maximum Supply Reached");
        if(state){
            require(preSalePrice*amount <= msg.value, "TLS ETH Value Sent for Pre Sale is not enough");
        }
        else{
            require(publicSalePrice*amount <= msg.value, "TLS ETH Value Sent for Public Sale is not enough");
        }
        _safeMint(msg.sender, amount);
    }

    function _baseURI() internal view virtual override returns (string memory){
        return _baseURIextended;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function togglePauseState() external onlyOwner {
        paused = !paused;
    }

    function togglePreSale() external onlyOwner {
        preSaleActive = !preSaleActive;
        publicSaleActive = false;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
        preSaleActive = false;
    }

    function addWhiteListedAddresses(address[] memory _address) external onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            isWhiteListed[_address[i]] = true;
        }
    }

    function addOgListedAddresses(address[] memory _address) external onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            isOgListed[_address[i]] = true;
        }
    }

    function setPreSalePrice(uint256 _preSalePrice) external onlyOwner {
        preSalePrice = _preSalePrice;
    }

    function setPublicSalePrice(uint256 _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    function airDrop(address[] memory _address) external onlyOwner {
        require(totalSupply().add(_address.length) <= maxSupply, "TLS Maximum Supply Reached");
        for(uint i=0; i < _address.length; i++){
            _safeMint(_address[i], 1);
        }
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function withdrawTotal() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        NETWORK_PROVENANCE = provenanceHash;
    }

    function setNotRevealedURI(string memory _notRevealedUri) external onlyOwner {
        notRevealedUri = _notRevealedUri;
    }

    function raffleNumberGenerator(uint _limit) public view returns(uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) + block.number
        )));
        return 1 + (seed - ((seed / _limit) * _limit));
        
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "TLS URI For Token Non-existent");
        if(!revealed){
            return notRevealedUri;
        }
        string memory currentBaseURI = _baseURI(); 
        return bytes(currentBaseURI).length > 0 ? 
        string(abi.encodePacked(currentBaseURI,_tokenId.toString(),".json")) : "";
    }
}
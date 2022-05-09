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

    uint256 public maxSupply = 5555;
    uint256 public preSalePrice = 0.08 ether;
    uint256 public preSaleOgPrice = 0.05 ether;
    uint256 public publicSalePrice = 0.1 ether;

    uint256 public maxPreSale = 7;
    uint256 public maxPreSaleOg = 8;
    uint256 public maxPublicSale = 5;

    string private _baseURIextended;
    
    string public NETWORK_PROVENANCE = "4544338203310281430";
    string public notRevealedUri = "ipfs://QmdSHzmB6EEBkuBzc84Gg5QaewjwZX1KkiTykN2HJBU6ZB";

    mapping(address => bool) public isWhiteListed;
    mapping(address => bool) public isOgListed;
    mapping(address => uint256) public preSaleCounter;
    mapping(address => uint256) public publicSaleCounter;

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) ReentrancyGuard() {
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function preSaleMint(uint256 _amount) external payable nonReentrant{
        require(preSaleActive, "TLS Pre Sale is not Active");
        require(isWhiteListed[msg.sender] || isOgListed[msg.sender], "TLS User is not White/OG Listed");
        if(isOgListed[msg.sender])
        {
            require(preSaleCounter[msg.sender].add(_amount) <= maxPreSaleOg, "TLS Maximum Pre Sale OG Minting Limit Reached");
            require(preSaleOgPrice*_amount <= msg.value, "TLS ETH Value Sent for Pre Sale Og is not enough");
        }
        else{
            require(preSaleCounter[msg.sender].add(_amount) <= maxPreSale, "TLS Maximum Pre Sale Minting Limit Reached");
            require(preSalePrice*_amount <= msg.value, "TLS ETH Value Sent for Pre Sale is not enough");
        }
        mint(_amount, true);
    }

    function publicSaleMint(uint256 _amount) external payable nonReentrant {
        require(publicSaleActive, "TLS Public Sale is not Active");
        require(publicSaleCounter[msg.sender].add(_amount) <= maxPublicSale, "TLS Maximum Minting Limit Reached");
        mint(_amount, false);
    }

    function mint(uint256 amount,bool state) internal {
        require(!paused, "TLS Minting is Paused");
        require(totalSupply().add(amount) <= maxSupply, "TLS Maximum Supply Reached");
        if(state){
            preSaleCounter[msg.sender] = preSaleCounter[msg.sender].add(amount);
        }
        else{
            require(publicSalePrice*amount <= msg.value, "TLS ETH Value Sent for Public Sale is not enough");
            publicSaleCounter[msg.sender] = publicSaleCounter[msg.sender].add(amount);
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
        payable(address(0x3e89Fbf78021D067060CC91496E604EFb69cbb15)).transfer(balance.mul(125).div(10000));
        payable(address(0xebD47AaebdeEBE67DFB2092DB728e86cC62fFac6)).transfer(balance.mul(125).div(10000));
        payable(address(0x345A8760D24CAd15E00387FCA6Da6Cbb85334482)).transfer(balance.mul(30).div(100)); // Mystery pearls
        payable(address(0xB6cD3e633b4D1072557c236767c38C26e09039b7)).transfer(balance.mul(10).div(100)); // DAO
        payable(address(0x8102c63993151973c0F334CE3bFB3B48B611e1C1)).transfer(balance.mul(15).div(100));
        payable(address(0xB6cD3e633b4D1072557c236767c38C26e09039b7)).transfer(balance.mul(10).div(100));
        payable(address(0x70148a9f077D4836d9a790ce1c1b637FAB2A9d8f)).transfer(balance.mul(15).div(100));

        balance = address(this).balance;
        payable(address(0xF1e25b6935aC967dC62A39Af295c1E6d5F725940)).transfer(balance); // 27.5, rest of balance
    }

    function setNotRevealedURI(string memory _notRevealedUri) external onlyOwner {
        notRevealedUri = _notRevealedUri;
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

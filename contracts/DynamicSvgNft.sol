//DynamicSvgNft.sol
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "base64-sol/base64.sol";

contract DynamicSvgNft is ERC721 {

    // mint
    // store svg data
    // some logic to say "sow x" or "show y image"

    uint256 private s_tokenCounter;
    string private s_lowImageURI;
    string private s_highImageURI;
    AggregatorV3Interface internal immutable i_priceFeed;
    mapping(uint256 => int256) public s_tokenIdToHighValue;
    event CreatedNFT(uint256 indexed tokenId, int256 highValue);


    constructor(address priceFeedAddress, string memory lowSvg, string memory highSvg) ERC721("Dynamic SVG NFT", "DSN") {
        s_tokenCounter=0;
        // i_lowImageURI= svgToImageURI(lowSvg);
        // i_highImageURI= svgToImageURI(highSvg);
        i_priceFeed = AggregatorV3Interface(priceFeedAddress);
        s_lowImageURI = svgToImageURI(lowSvg);
        s_highImageURI = svgToImageURI(highSvg);

        
    }

    function svgToImageURI(string memory svg) public pure returns (string memory) {
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        string memory baseURL = "data:image/svg+xml;base64,";
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }
    function mintNft(int256 highValue) public {
         s_tokenIdToHighValue[s_tokenCounter] = highValue;
         emit CreatedNFT(s_tokenCounter, highValue);
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter = s_tokenCounter + 1;
    }
    function _baseURI() internal pure override returns(string memory) {
        return "data:application/json;base64,";
    }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI Query for nonexistent token");
    (, int256 price, , , ) = i_priceFeed.latestRoundData();
    string memory imageURI= s_lowImageURI;
    if(price >= s_tokenIdToHighValue[tokenId]){
        imageURI = s_highImageURI;
    }
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name(), // You can add whatever name here
                                '", "description":"An NFT that changes based on the Chainlink Feed", ',
                                '"attributes": [{"trait_type": "coolness", "value": 100}], "image":"',
                                imageURI,
                                '"}'
            )
            )
            )
            )
            );
    }

    function getLowSVG() public view returns (string memory) {
        return s_lowImageURI;
    }

    function getHighSVG() public view returns (string memory) {
        return s_highImageURI;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return i_priceFeed;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
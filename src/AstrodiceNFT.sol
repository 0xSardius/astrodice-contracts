// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

contract AstrodiceNFT is ERC721, VRFConsumerBase, Ownable {
    using Strings for uint256;

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public tokenCounter;

    struct Astrodice {
        string planet;
        string sign;
        string house;
        string planetImage;
        string signImage;
        string houseImage;
    }

    string[] public planets = ["Planet1", "Planet2", "Planet3", /*...*/ "Planet12"];
    string[] public signs = ["Sign1", "Sign2", "Sign3", /*...*/ "Sign12"];
    string[] public houses = ["House1", "House2", "House3", /*...*/ "House12"];
    string[] public planetImages = ["planetImage1.png", "planetImage2.png", /*...*/ "planetImage12.png"];
    string[] public signImages = ["signImage1.png", "signImage2.png", /*...*/ "signImage12.png"];
    string[] public houseImages = ["houseImage1.png", "houseImage2.png", /*...*/ "houseImage12.png"];

    mapping(uint256 => Astrodice) public tokenIdToAstrodice;
    mapping(bytes32 => address) public requestIdToSender;

    event RequestedAstrodice(bytes32 indexed requestId, uint256 indexed tokenId);
    event CreatedAstrodice(uint256 indexed tokenId, string planet, string sign, string house, string planetImage, string signImage, string houseImage);

    constructor(
        address _VRFCoordinator,
        address _LinkToken,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_VRFCoordinator, _LinkToken) ERC721("AstrodiceNFT", "ADICE") {
        keyHash = _keyHash;
        fee = _fee;
        tokenCounter = 0;
    }

    function createAstrodiceNFT() public returns (bytes32) {
        bytes32 requestId = requestRandomness(keyHash, fee);
        requestIdToSender[requestId] = msg.sender;
        uint256 newTokenId = tokenCounter;
        emit RequestedAstrodice(requestId, newTokenId);
        return requestId;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        address nftOwner = requestIdToSender[requestId];
        uint256 newTokenId = tokenCounter;

        uint256 planetIndex = randomNumber % planets.length;
        uint256 signIndex = (randomNumber / planets.length) % signs.length;
        uint256 houseIndex = (randomNumber / (planets.length * signs.length)) % houses.length;

        Astrodice memory newAstrodice = Astrodice(
            planets[planetIndex],
            signs[signIndex],
            houses[houseIndex],
            planetImages[planetIndex],
            signImages[signIndex],
            houseImages[houseIndex]
        );
        
        tokenIdToAstrodice[newTokenId] = newAstrodice;
        
        _safeMint(nftOwner, newTokenId);
        emit CreatedAstrodice(newTokenId, newAstrodice.planet, newAstrodice.sign, newAstrodice.house, newAstrodice.planetImage, newAstrodice.signImage, newAstrodice.houseImage);
        
        tokenCounter += 1;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        Astrodice memory astrodice = tokenIdToAstrodice[tokenId];
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Astrodice #', tokenId.toString(), '", "description": "An Astrodice NFT", "attributes": [',
            '{"trait_type": "Planet", "value": "', astrodice.planet, '"},',
            '{"trait_type": "Sign", "value": "', astrodice.sign, '"},',
            '{"trait_type": "House", "value": "', astrodice.house, '"}],',
            '"image": "', generateImageURI(astrodice), '"}'
        ))));
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function generateImageURI(Astrodice memory astrodice) internal pure returns (string memory) {
        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">',
            '<image href="', astrodice.planetImage, '" x="0" y="0" width="100" height="100"/>',
            '<image href="', astrodice.signImage, '" x="100" y="0" width="100" height="100"/>',
            '<image href="', astrodice.houseImage, '" x="50" y="100" width="100" height="100"/>',
            '</svg>'
        )))));
    }
}

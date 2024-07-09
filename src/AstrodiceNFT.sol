// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract AstrodiceNFT is ERC721 /* Ownable */ {
    using Strings for uint256;

    uint256 public tokenCounter;

    struct Astrodice {
        string planet;
        string sign;
        string house;
        string planetSymbol;
        string signSymbol;
    }

    string[] public planets = ["Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto" "North Node", "South Node"];
    string[] public signs = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"];
    string[] public houses = ["1st House", "2nd House", "3rd House", "4th House", "5th House", "6th House", "7th House", "8th House", "9th House", "10th House", "11th House", "12th House"];
    string[] public planetSymbols = ["\u2609", "\u263E", "\u263F", "\u2640", "\u2642", "\u2643", "\u2644", "\u2645", "\u2646", "\u2647", "\u260A", "\u260B"];
    string[] public signSymbols = ["\u2648", "\u2649", "\u264A", "\u264B", "\u264C", "\u264D", "\u264E", "\u264F", "\u2650", "\u2651", "\u2652", "\u2653"];

    mapping(uint256 => Astrodice) public tokenIdToAstrodice;
    mapping(address => Astrodice[]) public ownerToAstrodiceCollection;

    Astrodice[] public listOfAstrodiceReadings;

    event CreatedAstrodice(uint256 tokenId, string planet, string sign, string house, string planetSymbol, string signSymbol);

    constructor() ERC721("AstrodiceNFT", "ASTRODICE") {
        tokenCounter = 0;
    }

    function createAstrodiceNFT() public {
        uint256 newTokenId = tokenCounter;

        // Generate a base random number using block attributes and user input
        uint256 baseRandomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, newTokenId)));

        // Derive independent random indices for each attribute
        uint256 planetIndex = uint256(keccak256(abi.encodePacked(baseRandomNumber, "planet"))) % planets.length;
        uint256 signIndex = uint256(keccak256(abi.encodePacked(baseRandomNumber, "sign"))) % signs.length;
        uint256 houseIndex = uint256(keccak256(abi.encodePacked(baseRandomNumber, "house"))) % houses.length;

        // Create a new Astrodice struct with the randomly selected attributed
        Astrodice memory newAstrodice = Astrodice(
            planets[planetIndex],
            signs[signIndex],
            houses[houseIndex],
            planetSymbols[planetIndex],
            signSymbols[signIndex]
        );
        
        // Store the Astrodice struct and mint the NFT
        tokenIdToAstrodice[newTokenId] = newAstrodice;
        ownerToAstrodiceCollection[msg.sender].push(newAstrodice);
        listOfAstrodiceReadings.push(newAstrodice);
        _safeMint(msg.sender, newTokenId);
        emit CreatedAstrodice(newTokenId, newAstrodice.planet, newAstrodice.sign, newAstrodice.house, newAstrodice.planetSymbol, newAstrodice.signSymbol);

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
            '"planet_symbol": "', astrodice.planetSymbol, '",',
            '"sign_symbol": "', astrodice.signSymbol, '"}'
        ))));
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

}
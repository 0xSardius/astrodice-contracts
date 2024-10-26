// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract AstrodiceNFT is ERC721, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;

    uint256 public tokenCounter;
    uint256 public mintPrice = 0.0017 ether; // ~$5
    
    struct Astrodice {
        string planet;
        string sign;
        string house;
        string planetSymbol;
        string signSymbol;
        string question;
        uint256 timestamp;
        address requester;
        bytes32 entropyHash;
    }

    // Core storage
    mapping(uint256 => Astrodice) public tokenIdToAstrodice;
    mapping(address => uint256[]) private userReadings;

    // Arrays for generating readings
    string[] private planets = ["Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto", "North Node", "South Node"];
    string[] private signs = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"];
    string[] private houses = ["1st House", "2nd House", "3rd House", "4th House", "5th House", "6th House", "7th House", "8th House", "9th House", "10th House", "11th House", "12th House"];
    string[] private planetSymbols = ["\u2609", "\u263E", "\u263F", "\u2640", "\u2642", "\u2643", "\u2644", "\u2645", "\u2646", "\u2647", "\u260A", "\u260B"];
    string[] private signSymbols = ["\u2648", "\u2649", "\u264A", "\u264B", "\u264C", "\u264D", "\u264E", "\u264F", "\u2650", "\u2651", "\u2652", "\u2653"];

    event ReadingCreated(
        uint256 indexed tokenId,
        address indexed requester,
        string planet,
        string sign,
        string house,
        string question,
        uint256 timestamp
    );

    event PriceUpdated(uint256 newPrice);

    constructor() ERC721("AstrodiceNFT", "ASTRODICE") Ownable(msg.sender) {}

    function generateEntropy(
        address user,
        uint256 tokenId,
        string memory question
    ) private view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                block.timestamp,
                block.prevrandao,
                user,
                tokenId,
                question
            )
        );
    }

    function createAstrodiceNFT(string memory _question) 
        public 
        payable 
        nonReentrant 
        whenNotPaused
        returns (uint256) 
    {
        require(msg.value >= mintPrice, "Insufficient payment");
        require(bytes(_question).length > 0, "Question cannot be empty");
        require(bytes(_question).length <= 500, "Question too long");

        uint256 newTokenId = tokenCounter++;
        uint256 timestamp = block.timestamp;
        
        bytes32 entropy = generateEntropy(msg.sender, newTokenId, _question);
        
        uint256 planetIndex = uint256(keccak256(abi.encodePacked(entropy, "planet"))) % planets.length;
        uint256 signIndex = uint256(keccak256(abi.encodePacked(entropy, "sign"))) % signs.length;
        uint256 houseIndex = uint256(keccak256(abi.encodePacked(entropy, "house"))) % houses.length;

        Astrodice memory newAstrodice = Astrodice({
            planet: planets[planetIndex],
            sign: signs[signIndex],
            house: houses[houseIndex],
            planetSymbol: planetSymbols[planetIndex],
            signSymbol: signSymbols[signIndex],
            question: _question,
            timestamp: timestamp,
            requester: msg.sender,
            entropyHash: entropy
        });

        tokenIdToAstrodice[newTokenId] = newAstrodice;
        userReadings[msg.sender].push(newTokenId);
        
        _safeMint(msg.sender, newTokenId);
        
        emit ReadingCreated(
            newTokenId,
            msg.sender,
            newAstrodice.planet,
            newAstrodice.sign,
            newAstrodice.house,
            _question,
            timestamp
        );

        // Refund excess payment
        uint256 excess = msg.value - mintPrice;
        if (excess > 0) {
            (bool success, ) = payable(msg.sender).call{value: excess}("");
            require(success, "Refund failed");
        }

        return newTokenId;
    }

    // View functions
    function getMyReadings() public view returns (uint256[] memory) {
        return userReadings[msg.sender];
    }

    function getReadingDetails(uint256 tokenId) 
        public 
        view 
        returns (
            string memory question,
            string memory planet,
            string memory sign,
            string memory house,
            uint256 timestamp
        ) 
    {
        require(_exists(tokenId), "Reading doesn't exist");
        Astrodice memory reading = tokenIdToAstrodice[tokenId];
        return (
            reading.question,
            reading.planet,
            reading.sign,
            reading.house,
            reading.timestamp
        );
    }

    function tokenURI(uint256 tokenId) 
        public 
        view 
        override 
        returns (string memory) 
    {
        require(_exists(tokenId), "Reading doesn't exist");
        Astrodice memory reading = tokenIdToAstrodice[tokenId];
        
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Astrodice Reading #', 
                                tokenId.toString(), 
                                '", "description": "Astrological Reading\\n\\nQuestion: ',
                                reading.question,
                                '\\n\\nReading: ', reading.planet,
                                ' in ', reading.sign,
                                ' - ', reading.house,
                                '", "attributes": [',
                                '{"trait_type": "Planet", "value": "', reading.planet, '"},',
                                '{"trait_type": "Sign", "value": "', reading.sign, '"},',
                                '{"trait_type": "House", "value": "', reading.house, '"},',
                                '{"trait_type": "Reading Date", "display_type": "date", "value": "', 
                                uint2str(reading.timestamp), '"}],',
                                '"planet_symbol": "', reading.planetSymbol, '",',
                                '"sign_symbol": "', reading.signSymbol, '"}'
                            )
                        )
                    )
                )
            )
        );
    }

    // Admin functions
    function updatePrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
        emit PriceUpdated(newPrice);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    // Helper function
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        return string(bstr);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
}

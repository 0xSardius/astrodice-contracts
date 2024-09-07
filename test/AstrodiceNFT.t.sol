// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "../src/AstrodiceNFT.sol";
// // import "solady/src/utils/LibString.sol";

// contract AstrodiceNFTTest is Test {
//     AstrodiceNFT public astrodiceNFT;
//     address public user = address(1);

//     function setUp() public {
//         astrodiceNFT = new AstrodiceNFT();
//     }

//     function testCreateAstrodiceNFT() public {
//         vm.prank(user);
//         string memory question = "What is my lucky planet?";
//         uint256 initialTokenCounter = astrodiceNFT.tokenCounter();
        
//         astrodiceNFT.createAstrodiceNFT(question);
        
//         assertEq(astrodiceNFT.tokenCounter(), initialTokenCounter + 1);
//         assertEq(astrodiceNFT.ownerOf(initialTokenCounter), user);
        
//         (string memory planet, string memory sign, string memory house, string memory planetSymbol, string memory signSymbol, string memory storedQuestion) = astrodiceNFT.tokenIdToAstrodice(initialTokenCounter);
        
//         assertTrue(bytes(planet).length > 0);
//         assertTrue(bytes(sign).length > 0);
//         assertTrue(bytes(house).length > 0);
//         assertTrue(bytes(planetSymbol).length > 0);
//         assertTrue(bytes(signSymbol).length > 0);
//         assertEq(storedQuestion, question);
//     }

//     function testTokenURI() public {
//         vm.prank(user);
//         astrodiceNFT.createAstrodiceNFT("What is my lucky planet?");
//         uint256 tokenId = astrodiceNFT.tokenCounter() - 1;
        
//         string memory tokenURI = astrodiceNFT.tokenURI(tokenId);
//         assertTrue(bytes(tokenURI).length > 0);
//         assertTrue(LibString.startsWith(tokenURI, "data:application/json;base64,"));
//     }

//     function testFailCreateAstrodiceNFTWithEmptyQuestion() public {
//         vm.prank(user);
//         astrodiceNFT.createAstrodiceNFT("");
//     }

//     function testOwnerToAstrodiceCollection() public {
//         vm.startPrank(user);
//         astrodiceNFT.createAstrodiceNFT("Question 1");
//         astrodiceNFT.createAstrodiceNFT("Question 2");
//         vm.stopPrank();

//         AstrodiceNFT.Astrodice[] memory userCollection = astrodiceNFT.ownerToAstrodiceCollection(user);
//         assertEq(userCollection.length, 2);
//         assertEq(userCollection[0].question, "Question 1");
//         assertEq(userCollection[1].question, "Question 2");
//     }
// }
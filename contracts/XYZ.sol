// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ChainlinkKeeperInterface.sol";

/*
* @author Solextin
* @title XYZ token
* @notice This contract handles token creation plus vesting. 
* It creates a contract named `XYZ token` with a symbol `XYZ`
* The token has 18 decimals and a maximum supply of 100 million.
* The contract releases a certain amount of the maximum supply to the listed addresses on a per minute basis,
* @dev The periodic minting of the XYZ tokens is done using chainlink keepers.
*/

contract XYZ is ERC20, Ownable, ChainlinkKeeperInterface{

    // The maximum supply of xyz token
    uint256 public constant MAX_SUPPLY = 100000000 * 1e18;

    // An array of addresses that the minted tokens will be sent to periodically
    address[] public receivingAddresses;

    // The time the last tokens were minted to the addresses
    uint lastReleased;

    // The number of tokens minted
    uint amountMinted;

    event Minted (
        address indexed receiver,
        uint amount,
        uint time
    );


    constructor(address[] memory _receivingAddresses) 
        ERC20("XYZ token", "XYZ") 
    {
        _populateAddress(_receivingAddresses);
        require(_receivingAddresses.length > 0, "receivingAddresses not populated");
    }

    /*
    * @dev This function is called from the constructor and takes an array of addresses where the token will be dispersed
    */
    function _populateAddress(address[] memory _receivingAddresses) private onlyOwner {
        require(_receivingAddresses.length <= 10, "Addresses can't be more than 10");
        receivingAddresses = _receivingAddresses;
    }

    /*
    * @dev This function calculates the amount of tokens to be minted per minute to the addresses in receivingAddresses array.
    * This function is called by the performUpkeep whenever the checkUpkeep function returns true.
    */
    function _disperse() internal {
        require(block.timestamp - lastReleased >= 1 minutes, "Need to wait 1 minute");
        require(amountMinted <= MAX_SUPPLY, "Maximum supply exceeded");
        uint tokenPerMinute = MAX_SUPPLY / (60*24*30*12);
        uint tokenPerAddress = tokenPerMinute/ receivingAddresses.length;

        for (uint i = 0; i < receivingAddresses.length; i++) {
            address listedAddress = receivingAddresses[i];
            _mint(listedAddress, tokenPerAddress);
            amountMinted += tokenPerAddress;
            emit Minted(
                listedAddress,
                tokenPerAddress,
                block.timestamp
            );
        }
        lastReleased = block.timestamp;
    }

    function checkUpkeep(bytes calldata /* checkData */) external  override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastReleased == 1 minutes);
    }

    /**
     * @dev Minting tokens periodically using chainlink is going to be pretty expensive in the long run
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        _disperse();
    }

    function getReceivingAddresses() public view returns (address[] memory) {
        return receivingAddresses;
    }

}
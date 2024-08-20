// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^8.0.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Presale is  Ownable, ReentrancyGuard {

    bytes32 private root;
    uint8 public currentRound;

    mapping(uint8 => Round) public rounds;
    mapping(address => mapping(uint8 => Investor)) public investors;
    mapping(address => mapping(uint8 => uint256)) public customInvestor;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) private isCustomInvestor;

     struct Round {
        bool active;
        bool isPublic;
        uint256 tokenPrice;
        uint256 targetedTokens;
        uint256 currentTokens;
        uint256 minInvest;
        uint256 maxInvest;
        uint256 totalInvestment;
    }

    struct Investor {
        uint256 totalInvestment;
        uint256 balance;
    }

    event Investment(address indexed investor, uint8 indexed round, uint256 amount);
    event Whitelisted(address indexed addr);
    event RoundStatusChanged(uint8 indexed round, bool active);

    constructor() Ownable(msg.sender)
    {}

    function investRound(uint8 _round, bytes32[] memory _proof) external payable nonReentrant{
      require(rounds[_round].active, "No active round");
      if(!isWhitelisted[msg.sender] && !rounds[_round].isPublic){
          verify(_proof, msg.sender);
      }
      uint256 amountToBuy =  (msg.value * 10**9) / (rounds[_round].tokenPrice);
      require(amountToBuy >= rounds[_round].minInvest || (investors[msg.sender][_round].balance > 0 && msg.value >= 1e9), "Insufficient funds");
      require(investors[msg.sender][_round].balance + amountToBuy <= rounds[_round].maxInvest || (isCustomInvestor[msg.sender] && investors[msg.sender][_round].balance + amountToBuy <= customInvestor[msg.sender][_round]) , "Exceeds investment limit");
      require(rounds[_round].currentTokens + amountToBuy <= rounds[_round].targetedTokens, "Exceeds funding target");

      investors[msg.sender][_round].totalInvestment += msg.value;
      investors[msg.sender][_round].balance += amountToBuy;
      rounds[_round].currentTokens += amountToBuy;
      rounds[_round].totalInvestment += msg.value;

      emit Investment(msg.sender, _round, msg.value);
    }

    function verify(
        bytes32[] memory proof,
        address addr
    ) internal {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr))));
        require(MerkleProof.verify(proof, root, leaf), "Not Whitelisted");
        isWhitelisted[addr] = true;
        emit Whitelisted(addr);
    }

    function startRound (
        uint8 _round,
        uint256 _tokenPrice,
        uint256 _minInvest,
        uint256 _maxInvestment,
        uint256 _targetedTokens,
        bool _isPublic
        ) external onlyOwner{
            require(_tokenPrice > 0, "Invalid token price");
            require(_minInvest > 0, "Invalid minimum investment");
            require(_maxInvestment > _minInvest, "Max investment must exceed min investment");
            require(_targetedTokens > 0, "Invalid targeted tokens");

            Round storage round = rounds[_round];
            round.tokenPrice = _tokenPrice;
            round.minInvest = _minInvest;
            round.maxInvest = _maxInvestment;
            round.targetedTokens = _targetedTokens;
            round.active = true;
            round.isPublic = _isPublic;
            currentRound = _round;
            emit RoundStatusChanged(_round, true);
    }

    function addToWhitelist(address[] memory  _addresses) external onlyOwner{
        require(_addresses.length > 0, "Address array must not be empty");
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(!isWhitelisted[_addresses[i]], "Address already whitelisted");
            isWhitelisted[_addresses[i]] = true;
            emit Whitelisted(_addresses[i]);
        }
    }

    function customInvestLimit(address _user, uint8 _round, uint256 _maxInvest) external onlyOwner{
        require(_maxInvest > rounds[_round].minInvest, "Max must exceed min investment");
        customInvestor[_user][_round] = _maxInvest;
        isCustomInvestor[_user] = true;
    }

    function updateRoot(bytes32 _newRoot) external onlyOwner {
        root = _newRoot;
    }

    function updateMaxInvestment(uint256 _newMaxInvestment, uint8 _round) external onlyOwner {
        require(_newMaxInvestment > rounds[_round].minInvest, "must exceed min investment");
        rounds[_round].maxInvest = _newMaxInvestment;
    }

    function updateTokenPrice(uint256 _newTokenPrice, uint8 _round) external onlyOwner {
        require(_newTokenPrice > 0, "Invalid token price");
        rounds[_round].tokenPrice = _newTokenPrice;
    }

    function roundStatus(uint8 _round) external onlyOwner {
    rounds[_round].active = !rounds[_round].active;
    emit RoundStatusChanged(_round, rounds[_round].active);
    }

    function withdraw() external onlyOwner nonReentrant{
        require(address(this).balance > 0, "zero balance");
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import '@openzeppelin/contracts/access/Ownable.sol';
interface ICrocosNFT {
  function balanceOf(address _user) external view returns(uint256);
  function transferFrom(address _user1, address _user2, uint256 tokenId) external ;
}
interface ICrocosToken {
  function balanceOf(address _user) external view returns(uint256);
  function transfer(address _user, uint256 amount) external ;  
}
contract CrocosFarm is Ownable {
  ICrocosNFT public crocosNft;
  ICrocosToken public yieldToken;
  uint256 public constant dailyReward = 400 ether * 12 / 1000; //12% of 400 ftm
  mapping(address => uint256) public harvests;
  mapping(address => uint256) public lastUpdate;
  mapping(uint => address) public ownerOfToken;  
  mapping(address => uint) public stakeBalances;
  mapping(address => mapping(uint256 => uint256)) public ownedTokens;
  mapping(uint256 => uint256) public ownedTokensIndex;
  constructor (
    address nftAddr,
    address ftAddr
  ) {
    crocosNft = ICrocosNFT(nftAddr);
    yieldToken = ICrocosToken(ftAddr);
  }

  function stake(uint tokenId) external payable {
    updateHarvest();
    ownerOfToken[tokenId] = msg.sender;
    crocosNft.transferFrom(msg.sender, address(this), tokenId);
    _addTokenToOwner(msg.sender, tokenId);    
    stakeBalances[msg.sender] ++;
  }

  function withdraw(uint tokenId) external payable {
    require(ownerOfToken[tokenId] == msg.sender, "CrocosFarm: Unable to withdraw");
    harvest();
    crocosNft.transferFrom(address(this), msg.sender, tokenId);
    _removeTokenFromOwner(msg.sender, tokenId);
    stakeBalances[msg.sender]--;
  } 

  function updateHarvest() internal {
    uint256 time = block.timestamp;
    uint256 timerFrom = lastUpdate[msg.sender];
    if (timerFrom > 0)
      // harvests[msg.sender] += stakeBalances[msg.sender] * dailyReward * (time - timerFrom) / 864000;
      harvests[msg.sender] += stakeBalances[msg.sender] * dailyReward * (time - timerFrom) / 86400;
    lastUpdate[msg.sender] = time;
  }

  function harvest() public payable {
    updateHarvest();
    uint256 reward = harvests[msg.sender];
    if (reward > 0) {
      yieldToken.transfer( msg.sender, harvests[msg.sender]);
      harvests[msg.sender] = 0;     
    }
  }  

  function stakeOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = stakeBalances[_owner];
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = ownedTokens[_owner][i];
    }
    return tokenIds;
  }

  function setNftContractAddr(address nftAddr) public onlyOwner {
    crocosNft = ICrocosNFT(nftAddr);
  }

  function setFtContractAddr(address ftAddr) public onlyOwner {
    yieldToken = ICrocosToken(ftAddr);
  }

  function getTotalClaimable(address _user) external view returns(uint256) {
    uint256 time = block.timestamp;
    uint256 pending = stakeBalances[msg.sender] * dailyReward * (time - lastUpdate[_user]) / 86400;
    return harvests[_user] + pending;
  }

  function _addTokenToOwner(address to, uint256 tokenId) private {
      uint256 length = stakeBalances[to];
      ownedTokens[to][length] = tokenId;
      ownedTokensIndex[tokenId] = length;
  }

  function _removeTokenFromOwner(address from, uint256 tokenId) private {
      // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
      // then delete the last slot (swap and pop).

      uint256 lastTokenIndex = stakeBalances[from] - 1;
      uint256 tokenIndex = ownedTokensIndex[tokenId];

      // When the token to delete is the last token, the swap operation is unnecessary
      if (tokenIndex != lastTokenIndex) {
          uint256 lastTokenId = ownedTokens[from][lastTokenIndex];

          ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
          ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
      }

      // This also deletes the contents at the last position of the array
      delete ownedTokensIndex[tokenId];
      delete ownedTokens[from][lastTokenIndex];
  }  
}


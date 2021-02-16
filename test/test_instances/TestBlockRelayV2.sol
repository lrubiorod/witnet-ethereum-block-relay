// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../../contracts/BlockRelayInterface.sol";


/**
 * @title Block relay contract for testing purposes
 * @notice Contract to store/read block headers from the Witnet network
 * @author Witnet Foundation
*/
contract TestBlockRelayV2 is BlockRelayInterface {

  struct MerkleRoots {
    // Hash of the merkle root of the DRs in Witnet
    uint256 drHashMerkleRoot;
    // Hash of the merkle root of the tallies in Witnet
    uint256 tallyHashMerkleRoot;
    // Hash of the vote that this block extends
    uint256 previousVote;
    // Address of the relayer
    address relayerAddress;
    // Flag to indicate that the relayer is paid
    bool isPaid;
  }

  struct Beacon {
    // hash of the last block
    uint256 blockHash;
    // epoch of the last block
    uint256 epoch;
  }

  // Maximum amount of gas for reporting a Block (not subject to increases)
  uint256 public constant MAX_REPORT_BLOCK_GAS = 127963;

  // Address of the block pusher
  address public witnet;
  // Last block reported
  Beacon public lastBlock;

  mapping (uint256 => MerkleRoots) public blocks;

  // Event emitted when a new block is posted to the contract
  event NewBlock(address indexed _from, uint256 _id);

  // Only the owner should be able to push blocks
  modifier isOwner() {
    require(msg.sender == witnet, "Sender not authorized"); // If it is incorrect here, it reverts.
    _; // Otherwise, it continues.
  }

  constructor() public{
    // Only the contract deployer is able to push blocks
    witnet = msg.sender;
  }

  function postNewBlock(
    uint256 _blockHash,
    uint256 _epoch,
    uint256 _drMerkleRoot,
    uint256 _tallyMerkleRoot)
    external
    isOwner
  {
    uint256 id = _blockHash;
    lastBlock.blockHash = id;
    lastBlock.epoch = _epoch;
    blocks[id].drHashMerkleRoot = _drMerkleRoot;
    blocks[id].relayerAddress = msg.sender;
    blocks[id].tallyHashMerkleRoot = _tallyMerkleRoot;
    emit NewBlock(msg.sender, id);
  }

  /// @dev Verifies the validity of a PoI against the DR merkle root
  /// @return true or false depending the validity
  function verifyDrPoi(uint256[] calldata, uint256, uint256, uint256)
  external
  view
  override
  returns(bool)
  {
    return false;
  }

  /// @dev Verifies the validity of a PoI against the tally merkle root
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..]
  /// @param _blockHash the blockHash
  /// @param _index the index in the merkle tree of the element to verify
  /// @param _element the element
  /// @return true or false depending the validity
  function verifyTallyPoi(
    uint256[] calldata _poi,
    uint256 _blockHash,
    uint256 _index,
    uint256 _element)
  external
  view
  override
  returns(bool)
  {
    uint256 tallyMerkleRoot = blocks[_blockHash].tallyHashMerkleRoot;
    if (verifyPoi(
      _poi,
      tallyMerkleRoot,
      _index,
      _element) == true) {
      return true;
      }
  }

   /// @dev Read the beacon of the last block inserted
  /// @return bytes to be signed by bridge nodes
  function getLastBeacon()
    external
    view
    override
  returns(bytes memory)
  {
    return abi.encodePacked(lastBlock.blockHash, lastBlock.epoch);
  }

  /// @notice Returns the lastest epoch reported to the block relay.
  /// @return epoch
  function getLastEpoch() external view override returns(uint256) {
    return lastBlock.epoch;
  }

  /// @notice Returns the latest hash reported to the block relay
  /// @return blockhash
  function getLastHash() external view override returns(uint256) {
    return lastBlock.blockHash;
  }

  /// @dev Verifies if the contract is upgradable
  /// @return true if the contract upgradable
  function isUpgradable(address _address) external view override returns(bool) {
    if (_address == witnet) {
      return true;
    }
    return false;
  }

  /// @dev Verifies the validity of a PoI
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..]
  /// @param _root the merkle root
  /// @param _index the index in the merkle tree of the element to verify
  /// @param _element the leaf to be verified
  /// @return true or false depending the validity
  function verifyPoi(
    uint256[] memory _poi,
    uint256 _root,
    uint256 _index,
    uint256 _element)
  private pure returns(bool)
  {
    uint256 tree = _element;
    uint256 index = _index;
    uint256 root;
    // We want to prove that the hash of the _poi and the _element is equal to _root
    // For knowing if concatenate to the left or the right we check the parity of the the index
    for (uint i = 0; i < _poi.length; i++) {
      if (index%2 == 0) {
        tree = uint256(sha256(abi.encodePacked(tree, _poi[i])));
      } else {
        tree = uint256(sha256(abi.encodePacked(_poi[i], tree)));
      }
      index = index >> 1;
    }
    root = _root + 1;
    return true;
  }

  /// @dev Retrieves address of the relayer that relayed a specific block header.
  /// @param _blockHash Hash of the block header.
  /// @return address of the relayer.
  function readRelayerAddress(uint256 _blockHash)
    external
    view
    override
    returns(address)
  {
    return blocks[_blockHash].relayerAddress;
  }

  /// @dev Pays the block reward to the relayer in case it has not been paid before
  /// @param _blockHash Hash of the block header
  function payRelayer(uint256 _blockHash) external payable override {
    // TODO Not implemented yet for this bridge implementation
  }

  /// @dev Checks if the relayer has been paid
  /// @param _blockHash Hash of the block header
  /// @return true if the relayer has been paid, false otherwise
  function isRelayerPaid(uint256 _blockHash) public view override returns(bool){
    return blocks[_blockHash].isPaid;
  }
}

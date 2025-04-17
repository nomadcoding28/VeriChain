// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Roles.sol";

contract Insure {
  using Roles for Roles.Role;

  Roles.Role private admin;
  Roles.Role private agent;
  Roles.Role private user;

  struct User {
    address pID;
    string pwd;
  }

  struct Agent {
    address aID;
    string pwd;
  }

  struct Bill {
    uint256 id;
    uint256 bID;
    uint256 cID;
    address pID;
    string amount;
    string status;
  }

  struct Claim {
    uint256 id;
    uint256 bID;
    address pID;
    address aID;
    string status;
    string amount;
  }

  struct MedicalRecords {
    uint256 bID;
    uint256 cID;
    uint256 pID;
    string[] files;
  }

  address admin_id;

  mapping(address => User) uMap;
  mapping(address => Agent) aMap;
  mapping(uint256 => Bill) bMap;
  mapping(uint256 => Claim) cMap;
  mapping(uint256 => MedicalRecords) mrMap;

  mapping(address => Bill[]) bMaps;
  mapping(address => Claim[]) uClaimMap;
  mapping(address => Claim[]) aClaimMap;

  Bill[] bills;
  Claim[] claims;
  uint256 cID;
  uint256 bID;
  uint256 mID;

  constructor() {
    admin_id = msg.sender;
    admin.add(admin_id);
    cID = 0;
    bID = 0;
  }

  function isAdmin(address id) public view returns (bool) {
    return admin.has(id);
  }

  function getAdmin() public view returns (address) {
    return admin_id;
  }

  function isUser(address id) public view returns (bool) {
    return user.has(id);
  }

  function isAgent(address id) public view returns (bool) {
    return agent.has(id);
  }

  function addUser(address _pID, string memory _pwd) public {
    require(!admin.has(_pID));
    require(!agent.has(_pID));
    require(!user.has(_pID));
    User storage u = uMap[_pID];
    u.pID = _pID;
    u.pwd = _pwd;

    user.add(_pID);
  }

  function addAgent(address _aID) public {
    require(!admin.has(_aID), "userID is Admin");
    require(!agent.has(_aID), "userId is Agent");
    require(!user.has(_aID), "UserId is Patient");
    Agent storage a = aMap[_aID];
    a.aID = _aID;
    a.pwd = "password";

    agent.add(_aID);
  }

  function addBill(
    uint256 _id,
    address _pID,
    string memory _amount,
    string memory _status
  ) public {
    bID++;
    Bill storage b = bMap[bID];
    b.id = bID;
    b.bID = _id;
    b.pID = _pID;
    b.amount = _amount;
    b.status = _status;

    Bill[] storage bs = bMaps[_pID];
    bs.push(b);

    bills.push(b);
  }

  function getBills(address _id) public view returns (Bill[] memory) {
    Bill[] memory _bills = new Bill[](bMaps[_id].length);
    uint256 j = 0;
    for (uint256 i = 0; i <= bills.length; i++) {
      if (bMap[i].pID == _id) {
        _bills[j++] = bMap[i];
      }
    }
    return _bills;
  }

  function getAllBills() public view returns (Bill[] memory) {
    Bill[] memory _bills = new Bill[](bills.length);
    uint256 j = 0;
    for (uint256 i = 0; i < bills.length; i++) {
      _bills[j++] = bMap[i + 1];
    }
    return _bills;
  }

  function updateInsurance(
    uint256 _id,
    string memory _status,
    uint256 _cID
  ) public {
    Bill storage b = bMap[_id];
    b.status = _status;
    b.cID = _cID;
  }

  function claimInsurance(
    uint256 _bID,
    address _pID,
    address _aID,
    string memory _amount,
    string memory _status
  ) public {
    cID++;
    Claim storage c = cMap[cID];

    c.id = cID;
    c.bID = _bID;
    c.pID = _pID;
    c.aID = _aID;
    c.amount = _amount;
    c.status = _status;

    updateInsurance(_bID, _status, cID);

    claims.push(c);
  }

  function getUserClaims(address _pID) public view returns (Claim[] memory) {
    Claim[] memory _claims = new Claim[](claims.length);
    uint256 j = 0;
    for (uint256 i = 0; i <= bills.length; i++) {
      if (cMap[i].pID == _pID) {
        _claims[j++] = cMap[i];
      }
    }
    return _claims;
  }

  function getAgentClaims(address _aID) public view returns (Claim[] memory) {
    Claim[] memory _claims = new Claim[](claims.length);
    uint256 j = 0;
    for (uint256 i = 0; i <= bills.length; i++) {
      if (cMap[i].aID == _aID) {
        _claims[j++] = cMap[i];
      }
    }
    return _claims;
  }

  function updateClaim(uint256 _cID, string memory _status) public {
    Claim storage c = cMap[_cID];
    c.status = _status;
  }

  function addMedicalRecords(
    uint256 _bID,
    uint256 _cID,
    uint256 _pID,
    string[] memory _files
  ) public {
    require(admin.has(msg.sender));
    MedicalRecords storage mr = mrMap[mID++];
    mr.bID = _bID;
    mr.cID = _cID;
    mr.pID = _pID;
    mr.files = _files;

    string memory _status = "Medical Records Submitted \n Awaiting Agency";

    updateInsurance(_bID, _status, _cID);
    updateClaim(_cID, _status);
  }

  function getMedicalRecords(uint256 _cID)
  public
  view
  returns (MedicalRecords memory)
  {
    require(agent.has(msg.sender));
    MedicalRecords memory mr;
    for (uint256 i = 0; i < mID; i++) {
      if (mrMap[i].cID == _cID) {
        mr = mrMap[i];
        break;
      }
    }
    return mr;
  }

  function acceptClaim(uint256 _cID, uint256 _bID) public {
    require(agent.has(msg.sender), "Only Agency Can Access this function");
    string memory _status = "Claim Accepted";
    updateClaim(_cID, _status);
    updateInsurance(_bID, _status, _cID);
  }

  function rejectClaim(uint256 _cID, uint256 _bID) public {
    require(agent.has(msg.sender), "Only Agency Can Access this function");
    string memory _status = "Claim Rejected";
    updateClaim(_cID, _status);
    updateInsurance(_bID, _status, _cID);
  }

  function sendPayment(uint256 _cID, uint256 _bID) public {
    string memory _status = "Bill Payed";
    updateClaim(_cID, _status);
    updateInsurance(_bID, _status, _cID);
  }
}

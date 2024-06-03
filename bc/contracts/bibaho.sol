// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BibahoBondhon {
    enum Status { Pending, Approved, Rejected, Divorced }
    
    struct Person {
        string name;
        string idNumber;
        address walletAddress;
    }

    struct Certificate {
        Person bride;
        Person groom;
        Person[] witnesses;
        uint256 timestamp;
        string ipfsHash;
        Status status;
        string prenupHash;
        string[] marriageRules;
        string mahr;
        bool brideConsent;
        bool groomConsent;
    }

    mapping(uint256 => Certificate) public certificates;
    mapping(address => uint256[]) public marriagesByAddress;
    uint256 public certificateCount;
    address public owner;

    event CertificateCreated(
        uint256 certificateId,
        address bride,
        address groom,
        string ipfsHash
    );
    event CertificateApproved(uint256 certificateId);
    event CertificateRejected(uint256 certificateId);
    event CertificateDivorced(uint256 certificateId);
    event IPFSHashUpdated(uint256 certificateId, string newIpfsHash);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PrenupAdded(uint256 certificateId, string prenupHash);
    event MarriageRulesUpdated(uint256 certificateId, string[] newRules);
    event MahrUpdated(uint256 certificateId, string mahr);
    event ConsentGiven(uint256 certificateId, address party);
    event CertificateRegisteredWithAuthority(uint256 certificateId);
    event NotificationSent(address recipient, string message);
    event KabinNamaGenerated(uint256 certificateId);
    event PersonalInfoUpdated(uint256 certificateId, address party, string newName, string newIdNumber, address newWalletAddress);
    event WitnessInfoUpdated(uint256 certificateId, uint256 witnessIndex, string newName, string newIdNumber, address newWalletAddress);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createCertificate(
        string memory _brideName,
        string memory _brideIdNumber,
        address _brideWalletAddress,
        string memory _groomName,
        string memory _groomIdNumber,
        address _groomWalletAddress,
        string[] memory _witnessNames,
        string[] memory _witnessIdNumbers,
        address[] memory _witnessWalletAddresses,
        string memory _ipfsHash,
        string memory _mahr
    ) public {
        require(_witnessNames.length == _witnessIdNumbers.length && _witnessIdNumbers.length == _witnessWalletAddresses.length, "Witness arrays must be of equal length");

        Person memory bride = Person(_brideName, _brideIdNumber, _brideWalletAddress);
        Person memory groom = Person(_groomName, _groomIdNumber, _groomWalletAddress);
        
        Person[] memory witnesses = new Person[](_witnessNames.length);
        for (uint i = 0; i < _witnessNames.length; i++) {
            witnesses[i] = Person(_witnessNames[i], _witnessIdNumbers[i], _witnessWalletAddresses[i]);
        }

        certificates[certificateCount].bride = bride;
        certificates[certificateCount].groom = groom;
        certificates[certificateCount].timestamp = block.timestamp;
        certificates[certificateCount].ipfsHash = _ipfsHash;
        certificates[certificateCount].status = Status.Pending;
        certificates[certificateCount].prenupHash = "";
        certificates[certificateCount].mahr = _mahr;
        certificates[certificateCount].brideConsent = false;
        certificates[certificateCount].groomConsent = false;

        // Copy each witness from memory to storage
        for (uint i = 0; i < witnesses.length; i++) {
            certificates[certificateCount].witnesses.push(witnesses[i]);
        }

        string[] memory emptyRules;
        certificates[certificateCount].marriageRules = emptyRules;

        marriagesByAddress[_brideWalletAddress].push(certificateCount);
        marriagesByAddress[_groomWalletAddress].push(certificateCount);

        emit CertificateCreated(certificateCount, _brideWalletAddress, _groomWalletAddress, _ipfsHash);
        certificateCount++;
    }

    function getCertificate(uint256 _certificateId) public view returns (Certificate memory) {
        return certificates[_certificateId];
    }

    function approveCertificate(uint256 _certificateId) public onlyOwner {
        Certificate storage cert = certificates[_certificateId];
        require(cert.brideConsent && cert.groomConsent, "Both bride and groom must give their consent");
        cert.status = Status.Approved;
        emit CertificateApproved(_certificateId);
    }

    function rejectCertificate(uint256 _certificateId) public onlyOwner {
        certificates[_certificateId].status = Status.Rejected;
        emit CertificateRejected(_certificateId);
    }

    function updateIPFSHash(uint256 _certificateId, string memory _newIpfsHash) public onlyOwner {
        certificates[_certificateId].ipfsHash = _newIpfsHash;
        emit IPFSHashUpdated(_certificateId, _newIpfsHash);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function checkPreviousMarriages(address _walletAddress) public view returns (uint256[] memory) {
        return marriagesByAddress[_walletAddress];
    }

    function registerDivorce(uint256 _certificateId) public onlyOwner {
        certificates[_certificateId].status = Status.Divorced;
        emit CertificateDivorced(_certificateId);
    }

    function addPrenup(uint256 _certificateId, string memory _prenupHash) public {
        Certificate storage cert = certificates[_certificateId];
        require(msg.sender == cert.bride.walletAddress || msg.sender == cert.groom.walletAddress, "Caller is not authorized");
        cert.prenupHash = _prenupHash;
        emit PrenupAdded(_certificateId, _prenupHash);
    }

    function updateMarriageRules(uint256 _certificateId, string[] memory _newRules) public onlyOwner {
        certificates[_certificateId].marriageRules = _newRules;
        emit MarriageRulesUpdated(_certificateId, _newRules);
    }

    function updateMahr(uint256 _certificateId, string memory _mahr) public onlyOwner {
        certificates[_certificateId].mahr = _mahr;
        emit MahrUpdated(_certificateId, _mahr);
    }

    function giveConsent(uint256 _certificateId) public {
        Certificate storage cert = certificates[_certificateId];
        require(cert.status == Status.Pending, "Certificate is not in pending status");
        
        if (msg.sender == cert.bride.walletAddress) {
            cert.brideConsent = true;
        } else if (msg.sender == cert.groom.walletAddress) {
            cert.groomConsent = true;
        } else {
            revert("Caller is not one of the married individuals");
        }
        emit ConsentGiven(_certificateId, msg.sender);
    }

    function registerWithLocalAuthorities(uint256 _certificateId) public onlyOwner {
        emit CertificateRegisteredWithAuthority(_certificateId);
    }

    function sendNotification(address _recipient, string memory _message) public onlyOwner {
        emit NotificationSent(_recipient, _message);
    }

    function generateKabinNama(uint256 _certificateId) public onlyOwner {
        // Implement logic to generate Kabin Nama
        emit KabinNamaGenerated(_certificateId);
    }

    function isBrideCurrentlyMarried(address _brideWalletAddress) public view returns (bool) {
        uint256[] memory brideMarriages = marriagesByAddress[_brideWalletAddress];
        for (uint i = 0; i < brideMarriages.length; i++) {
            if (certificates[brideMarriages[i]].status == Status.Approved) {
                return true;
            }
        }
        return false;
    }

    function isGroomMarriedToMoreThanFour(address _groomWalletAddress) public view returns (bool) {
        uint256[] memory groomMarriages = marriagesByAddress[_groomWalletAddress];
        uint count = 0;
        for (uint i = 0; i < groomMarriages.length; i++) {
            if (certificates[groomMarriages[i]].status == Status.Approved) {
                count++;
                if (count >= 4) {
                    return true;
                }
            }
        }
        return false;
    }

    function updatePersonalInfo(
        uint256 _certificateId,
        string memory _newName,
        string memory _newIdNumber,
        address _newWalletAddress
    ) public {
        Certificate storage cert = certificates[_certificateId];
        if (msg.sender == cert.bride.walletAddress) {
            cert.bride.name = _newName;
            cert.bride.idNumber = _newIdNumber;
            cert.bride.walletAddress = _newWalletAddress;
        } else if (msg.sender == cert.groom.walletAddress) {
            cert.groom.name = _newName;
            cert.groom.idNumber = _newIdNumber;
            cert.groom.walletAddress = _newWalletAddress;
        } else {
            revert("Caller is not one of the married individuals");
        }
        emit PersonalInfoUpdated(_certificateId, msg.sender, _newName, _newIdNumber, _newWalletAddress);
    }

    function updateWitnessInfo(
        uint256 _certificateId,
        uint256 _witnessIndex,
        string memory _newName,
        string memory _newIdNumber,
        address _newWalletAddress
    ) public {
        Certificate storage cert = certificates[_certificateId];
        require(_witnessIndex < cert.witnesses.length, "Invalid witness index");
        cert.witnesses[_witnessIndex] = Person(_newName, _newIdNumber, _newWalletAddress);
        emit WitnessInfoUpdated(_certificateId, _witnessIndex, _newName, _newIdNumber, _newWalletAddress);
    }
}

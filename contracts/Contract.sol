// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

contract MainCleanContract {
    // total number of contract
    uint public ccCounter;

    // define contract struct
    struct CleanContract {
        uint contractId;
        string companyName;
        string contractType;
        string contractURI;
        uint dateFrom;
        uint dateTo;
        uint agreedPrice;
        string currency;
        address creator;
        bool creatorApproval;
        uint creatorSignDate;
        address contractSigner;
        bool signerApproval;
        uint signerSignDate;
        string status;
    }

    // define notification 6
    struct Notify {
        address nSender;
        address nReceiver;
        uint ccID;
        uint notifySentTime;
        string notifyContent;
        bool status;
    }

    // map house's token id to house
    mapping(uint => CleanContract) allCleanContracts;
    // map contracts of owner
    mapping(address => uint[]) allContractsByOwner;
    // map contracts of signer
    mapping(address => uint[]) allContractsBySigner;
    // notifications
    mapping(address => Notify[]) allNotifies;

    // write Contract
    function ccCreation(
        string memory _companyName,
        string memory _contractType,
        address _contractSigner,
        string memory _contractURI,
        uint _dateFrom,
        uint _dateTo,
        uint _agreedPrice,
        string memory _currency
    ) public {
        ccCounter++;
        CleanContract storage singleContract = allCleanContracts[ccCounter];
        singleContract.contractId = ccCounter;
        singleContract.contractURI = _contractURI;
        singleContract.companyName = _companyName;
        singleContract.contractType = _contractType;
        singleContract.dateFrom = _dateFrom;
        singleContract.dateTo = _dateTo;
        singleContract.agreedPrice = _agreedPrice;
        singleContract.currency = _currency;
        singleContract.status = "pending";
        singleContract.creator = msg.sender;
        singleContract.contractSigner = _contractSigner;
        require(
            singleContract.creator != _contractSigner,
            "Owner can't be signer"
        );
        if (_contractSigner != address(0)) {
            bool flag = false;
            // allContractsBySigner
            uint[] storage allCons = allContractsBySigner[_contractSigner];
            for (uint i = 0; i < allCons.length; i++) {
                if (allCons[i] == ccCounter) {
                    flag = true;
                }
            }
            if (flag == false) {
                allCons.push(ccCounter);
            }
        }
        singleContract.creatorApproval = false;
        singleContract.signerApproval = false;

        uint[] storage contractsByOwner = allContractsByOwner[msg.sender];
        contractsByOwner.push(ccCounter);
    }

    // Get All Contracts
    function getAllContractsByOwner()
        public
        view
        returns (CleanContract[] memory)
    {
        uint[] memory contractsByOwner = allContractsByOwner[msg.sender];
        CleanContract[] memory contracts = new CleanContract[](
            contractsByOwner.length
        );
        for (uint i = 0; i < contractsByOwner.length; i++) {
            contracts[i] = allCleanContracts[contractsByOwner[i]];
        }
        return contracts;
    }

    // Get All Signer Contracts
    function getAllContractsBySigner()
        public
        view
        returns (CleanContract[] memory)
    {
        uint[] memory allCons = allContractsBySigner[msg.sender];
        CleanContract[] memory contracts = new CleanContract[](allCons.length);
        for (uint i = 0; i < allCons.length; i++) {
            contracts[i++] = allCleanContracts[allCons[i]];
        }
        return contracts;
    }

    // Add Contract Signer
    function addContractSigner(uint _ccID, address _contractSigner) public {
        CleanContract storage singleContract = allCleanContracts[_ccID];
        require(
            singleContract.creator == msg.sender,
            "Only contract creator can add contract signer"
        );
        require(
            singleContract.creator != _contractSigner,
            "Owner can't be signer"
        );
        singleContract.contractSigner = _contractSigner;
        bool flag = false;
        // allContractsBySigner
        uint[] storage allCons = allContractsBySigner[_contractSigner];
        for (uint i = 0; i < allCons.length; i++) {
            if (allCons[i] == _ccID) {
                flag = true;
            }
        }
        if (flag == false) {
            allCons.push(_ccID);
        }
    }

    // sign contract
    function signContract(uint ccID) public {
        CleanContract storage singleContract = allCleanContracts[ccID];
        require(
            msg.sender == singleContract.creator ||
                msg.sender == singleContract.contractSigner,
            "You don't have permission to this contract"
        );
        uint flag = 0;
        if (msg.sender == singleContract.creator) {
            singleContract.creatorApproval = true;
            singleContract.creatorSignDate = block.timestamp;
            if (singleContract.signerApproval == true) {
                singleContract.status = "signed";
                flag = 1;
            }
        } else if (msg.sender == singleContract.contractSigner) {
            singleContract.signerApproval = true;
            singleContract.signerSignDate = block.timestamp;
            if (singleContract.creatorApproval == true) {
                singleContract.status = "signed";
                flag = 2;
            }
        }
        if (flag == 1) {
            for (
                uint i = 0;
                i < allNotifies[singleContract.creator].length;
                i++
            ) {
                if (allNotifies[singleContract.creator][i].ccID == ccID) {
                    allNotifies[singleContract.creator][i].status = true;
                }
            }
        } else if (flag == 2) {
            for (
                uint i = 0;
                i < allNotifies[singleContract.contractSigner].length;
                i++
            ) {
                if (
                    allNotifies[singleContract.contractSigner][i].ccID == ccID
                ) {
                    allNotifies[singleContract.contractSigner][i].status = true;
                }
            }
        } else {
            address _notifyReceiver;
            if (msg.sender == singleContract.creator) {
                _notifyReceiver = singleContract.contractSigner;
            } else {
                _notifyReceiver = singleContract.creator;
            }

            string memory stringAddress = addressToString(msg.sender);
            string memory notifyMsg = append(
                "New signing request from ",
                stringAddress
            );

            Notify memory newNotify = Notify({
                nSender: msg.sender,
                nReceiver: _notifyReceiver,
                ccID: ccID,
                notifySentTime: 0,
                notifyContent: notifyMsg,
                status: false
            });
            allNotifies[_notifyReceiver].push(newNotify);
        }
    }

    function transferContract(uint[] memory ccIDs, address seller) public {
        uint[] storage contractsByBuyer = allContractsByOwner[msg.sender];
        uint[] storage contractsBySeller = allContractsByOwner[seller];
        for (uint i = 0; i < ccIDs.length; i++){
            contractsByBuyer.push(ccIDs[i]);
            for (uint j = 0; j <contractsBySeller.length; j++){
                if ( contractsBySeller[j] == ccIDs[i]){
                    delete contractsBySeller[j];
                }
            }
        }
    }

    // send sign notification
    function sendNotify(
        address _notifyReceiver,
        string memory _notifyContent,
        uint ccID
    ) external {
        CleanContract storage cContract = allCleanContracts[ccID];
        require(
            cContract.contractSigner != address(0),
            "Please add contract signer."
        );
        Notify[] storage notifies = allNotifies[cContract.contractSigner];
        if (notifies.length > 0) {
            require(
                notifies[notifies.length - 1].notifySentTime + 24 * 3600 <=
                    block.timestamp,
                "You can send notify once per day."
            );
        }
        Notify memory newNotify = Notify({
            nSender: msg.sender,
            nReceiver: _notifyReceiver,
            ccID: ccID,
            notifySentTime: block.timestamp,
            notifyContent: _notifyContent,
            status: false
        });
        allNotifies[_notifyReceiver].push(newNotify);
    }

    function getUploadedCounter() public view returns(uint) {
        return ccCounter;
    }

    // get my all notifies
    function getAllNotifies() public view returns (Notify[] memory) {
        return allNotifies[msg.sender];
    }

    // Devide number
    function calcDiv(uint a, uint b) external pure returns (uint) {
        return (a - (a % b)) / b;
    }

    // declare this function for use in the following 3 functions
    function toString(bytes memory data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    // cast address to string
    function addressToString(address account)
        public
        pure
        returns (string memory)
    {
        return toString(abi.encodePacked(account));
    }

    // cast uint to string
    function uintToString(uint value) public pure returns (string memory) {
        return toString(abi.encodePacked(value));
    }

    // cast bytes32 to string
    function bytesToString(bytes32 value) public pure returns (string memory) {
        return toString(abi.encodePacked(value));
    }

    function append(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }
}

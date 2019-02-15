// todo: make this in compliance with style guide
// https://solidity.readthedocs.io/en/v0.5.4/style-guide.html
// long function names, naming conventions, doxy comments

pragma solidity ^0.5.0;

contract FavorExchange {
    // ==================== type declarations ====================

    // stores information about a user
    struct User {
        // current funds
        uint balance;
    }

    // stores information about a favor
    struct Favor {
        // list links
        bytes32 prev_favor_id;
        bytes32 next_favor_id;

        // essential information
        address client_addr;
        address provider_addr;
        uint cost;

        // metadata
        bytes32 title;
        bytes32 location;
        bytes32 description;
        uint category;

        // flags
        bool client_vote_done;
        bool provider_vote_done;
        bool client_vote_cancel;
        bool provider_vote_cancel;
    }

    // ==================== state variables ====================

    // dictionary of users
    mapping(address => User) private users;

    // linked list of favors
    mapping(bytes32 => Favor) private billboard;
    bytes32 billboard_head_id;

    // ==================== events ====================

    event BalanceChanged(address user_addr);

    event FavorCreated(bytes32 favor_id);

    event FavorAccepted(bytes32 favor_id);

    event FavorVoteCancel(bytes32 favor_id, address user_addr);
    event FavorCancel(bytes32 favor_id);

    event FavorVoteDone(bytes32 favor_id, address user_addr);
    event FavorDone(bytes32 favor_id);

    // ==================== external functions ====================

    // test: acquire FVR with ether
    function testBuyToken() external payable {
        users[msg.sender].balance += msg.value;
        emit BalanceChanged(msg.sender);
    }

    // test: populate mock billboard
    function testPopulateBillboard(address _user_addr) external {
        _createFavor(_user_addr, address(0), 1, "Favor 1", "Location 1", "Description 1", 1);
        _createFavor(address(0), _user_addr, 2, "Favor 2", "Location 2", "Description 2", 2);
    }

    // get user balance
    function getUserBalance() external view returns (uint) {
        return users[msg.sender].balance;
    }

    // get id of the first favor in linked list
    function getFavorsHeadId() external view returns (bytes32) {
        return billboard_head_id;
    }

    // get basic information about favor
    function getFavorInfo(bytes32 _favor_id) external view returns (bytes32, bytes32, address, address, uint, bytes32, bytes32, bytes32, uint) {
        Favor memory favor = billboard[_favor_id];
        return (favor.prev_favor_id, favor.next_favor_id,
                favor.client_addr, favor.provider_addr, favor.cost,
                favor.title, favor.location, favor.description, favor.category);
    }

    // create a request favor
    function createRequest(uint _cost, bytes32 _title, bytes32 _location, bytes32 _description, uint _category) external returns (bytes32 favor_id) {
        require(users[msg.sender].balance >= 2 * _cost, "Insufficient funds");
        // deduct funds
        users[msg.sender].balance -= 2 * _cost;
        emit BalanceChanged(msg.sender);

        // create favor
        favor_id = _createFavor(msg.sender, address(0), _cost,
            _title, _location, _description, _category);
        emit FavorCreated(favor_id);
    }

    // create an offer favor
    function createOffer(uint _cost, bytes32 _title, bytes32 _location, bytes32 _description, uint _category) external returns (bytes32 favor_id) {
        // check if user has sufficient funds
        require(users[msg.sender].balance >= _cost, "Insufficient funds");

        // deduct funds
        users[msg.sender].balance -= _cost;
        emit BalanceChanged(msg.sender);

        // create favor
        favor_id = _createFavor(address(0), msg.sender, _cost,
            _title, _location, _description, _category);
        emit FavorCreated(favor_id);
    }

    // accept a request favor
    function acceptRequest(bytes32 _favor_id) external {
        // check if favor is valid
        require(_isFavorRequest(_favor_id), "Not a pending favor request");

        // check if user has sufficient funds
        require(users[msg.sender].balance >= billboard[_favor_id].cost, "Insufficient funds");

        // deduct funds
        users[msg.sender].balance -= billboard[_favor_id].cost;
        emit BalanceChanged(msg.sender);

        // accept request
        billboard[_favor_id].provider_addr = msg.sender;
        emit FavorAccepted(_favor_id);
    }

    // accept an offer favor
    function acceptOffer(bytes32 _favor_id) external {
        // check if favor is valid
        require(_isFavorOffer(_favor_id), "Not a pending favor offer");

        // check if user has sufficient funds
        require(users[msg.sender].balance >= 2 * billboard[_favor_id].cost, "Insufficient funds");

        // deduct funds
        users[msg.sender].balance -= 2 * billboard[_favor_id].cost;
        emit BalanceChanged(msg.sender);

        // accept request
        billboard[_favor_id].client_addr = msg.sender;
        emit FavorAccepted(_favor_id);
    }

    // request abort
    function voteCancel(bytes32 _favor_id) external {
        // check if favor is valid
        require(_isFavorMatched(_favor_id), "Not an active favor");
        // check if user is a participant
        require(_isUserInvolved(_favor_id, msg.sender), "Access denied");

        // remember vote
        if(msg.sender == billboard[_favor_id].client_addr) {
            billboard[_favor_id].client_vote_cancel = true;
        } else {
            billboard[_favor_id].provider_vote_cancel = true;
        }
        emit FavorVoteCancel(_favor_id, msg.sender);

        // check if both parties voted
        if(billboard[_favor_id].client_vote_cancel && billboard[_favor_id].provider_vote_cancel) {
            // revert transaction
            users[billboard[_favor_id].client_addr].balance += 2 * billboard[_favor_id].cost;
            emit BalanceChanged(billboard[_favor_id].client_addr);
            users[billboard[_favor_id].provider_addr].balance += billboard[_favor_id].cost;
            emit BalanceChanged(billboard[_favor_id].provider_addr);

            // clean up
            _clearFavor(_favor_id);

            // finalize
            emit FavorCancel(_favor_id);
        }
    }

    // request for completion
    function voteDone(bytes32 _favor_id) external {
        // check if favor is valid
        require(_isFavorMatched(_favor_id), "Not an active favor");
        // check if user is a participant
        require(_isUserInvolved(_favor_id, msg.sender), "Access denied");

        // remember vote
        if(msg.sender == billboard[_favor_id].client_addr) {
            billboard[_favor_id].client_vote_done = true;
        } else {
            billboard[_favor_id].provider_vote_done = true;
        }
        emit FavorVoteDone(_favor_id, msg.sender);

        // check if both parties voted
        if(billboard[_favor_id].client_vote_done && billboard[_favor_id].provider_vote_done) {
            // finalize transaction
            users[billboard[_favor_id].client_addr].balance += billboard[_favor_id].cost;
            users[billboard[_favor_id].provider_addr].balance += 2 * billboard[_favor_id].cost;

            // clean up
            _clearFavor(_favor_id);

            emit FavorDone(_favor_id);
        }
    }

    // ==================== private functions ====================

    // check if favor is first in linked list
    function _isFavorHead(bytes32 _favor_id) private view returns (bool) {
        return (!_isFavorEmpty(_favor_id)) && (_favor_id == billboard_head_id);
    }

    // check if favor is last in linked list
    function _isFavorTail(bytes32 _favor_id) private view returns (bool) {
        return (!_isFavorEmpty(_favor_id)) && (billboard[_favor_id].next_favor_id == _favor_id);
    }

    // check if favor is empty
    function _isFavorEmpty(bytes32 _favor_id) private view returns (bool) {
        return (billboard[_favor_id].client_addr == address(0)) && (billboard[_favor_id].provider_addr == address(0));
    }

    // check if favor is a request
    function _isFavorRequest(bytes32 _favor_id) private view returns (bool) {
        return (billboard[_favor_id].client_addr != address(0)) && (billboard[_favor_id].provider_addr == address(0));
    }

    // check if favor is an offer
    function _isFavorOffer(bytes32 _favor_id) private view returns (bool) {
        return (billboard[_favor_id].client_addr == address(0)) && (billboard[_favor_id].provider_addr != address(0));
    }

    // check if favor is matched
    function _isFavorMatched(bytes32 _favor_id) private view returns (bool) {
        return (billboard[_favor_id].client_addr != address(0)) && (billboard[_favor_id].provider_addr != address(0));
    }

    // check if user is client or provider
    function _isUserInvolved(bytes32 _favor_id, address _user_addr) private view returns (bool) {
        return (_user_addr == billboard[_favor_id].client_addr) || (_user_addr == billboard[_favor_id].provider_addr);
    }

    // create favor
    function _createFavor(address _client_addr, address _provider_addr, uint _cost, bytes32 _title, bytes32 _location, bytes32 _description, uint _category) private returns (bytes32 favor_id) {
        // use hash as index
        favor_id = keccak256(abi.encodePacked(_client_addr, _provider_addr, _cost, _title, _location, _description, _category));

        // update linked list links
        if(_isFavorHead(billboard_head_id)) {
            // previous head exists
            billboard[billboard_head_id].prev_favor_id = favor_id;
        } else {
            // adding first favor to list
            billboard_head_id = favor_id;
        }
        billboard[favor_id].prev_favor_id = favor_id;
        billboard[favor_id].next_favor_id = billboard_head_id;
        billboard_head_id = favor_id;

        // set essential information
        billboard[favor_id].client_addr = _client_addr;
        billboard[favor_id].provider_addr = _provider_addr;
        billboard[favor_id].cost = _cost;

        // set metadata
        billboard[favor_id].title = _title;
        billboard[favor_id].location = _location;
        billboard[favor_id].description = _description;
        billboard[favor_id].category = _category;

        // set flags
        billboard[favor_id].client_vote_done = false;
        billboard[favor_id].provider_vote_done = false;
        billboard[favor_id].client_vote_cancel = false;
        billboard[favor_id].provider_vote_cancel = false;
    }

    // clear favor
    function _clearFavor(bytes32 _favor_id) private {
        // update linked list links
        billboard[billboard[_favor_id].prev_favor_id].next_favor_id = billboard[_favor_id].next_favor_id;
        billboard[billboard[_favor_id].next_favor_id].prev_favor_id = billboard[_favor_id].prev_favor_id;
        billboard[_favor_id].prev_favor_id = 0;
        billboard[_favor_id].next_favor_id = 0;

        // clear essential information
        billboard[_favor_id].client_addr = address(0);
        billboard[_favor_id].provider_addr = address(0);
        billboard[_favor_id].cost = 0;

        // clear metadata
        billboard[_favor_id].title = "";
        billboard[_favor_id].location = "";
        billboard[_favor_id].description = "";
        billboard[_favor_id].category = 0;

        // clear flags
        billboard[_favor_id].client_vote_done = false;
        billboard[_favor_id].provider_vote_done = false;
        billboard[_favor_id].client_vote_cancel = false;
        billboard[_favor_id].provider_vote_cancel = false;
    }
}

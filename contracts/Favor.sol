// todo: make this in compliance with style guide
// https://solidity.readthedocs.io/en/v0.5.4/style-guide.html
// long function names, naming conventions, doxy comments

pragma solidity ^0.5.0;

contract Favor {
    // ==================== type declarations ====================

    // stores information about a user
    struct User {
        uint balance_fvr;  // current funds
    }

    // stores information about a listing
    struct Listing {
        // unordered list links
        bytes32 prev_listing_idx;
        bytes32 next_listing_idx;

        // essential information
        address requester_addr;
        address performer_addr;
        uint cost_fvr;

        // metadata
        bytes32 title;
        bytes32 location;
        bytes32 description;
        uint category;

        // flags
        bool requester_complete;
        bool performer_complete;
        bool requester_abort;
        bool performer_abort;
    }

    // ==================== state variables ====================

    // dictionary of users
    mapping(address => User) private users;

    // unordered list of all listings
    mapping(bytes32 => Listing) private listings;
    bytes32 listings_head_idx = 0;

    // ==================== events ====================

    event BalanceChanged(address _user_addr);
    event ListingAccepted(bytes32 _listing_idx);
    event ListingAborted(bytes32 _listing_idx);
    event ListingAbortRequest(bytes32 _listing_idx);
    event ListingCompleted(bytes32 _listing_idx);
    event ListingCompleteRequest(bytes32 _listing_idx);
    event ListingCreated(bytes32 _listing_idx);

    // ==================== external functions ====================

    // get user balance
    function getUserBalance() external view returns (uint) {
        return users[msg.sender].balance_fvr;
    }

    // acquire FVR with ether, for test purposes only
    function testBuyFVR() external payable {
        users[msg.sender].balance_fvr += msg.value;
        emit BalanceChanged(msg.sender);
    }

    // get basic information about listing
    function getListingInfo(bytes32 _listing_idx) external view returns (bytes32, bytes32, address, address, uint, bytes32, bytes32, bytes32, uint) {
        Listing memory listing = listings[_listing_idx];
        return (listing.prev_listing_idx, listing.next_listing_idx,
                listing.requester_addr, listing.performer_addr, listing.cost_fvr,
                listing.title, listing.location, listing.description, listing.category);
    }

    // create a request listing
    function createListingRequest(uint _cost_fvr,
            bytes32 _title, bytes32 _location, bytes32 _description, uint _category) external returns (bytes32 listing_idx) {
        require(users[msg.sender].balance_fvr >= 2 * _cost_fvr, "Insufficient funds");
        // deduct funds
        users[msg.sender].balance_fvr -= 2 * _cost_fvr;
        emit BalanceChanged(msg.sender);

        // create listing
        listing_idx = _createListing(msg.sender, address(0), _cost_fvr,
            _title, _location, _description, _category);
        emit ListingCreated(listing_idx);
    }

    // create an offer listing
    function createListingOffer(uint _cost_fvr,
            bytes32 _title, bytes32 _location, bytes32 _description, uint _category) external returns (bytes32 listing_idx) {
        // check if user has sufficient funds
        require(users[msg.sender].balance_fvr >= _cost_fvr, "Insufficient funds");

        // deduct funds
        users[msg.sender].balance_fvr -= _cost_fvr;
        emit BalanceChanged(msg.sender);

        // create listing
        listing_idx = _createListing(address(0), msg.sender, _cost_fvr,
            _title, _location, _description, _category);
        emit ListingCreated(listing_idx);
    }

    // accept a request listing
    function acceptListingRequest(bytes32 _listing_idx) external {
        // check if listing is valid
        require(_isListingRequestPending(_listing_idx), "Not a pending listing request");

        // check if user has sufficient funds
        require(users[msg.sender].balance_fvr >= listings[_listing_idx].cost_fvr, "Insufficient funds");

        // deduct funds
        users[msg.sender].balance_fvr -= listings[_listing_idx].cost_fvr;
        emit BalanceChanged(msg.sender);

        // accept request
        listings[_listing_idx].performer_addr = msg.sender;
        emit ListingAccepted(_listing_idx);
    }

    // accept an offer listing
    function acceptListingOffer(bytes32 _listing_idx) external {
        // check if listing is valid
        require(_isListingOfferPending(_listing_idx), "Not a pending listing offer");

        // check if user has sufficient funds
        require(users[msg.sender].balance_fvr >= 2 * listings[_listing_idx].cost_fvr, "Insufficient funds");

        // deduct funds
        users[msg.sender].balance_fvr -= 2 * listings[_listing_idx].cost_fvr;
        emit BalanceChanged(msg.sender);

        // accept request
        listings[_listing_idx].requester_addr = msg.sender;
        emit ListingAccepted(_listing_idx);
    }

    // request abort
    function requestAbortListing(bytes32 _listing_idx) external {
        // check if listing is valid
        require(_isListingMatched(_listing_idx), "Not an active listing");

        // check if user is a participant
        require(_isUserInvolved(_listing_idx, msg.sender), "Access denied");

        // set flag
        if(msg.sender == listings[_listing_idx].requester_addr) {
            listings[_listing_idx].requester_abort = true;
        } else {
            listings[_listing_idx].performer_abort = true;
        }
        emit ListingAbortRequest(_listing_idx);

        // check if both parties agree
        if(listings[_listing_idx].requester_abort && listings[_listing_idx].performer_abort) {
            // revert transaction
            users[listings[_listing_idx].requester_addr].balance_fvr += 2 * listings[_listing_idx].cost_fvr;
            emit BalanceChanged(listings[_listing_idx].requester_addr);
            users[listings[_listing_idx].performer_addr].balance_fvr += listings[_listing_idx].cost_fvr;
            emit BalanceChanged(listings[_listing_idx].performer_addr);

            // clean up
            _clearListing(_listing_idx);

            // finalize
            emit ListingAborted(_listing_idx);
        }
    }

    // request for completion
    function requestCompleteListing(bytes32 _listing_idx) external {
        require(_isListingMatched(_listing_idx), "Not an active listing");
        require(_isUserInvolved(_listing_idx, msg.sender), "Access denied");

        // record request
        if(msg.sender == listings[_listing_idx].requester_addr) {
            listings[_listing_idx].requester_complete = true;
        } else {
            listings[_listing_idx].performer_complete = true;
        }
        emit ListingCompleteRequest(_listing_idx);

        if(listings[_listing_idx].requester_complete && listings[_listing_idx].performer_complete) {
            // finalize transaction
            users[listings[_listing_idx].requester_addr].balance_fvr += listings[_listing_idx].cost_fvr;
            users[listings[_listing_idx].performer_addr].balance_fvr += 2 * listings[_listing_idx].cost_fvr;
            // clean up
            _clearListing(_listing_idx);
            emit ListingCompleted(_listing_idx);
        }
    }

    // ==================== private functions ====================

    // check if unordered list head
    function _isListingHead(bytes32 _listing_idx) private view returns (bool) {
        return (!_isListingEmpty(_listing_idx)) && (_listing_idx == listings_head_idx);
    }

    // check if unordered list tail
    function _isListingTail(bytes32 _listing_idx) private view returns (bool) {
        return (!_isListingEmpty(_listing_idx)) &&
               (listings[_listing_idx].next_listing_idx == _listing_idx);
    }

    // check if listing is empty
    function _isListingEmpty(bytes32 _listing_idx) private view returns (bool) {
        return (listings[_listing_idx].requester_addr == address(0)) &&
               (listings[_listing_idx].performer_addr == address(0));
    }

    // check if listing a request
    function _isListingRequestPending(bytes32 _listing_idx) private view returns (bool) {
        return (listings[_listing_idx].requester_addr != address(0)) &&
               (listings[_listing_idx].performer_addr == address(0));
    }

    // check if listing an offer
    function _isListingOfferPending(bytes32 _listing_idx) private view returns (bool) {
        return (listings[_listing_idx].requester_addr == address(0)) &&
               (listings[_listing_idx].performer_addr != address(0));
    }

    // check if listing is matched
    function _isListingMatched(bytes32 _listing_idx) private view returns (bool) {
        return (listings[_listing_idx].requester_addr != address(0)) &&
               (listings[_listing_idx].performer_addr != address(0));
    }

    // check if user is requester or performer
    function _isUserInvolved(bytes32 _listing_idx, address _user_addr) private view returns (bool) {
        return (_user_addr == listings[_listing_idx].requester_addr) ||
               (_user_addr == listings[_listing_idx].performer_addr);
    }

    // create listing
    function _createListing(address _requester_addr, address _performer_addr, uint _cost_fvr,
            bytes32 _title, bytes32 _location, bytes32 _description, uint _category) private returns (bytes32 listing_idx) {
        // use hash as index
        listing_idx = keccak256(abi.encodePacked(_requester_addr, _performer_addr, _cost_fvr,
            _title, _location, _description, _category));

        // update unordered list links
        if(_isListingHead(listings_head_idx)) {
            // previous head exists
            listings[listings_head_idx].prev_listing_idx = listing_idx;
        } else {
            // adding first listing to list
            listings_head_idx = listing_idx;
        }
        listings[listing_idx].prev_listing_idx = listing_idx;
        listings[listing_idx].next_listing_idx = listings_head_idx;
        listings_head_idx = listing_idx;

        // set essential information
        listings[listing_idx].requester_addr = _requester_addr;
        listings[listing_idx].performer_addr = _performer_addr;
        listings[listing_idx].cost_fvr = _cost_fvr;

        // set metadata
        listings[listing_idx].title = _title;
        listings[listing_idx].location = _location;
        listings[listing_idx].description = _description;
        listings[listing_idx].category = _category;

        // set flags
        listings[listing_idx].requester_complete = false;
        listings[listing_idx].performer_complete = false;
        listings[listing_idx].requester_abort = false;
        listings[listing_idx].performer_abort = false;
    }

    // clear listing
    function _clearListing(bytes32 _listing_idx) private {
        // update unordered list links
        listings[listings[_listing_idx].prev_listing_idx].next_listing_idx =
            listings[_listing_idx].next_listing_idx;
        listings[listings[_listing_idx].next_listing_idx].prev_listing_idx =
            listings[_listing_idx].prev_listing_idx;
        listings[_listing_idx].prev_listing_idx = 0;
        listings[_listing_idx].next_listing_idx = 0;

        // clear essential information
        listings[_listing_idx].requester_addr = address(0);
        listings[_listing_idx].performer_addr = address(0);
        listings[_listing_idx].cost_fvr = 0;

        // clear metadata
        listings[_listing_idx].title = "";
        listings[_listing_idx].location = "";
        listings[_listing_idx].description = "";
        listings[_listing_idx].category = 0;

        // clear flags
        listings[_listing_idx].requester_complete = false;
        listings[_listing_idx].performer_complete = false;
        listings[_listing_idx].requester_abort = false;
        listings[_listing_idx].performer_abort = false;
    }
}

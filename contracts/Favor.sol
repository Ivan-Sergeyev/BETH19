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
        bytes32 prev_listing_id;
        bytes32 next_listing_id;

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
    bytes32 listings_head_id = 0;

    // ==================== events ====================

    event BalanceChanged(address user_addr);
    event ListingAccepted(bytes32 listing_id);
    event ListingAborted(bytes32 listing_id);
    event ListingAbortRequest(bytes32 listing_id);
    event ListingCompleted(bytes32 listing_id);
    event ListingCompleteRequest(bytes32 listing_id);
    event ListingCreated(bytes32 listing_id);

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

    // get id of the first listing in unordered list
    function getListingsHeadId() external view returns (bytes32) {
        require(_isListingHead(listings_head_id),"No listings");
        return listings_head_id;
    }

    // get basic information about listing
    function getListingInfo(bytes32 _listing_id) external view returns (bytes32, bytes32, address, address, uint, bytes32, bytes32, bytes32, uint) {
        require(_isListingEmpty(_listing_id), "Empty listing");
        Listing memory listing = listings[_listing_id];
        return (listing.prev_listing_id, listing.next_listing_id,
                listing.requester_addr, listing.performer_addr, listing.cost_fvr,
                listing.title, listing.location, listing.description, listing.category);
    }

    // create a request listing
    function createListingRequest(uint _cost_fvr, bytes32 _title, bytes32 _location, bytes32 _description, uint _category) external returns (bytes32 listing_id) {
        require(users[msg.sender].balance_fvr >= 2 * _cost_fvr, "Insufficient funds");
        // deduct funds
        users[msg.sender].balance_fvr -= 2 * _cost_fvr;
        emit BalanceChanged(msg.sender);

        // create listing
        listing_id = _createListing(msg.sender, address(0), _cost_fvr,
            _title, _location, _description, _category);
        emit ListingCreated(listing_id);
    }

    // create an offer listing
    function createListingOffer(uint _cost_fvr, bytes32 _title, bytes32 _location, bytes32 _description, uint _category) external returns (bytes32 listing_id) {
        // check if user has sufficient funds
        require(users[msg.sender].balance_fvr >= _cost_fvr, "Insufficient funds");

        // deduct funds
        users[msg.sender].balance_fvr -= _cost_fvr;
        emit BalanceChanged(msg.sender);

        // create listing
        listing_id = _createListing(address(0), msg.sender, _cost_fvr,
            _title, _location, _description, _category);
        emit ListingCreated(listing_id);
    }

    // accept a request listing
    function acceptListingRequest(bytes32 _listing_id) external {
        // check if listing is valid
        require(_isListingRequestPending(_listing_id), "Not a pending listing request");

        // check if user has sufficient funds
        require(users[msg.sender].balance_fvr >= listings[_listing_id].cost_fvr, "Insufficient funds");

        // deduct funds
        users[msg.sender].balance_fvr -= listings[_listing_id].cost_fvr;
        emit BalanceChanged(msg.sender);

        // accept request
        listings[_listing_id].performer_addr = msg.sender;
        emit ListingAccepted(_listing_id);
    }

    // accept an offer listing
    function acceptListingOffer(bytes32 _listing_id) external {
        // check if listing is valid
        require(_isListingOfferPending(_listing_id), "Not a pending listing offer");

        // check if user has sufficient funds
        require(users[msg.sender].balance_fvr >= 2 * listings[_listing_id].cost_fvr, "Insufficient funds");

        // deduct funds
        users[msg.sender].balance_fvr -= 2 * listings[_listing_id].cost_fvr;
        emit BalanceChanged(msg.sender);

        // accept request
        listings[_listing_id].requester_addr = msg.sender;
        emit ListingAccepted(_listing_id);
    }

    // request abort
    function requestAbortListing(bytes32 _listing_id) external {
        // check if listing is valid
        require(_isListingMatched(_listing_id), "Not an active listing");

        // check if user is a participant
        require(_isUserInvolved(_listing_id, msg.sender), "Access denied");

        // set flag
        if(msg.sender == listings[_listing_id].requester_addr) {
            listings[_listing_id].requester_abort = true;
        } else {
            listings[_listing_id].performer_abort = true;
        }
        emit ListingAbortRequest(_listing_id);

        // check if both parties agree
        if(listings[_listing_id].requester_abort && listings[_listing_id].performer_abort) {
            // revert transaction
            users[listings[_listing_id].requester_addr].balance_fvr += 2 * listings[_listing_id].cost_fvr;
            emit BalanceChanged(listings[_listing_id].requester_addr);
            users[listings[_listing_id].performer_addr].balance_fvr += listings[_listing_id].cost_fvr;
            emit BalanceChanged(listings[_listing_id].performer_addr);

            // clean up
            _clearListing(_listing_id);

            // finalize
            emit ListingAborted(_listing_id);
        }
    }

    // request for completion
    function requestCompleteListing(bytes32 _listing_id) external {
        require(_isListingMatched(_listing_id), "Not an active listing");
        require(_isUserInvolved(_listing_id, msg.sender), "Access denied");

        // record request
        if(msg.sender == listings[_listing_id].requester_addr) {
            listings[_listing_id].requester_complete = true;
        } else {
            listings[_listing_id].performer_complete = true;
        }
        emit ListingCompleteRequest(_listing_id);

        if(listings[_listing_id].requester_complete && listings[_listing_id].performer_complete) {
            // finalize transaction
            users[listings[_listing_id].requester_addr].balance_fvr += listings[_listing_id].cost_fvr;
            users[listings[_listing_id].performer_addr].balance_fvr += 2 * listings[_listing_id].cost_fvr;
            // clean up
            _clearListing(_listing_id);
            emit ListingCompleted(_listing_id);
        }
    }

    // ==================== private functions ====================

    // check if unordered list head
    function _isListingHead(bytes32 _listing_id) private view returns (bool) {
        return (!_isListingEmpty(_listing_id)) && (_listing_id == listings_head_id);
    }

    // check if unordered list tail
    function _isListingTail(bytes32 _listing_id) private view returns (bool) {
        return (!_isListingEmpty(_listing_id)) &&
               (listings[_listing_id].next_listing_id == _listing_id);
    }

    // check if listing is empty
    function _isListingEmpty(bytes32 _listing_id) private view returns (bool) {
        return (listings[_listing_id].requester_addr == address(0)) &&
               (listings[_listing_id].performer_addr == address(0));
    }

    // check if listing a request
    function _isListingRequestPending(bytes32 _listing_id) private view returns (bool) {
        return (listings[_listing_id].requester_addr != address(0)) &&
               (listings[_listing_id].performer_addr == address(0));
    }

    // check if listing an offer
    function _isListingOfferPending(bytes32 _listing_id) private view returns (bool) {
        return (listings[_listing_id].requester_addr == address(0)) &&
               (listings[_listing_id].performer_addr != address(0));
    }

    // check if listing is matched
    function _isListingMatched(bytes32 _listing_id) private view returns (bool) {
        return (listings[_listing_id].requester_addr != address(0)) &&
               (listings[_listing_id].performer_addr != address(0));
    }

    // check if user is requester or performer
    function _isUserInvolved(bytes32 _listing_id, address _user_addr) private view returns (bool) {
        return (_user_addr == listings[_listing_id].requester_addr) ||
               (_user_addr == listings[_listing_id].performer_addr);
    }

    // create listing
    function _createListing(address _requester_addr, address _performer_addr, uint _cost_fvr, bytes32 _title, bytes32 _location, bytes32 _description, uint _category) private returns (bytes32 listing_id) {
        // use hash as index
        listing_id = keccak256(abi.encodePacked(_requester_addr, _performer_addr, _cost_fvr,
            _title, _location, _description, _category));

        // update unordered list links
        if(_isListingHead(listings_head_id)) {
            // previous head exists
            listings[listings_head_id].prev_listing_id = listing_id;
        } else {
            // adding first listing to list
            listings_head_id = listing_id;
        }
        listings[listing_id].prev_listing_id = listing_id;
        listings[listing_id].next_listing_id = listings_head_id;
        listings_head_id = listing_id;

        // set essential information
        listings[listing_id].requester_addr = _requester_addr;
        listings[listing_id].performer_addr = _performer_addr;
        listings[listing_id].cost_fvr = _cost_fvr;

        // set metadata
        listings[listing_id].title = _title;
        listings[listing_id].location = _location;
        listings[listing_id].description = _description;
        listings[listing_id].category = _category;

        // set flags
        listings[listing_id].requester_complete = false;
        listings[listing_id].performer_complete = false;
        listings[listing_id].requester_abort = false;
        listings[listing_id].performer_abort = false;
    }

    // clear listing
    function _clearListing(bytes32 _listing_id) private {
        // update unordered list links
        listings[listings[_listing_id].prev_listing_id].next_listing_id =
            listings[_listing_id].next_listing_id;
        listings[listings[_listing_id].next_listing_id].prev_listing_id =
            listings[_listing_id].prev_listing_id;
        listings[_listing_id].prev_listing_id = 0;
        listings[_listing_id].next_listing_id = 0;

        // clear essential information
        listings[_listing_id].requester_addr = address(0);
        listings[_listing_id].performer_addr = address(0);
        listings[_listing_id].cost_fvr = 0;

        // clear metadata
        listings[_listing_id].title = "";
        listings[_listing_id].location = "";
        listings[_listing_id].description = "";
        listings[_listing_id].category = 0;

        // clear flags
        listings[_listing_id].requester_complete = false;
        listings[_listing_id].performer_complete = false;
        listings[_listing_id].requester_abort = false;
        listings[_listing_id].performer_abort = false;
    }
}

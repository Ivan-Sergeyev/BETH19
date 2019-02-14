pragma solidity ^0.5.0;

contract Favor {
    event ListingCreated(bytes32 _listing_idx);
    event ListingAccepted(bytes32 _listing_idx);
    event ListingAbortRequest(bytes32 _listing_idx);
    event ListingAborted(bytes32 _listing_idx);
    event ListingCompleteRequest(bytes32 _listing_idx);
    event ListingCompleted(bytes32 _listing_idx);

    // note: this will be publicly visible on the whole blockchain! are we OK with that?
    struct ListingMetadata {
        bytes32 name;
        bytes32 location;
        bytes32 description;
        uint category;
    }

    struct Listing {
        bytes32 prev_listing_idx;
        bytes32 next_listing_idx;

        address requester_addr;
        address performer_addr;
        uint cost_fvr;

        bool requester_complete;
        bool performer_complete;

        bool requester_abort;
        bool performer_abort;

        ListingMetadata basic_info;
        ListingMetadata extended_info;  // todo: this should be hidden from public and only available to requester_addr and performer_addr!
    }

    struct User {
        uint balance_fvr;  // fvr

        // // todo:
        // bool is_old;
        // uint performed_count;
        // uint rep;
    }

    mapping(address => User) public users;
    mapping(bytes32 => Listing) listings;
    bytes32 listings_head_idx = 0;

    // get user balance
    function getUserBalance(address _user_addr) external view returns(uint) {
        require(msg.sender == _user_addr, "Requesting info about other user");
        return users[_user_addr].balance_fvr;
    }

    // acquire FVR with ether, for test purposes only
    uint testPriceFVR = 1 ether;

    function testBuyFVR(address _user_addr, uint _buy_fvr) external payable {
        require(msg.value == testPriceFVR * _buy_fvr, "Wrong payment value");
        users[_user_addr].balance_fvr += _buy_fvr;
    }

    function testGetPriceFVR() external view returns(uint) {
        return testPriceFVR;
    }

    // checks for list endpoints
    function _isListingHead(bytes32 _listing_idx) private view returns(bool) {
        return (!_isListingEmpty(_listing_idx)) &&
               (_listing_idx == listings_head_idx);
    }

    function _isListingTail(bytes32 _listing_idx) private view returns(bool) {
        return (!_isListingEmpty(_listing_idx)) &&
               (listings[_listing_idx].next_listing_idx == _listing_idx);
    }

    // states of listings
    function _isListingEmpty(bytes32 _listing_idx) private view returns(bool) {
        return (listings[_listing_idx].requester_addr == address(0)) &&
               (listings[_listing_idx].performer_addr == address(0));
    }

    function _isListingRequestPending(bytes32 _listing_idx) private view returns(bool) {
        return (listings[_listing_idx].requester_addr != address(0)) &&
               (listings[_listing_idx].performer_addr == address(0));
    }

    function _isListingOfferPending(bytes32 _listing_idx) private view returns(bool) {
        return (listings[_listing_idx].requester_addr == address(0)) &&
               (listings[_listing_idx].performer_addr != address(0));
    }

    function _isListingActive(bytes32 _listing_idx) private view returns(bool) {
        return (listings[_listing_idx].requester_addr != address(0)) &&
               (listings[_listing_idx].performer_addr != address(0));
    }

    // check if user is requester or performer
    function _isUserInvolved(bytes32 _listing_idx, address _user_addr) private view returns(bool) {
        return (_user_addr == listings[_listing_idx].requester_addr) ||
               (_user_addr == listings[_listing_idx].performer_addr);
    }

    // get basic information about listings
    function getListingBasicInfo(bytes32 _listing_idx) external view returns(bytes32, bytes32, bytes32, address, address, uint, bytes32, bytes32, bytes32, uint) {
        Listing memory listing = listings[_listing_idx];
        return (_listing_idx, listing.prev_listing_idx, listing.next_listing_idx,
                listing.requester_addr, listing.performer_addr, listing.cost_fvr,
                listing.basic_info.name, listing.basic_info.location, listing.basic_info.description, listing.basic_info.category);
    }

    // create listing
    function _createListing(address _requester_addr, address _performer_addr, uint _cost_fvr,
            bytes32 _basic_name, bytes32 _basic_location, bytes32 _basic_description, uint _basic_category,
            bytes32 _extended_name, bytes32 _extended_location, bytes32 _extended_description, uint _extended_category) private returns(bytes32 listing_idx) {
        listing_idx = keccak256(abi.encodePacked(_requester_addr, _performer_addr, _cost_fvr,
            _basic_name, _basic_location, _basic_description, _basic_category,
            _extended_name, _extended_location, _extended_description, _extended_category));
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

        listings[listing_idx].requester_addr = _requester_addr;
        listings[listing_idx].performer_addr = _performer_addr;
        listings[listing_idx].cost_fvr = _cost_fvr;

        listings[listing_idx].requester_complete = false;
        listings[listing_idx].performer_complete = false;

        listings[listing_idx].requester_abort = false;
        listings[listing_idx].performer_abort = false;

        listings[listing_idx].basic_info = ListingMetadata(_basic_name, _basic_location, _basic_description, _basic_category);
        listings[listing_idx].extended_info = ListingMetadata(_extended_name, _extended_location, _extended_description, _extended_category);
    }

    function createListingRequest(address _requester_addr, uint _cost_fvr,
            bytes32 _basic_name, bytes32 _basic_location, bytes32 _basic_description, uint _basic_category,
            bytes32 _extended_name, bytes32 _extended_location, bytes32 _extended_description, uint _extended_category) external returns(bytes32 listing_idx) {
        require(users[_requester_addr].balance_fvr >= 2 * _cost_fvr, "Insufficient funds");
        users[_requester_addr].balance_fvr -= 2 * _cost_fvr;
        listing_idx = _createListing(_requester_addr, address(0), _cost_fvr,
            _basic_name, _basic_location, _basic_description, _basic_category,
            _extended_name, _extended_location, _extended_description, _extended_category);
        emit ListingCreated(listing_idx);
    }

    function createListingOffer(address _performer_addr, uint _cost_fvr,
            bytes32 _basic_name, bytes32 _basic_location, bytes32 _basic_description, uint _basic_category,
            bytes32 _extended_name, bytes32 _extended_location, bytes32 _extended_description, uint _extended_category) external returns(bytes32 listing_idx) {
        require(users[_performer_addr].balance_fvr >= _cost_fvr, "Insufficient funds");
        users[_performer_addr].balance_fvr -= _cost_fvr;
        listing_idx = _createListing(address(0), _performer_addr, _cost_fvr,
            _basic_name, _basic_location, _basic_description, _basic_category,
            _extended_name, _extended_location, _extended_description, _extended_category);
        emit ListingCreated(listing_idx);
    }

    // accept listings
    function acceptListingRequest(bytes32 _listing_idx, address _performer_addr) external {
        require(_isListingRequestPending(_listing_idx), "Not a pending listing request");
        require(users[_performer_addr].balance_fvr >= listings[_listing_idx].cost_fvr, "Insufficient funds");
        users[_performer_addr].balance_fvr -= listings[_listing_idx].cost_fvr;
        listings[_listing_idx].performer_addr = _performer_addr;
        emit ListingAccepted(_listing_idx);
    }

    function acceptListingOffer(bytes32 _listing_idx, address _requeser_addr) external {
        require(_isListingOfferPending(_listing_idx), "Not a pending listing offer");
        require(users[_requeser_addr].balance_fvr >= 2 * listings[_listing_idx].cost_fvr, "Insufficient funds");
        users[_requeser_addr].balance_fvr -= 2 * listings[_listing_idx].cost_fvr;
        listings[_listing_idx].requester_addr = _requeser_addr;
        emit ListingAccepted(_listing_idx);
    }

    // // get detailed info
    // function getExtendedInfo(address _addr) external view returns(bytes32, bytes32, bytes32, uint) {
    //     require(_addr == requester_addr || _addr == performer_addr, "Access denied");
    //     return (extended_info.name, extended_info.location, extended_info.description, extended_info.category);
    // }

    // wipe listing
    function _wipeListing(bytes32 _listing_idx) private {
        listings[listings[_listing_idx].prev_listing_idx].next_listing_idx = listings[_listing_idx].next_listing_idx;
        listings[listings[_listing_idx].next_listing_idx].prev_listing_idx = listings[_listing_idx].prev_listing_idx;
        listings[_listing_idx].prev_listing_idx = 0;
        listings[_listing_idx].next_listing_idx = 0;

        listings[_listing_idx].requester_addr = address(0);
        listings[_listing_idx].performer_addr = address(0);
        listings[_listing_idx].cost_fvr = 0;

        listings[_listing_idx].requester_complete = false;
        listings[_listing_idx].performer_complete = false;

        listings[_listing_idx].requester_abort = false;
        listings[_listing_idx].performer_abort = false;

        listings[_listing_idx].basic_info = ListingMetadata("", "", "", 0);
        listings[_listing_idx].extended_info = ListingMetadata("", "", "", 0);
    }

    // request for abort
    function requestAbortListing(bytes32 _listing_idx, address _user_addr) external {
        require(_isListingActive(_listing_idx), "Not an active listing");
        require(_isUserInvolved(_listing_idx, _user_addr), "Access denied");

        // record request
        if(_user_addr == listings[_listing_idx].requester_addr) {
            listings[_listing_idx].requester_abort = true;
        } else {
            listings[_listing_idx].performer_abort = true;
        }
        emit ListingAbortRequest(_listing_idx);

        if(listings[_listing_idx].requester_abort && listings[_listing_idx].performer_abort) {
            // revert fvr transaction
            users[listings[_listing_idx].requester_addr].balance_fvr += 2 * listings[_listing_idx].cost_fvr;
            users[listings[_listing_idx].performer_addr].balance_fvr += listings[_listing_idx].cost_fvr;
            // clean up
            _wipeListing(_listing_idx);
            emit ListingAborted(_listing_idx);
        }
    }

    // request for completion
    function requestCompleteListing(bytes32 _listing_idx, address _user_addr) external {
        require(_isListingActive(_listing_idx), "Not an active listing");
        require(_isUserInvolved(_listing_idx, _user_addr), "Access denied");

        // record request
        if(_user_addr == listings[_listing_idx].requester_addr) {
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
            _wipeListing(_listing_idx);
            emit ListingCompleted(_listing_idx);
        }
    }
}

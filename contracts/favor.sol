pragma solidity ^0.5.0;

contract Favor {
    event ListingCreated(uint _listing_idx, address _user_addr);
    event ListingAccepted(uint _listing_idx, address _user_addr);
    event ListingAbortRequest(uint _listing_idx, address _user_addr);
    event ListingAborted(uint _listing_idx);
    event ListingCompleteRequest(uint _listing_idx, address _user_addr);
    event ListingCompleted(uint _listing_idx);

    // note: this will be publicly visible on the whole blockchain! are we OK with that?
    struct ListingMetadata {
        bytes32 name;
        bytes32 location;
        bytes32 description;
        uint category;
    }

    struct Listing {
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

    uint constant MAX_NUM_FAVORS = 10;
    Listing[MAX_NUM_FAVORS] listings;

    mapping(address => User) public users;

    // get user balance
    function getUserBalance(address _user_addr) external view returns(uint) {
        require(msg.sender == _user_addr, "Requesting info about other user");
        return users[_user_addr].balance_fvr;
    }

    //
    function test(address _user_addr, uint _buy_fvr) external payable {
        _user_addr[_user_addr].balance_fvr += _buy_fvr;
    }

    // states of listings
    function _isListingEmpty(uint _listing_idx) private view returns(bool) {
        return (listings[_listing_idx].requester_addr == address(0)) &&
               (listings[_listing_idx].performer_addr == address(0));
    }

    function _isListingRequestPending(uint _listing_idx) private view returns(bool) {
        return (listings[_listing_idx].requester_addr != address(0)) &&
               (listings[_listing_idx].performer_addr == address(0));
    }

    function _isListingOfferPending(uint _listing_idx) private view returns(bool) {
        return (listings[_listing_idx].requester_addr == address(0)) &&
               (listings[_listing_idx].performer_addr != address(0));
    }

    function _isListingActive(uint _listing_idx) private view returns(bool) {
        return (listings[_listing_idx].requester_addr != address(0)) &&
               (listings[_listing_idx].performer_addr != address(0));
    }

    // check if user is requester_addr or performer_addr
    function _isUserInvolved(address _user_addr, uint _listing_idx) private view returns(bool) {
        return (_user_addr == listings[_listing_idx].requester_addr) ||
               (_user_addr == listings[_listing_idx].performer_addr);
    }

    // get basic information about listings
    function getNumListings() external pure returns(uint) {
        return MAX_NUM_FAVORS;
    }

    function getListingBasicInfo(uint _listing_idx) external view returns(uint, address, address, uint, bytes32, bytes32, bytes32, uint, uint) {
        Listing memory listing = listings[_listing_idx];
        return (_listing_idx, listing.requester_addr, listing.performer_addr, listing.cost_fvr,
                listing.basic_info.name, listing.basic_info.location, listing.basic_info.description, listing.basic_info.category,
                (_listing_idx + 1) % MAX_NUM_FAVORS);
    }

    // create listings
    function _createListing(uint _listing_idx, address _requester_addr, address _performer_addr, uint _cost_fvr,
            bytes32 _basic_name, bytes32 _basic_location, bytes32 _basic_description, uint _basic_category,
            bytes32 _extended_name, bytes32 _extended_location, bytes32 _extended_description, uint _extended_category) private {
        listings[_listing_idx].requester_addr = _requester_addr;
        listings[_listing_idx].performer_addr = _performer_addr;
        listings[_listing_idx].cost_fvr = _cost_fvr;

        listings[_listing_idx].requester_complete = false;
        listings[_listing_idx].performer_complete = false;

        listings[_listing_idx].requester_abort = false;
        listings[_listing_idx].performer_abort = false;

        listings[_listing_idx].basic_info = ListingMetadata(_basic_name, _basic_location, _basic_description, _basic_category);
        listings[_listing_idx].extended_info = ListingMetadata(_extended_name, _extended_location, _extended_description, _extended_category);
    }

    function createListingRequest(uint _listing_idx, address _requester_addr, uint _cost_fvr,
            bytes32 _basic_name, bytes32 _basic_location, bytes32 _basic_description, uint _basic_category,
            bytes32 _extended_name, bytes32 _extended_location, bytes32 _extended_description, uint _extended_category) external {
        require(_isListingEmpty(_listing_idx), "Not empty listing");
        require(users[_requester_addr].balance_fvr >= 2 * _cost_fvr, "Insufficient funds");
        users[_requester_addr].balance_fvr -= 2 * _cost_fvr;
        _createListing(_listing_idx, _requester_addr, address(0), _cost_fvr,
                     _basic_name, _basic_location, _basic_description, _basic_category,
                     _extended_name, _extended_location, _extended_description, _extended_category);
        emit ListingCreated(_listing_idx, _requester_addr);
    }

    function createListingOffer(uint _listing_idx, address _performer_addr, uint _cost_fvr,
            bytes32 _basic_name, bytes32 _basic_location, bytes32 _basic_description, uint _basic_category,
            bytes32 _extended_name, bytes32 _extended_location, bytes32 _extended_description, uint _extended_category) external {
        require(_isListingEmpty(_listing_idx), "Not empty listing");
        require(users[_performer_addr].balance_fvr >= _cost_fvr, "Insufficient funds");
        users[_performer_addr].balance_fvr -= _cost_fvr;
        _createListing(_listing_idx, address(0), _performer_addr, _cost_fvr,
                     _basic_name, _basic_location, _basic_description, _basic_category,
                     _extended_name, _extended_location, _extended_description, _extended_category);
        emit ListingCreated(_listing_idx, _performer_addr);
    }

    // accept listings
    function acceptListingRequest(uint _listing_idx, address _performer_addr) external {
        require(_isListingRequestPending(_listing_idx), "Not a pending listing request");
        require(users[_performer_addr].balance_fvr >= listings[_listing_idx].cost_fvr, "Insufficient funds");
        users[_performer_addr].balance_fvr -= listings[_listing_idx].cost_fvr;
        listings[_listing_idx].performer_addr = _performer_addr;
        emit ListingAccepted(_listing_idx, _performer_addr);
    }

    function acceptListingOffer(uint _listing_idx, address _requeser_addr) external {
        require(_isListingOfferPending(_listing_idx), "Not a pending listing offer");
        require(users[_requeser_addr].balance_fvr >= 2 * listings[_listing_idx].cost_fvr, "Insufficient funds");
        users[_requeser_addr].balance_fvr -= 2 * listings[_listing_idx].cost_fvr;
        listings[_listing_idx].requester_addr = _requeser_addr;
        emit ListingAccepted(_listing_idx, _requeser_addr);
    }

    // // get detailed info
    // function getExtendedInfo(address _addr) external view returns(bytes32, bytes32, bytes32, uint) {
    //     require(_addr == requester_addr || _addr == performer_addr, "Access denied");
    //     return (extended_info.name, extended_info.location, extended_info.description, extended_info.category);
    // }

    // wipe listing
    function _wipeListing(uint _listing_idx) private {
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
    function requestAbortListing(uint _listing_idx, address _user_addres) external {
        require(_isListingActive(_listing_idx), "Not an active listing");
        require(_isUserInvolved(_user_addres, _listing_idx), "Access denied");

        // record request
        if(_user_addres == listings[_listing_idx].requester_addr) {
            listings[_listing_idx].requester_abort = true;
        } else {
            listings[_listing_idx].performer_abort = true;
        }
        emit ListingAbortRequest(_listing_idx, _user_addres);

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
    function requestCompleteListing(uint _listing_idx, address _user_addres) external {
        require(_isListingActive(_listing_idx), "Not an active listing");
        require(_isUserInvolved(_user_addres, _listing_idx), "Access denied");

        // record request
        if(_user_addres == listings[_listing_idx].requester_addr) {
            listings[_listing_idx].requester_complete = true;
        } else {
            listings[_listing_idx].performer_complete = true;
        }
        emit ListingCompleteRequest(_listing_idx, _user_addres);

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

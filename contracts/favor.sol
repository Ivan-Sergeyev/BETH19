pragma solidity ^0.5.1;

contract Favor {
    event ListingCreated(uint _listing_idx, address _user_address);
    event ListingAccepted(uint _listing_idx, address _user_address);
    event ListingAbortRequest(uint _listing_idx, address _user_address);
    event ListingAborted(uint _listing_idx);
    event ListingCompleteRequest(uint _listing_idx, address _user_address);
    event ListingCompleted(uint _listing_idx);

    // note: this will be publicly visible on the whole blockchain! are we OK with that?
    struct ListingMetadata {
        bytes32 name;
        bytes32 location;
        bytes32 description;
        uint category;
    }

    struct Listing {
        address requester;
        address performer;
        uint cost_fvr;

        bool complete_requester;
        bool complete_performer;

        bool abort_requester;
        bool abort_performer;

        ListingMetadata basic_info;
        ListingMetadata extended_info;  // todo: this should be hidden from public and only available to requester and performer!
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
        return users[_user_addr].balance_fvr;
    }

    // states of listings
    function isListingEmpty(uint _listing_idx) public view returns(bool) {
        return (listings[_listing_idx].requester == address(0)) && (listings[_listing_idx].performer == address(0));
    }

    function _isListingRequestPending(uint _listing_idx) private view returns(bool) {
        return (listings[_listing_idx].requester != address(0)) && (listings[_listing_idx].performer == address(0));
    }

    function _isListingOfferPending(uint _listing_idx) private view returns(bool) {
        return (listings[_listing_idx].requester == address(0)) && (listings[_listing_idx].performer != address(0));
    }

    function _isListingActive(uint _listing_idx) private view returns(bool) {
        return (listings[_listing_idx].requester != address(0)) && (listings[_listing_idx].performer != address(0));
    }

    // check if user is requester or performer
    function _isUserInvolved(address _user_address, uint _listing_idx) private view returns(bool) {
        return (_user_address == listings[_listing_idx].requester) || (_user_address == listings[_listing_idx].performer);
    }

    // get basic information about listings
    function getNumListings() external pure returns(uint) {
        return MAX_NUM_FAVORS;
    }

    function getListingBasicInfo(uint _listing_idx) external view returns(address,address,uint,bytes32,bytes32,bytes32,uint) {
        return (listings[_listing_idx].requester,listings[_listing_idx].performer,listings[_listing_idx].cost_fvr,
                listings[_listing_idx].basic_info.name,listings[_listing_idx].basic_info.location,listings[_listing_idx].basic_info.description,listings[_listing_idx].basic_info.category);
    }

    // create listings
    function _createListing(uint _listing_idx, address _requester_addr, address _performer_addr, uint _cost_fvr,
            bytes32 _basic_name, bytes32 _basic_location, bytes32 _basic_description, uint _basic_category,
            bytes32 _extended_name, bytes32 _extended_location, bytes32 _extended_description, uint _extended_category) private {
        listings[_listing_idx].requester = _requester_addr;
        listings[_listing_idx].performer = _performer_addr;
        listings[_listing_idx].cost_fvr = _cost_fvr;

        listings[_listing_idx].complete_requester = false;
        listings[_listing_idx].complete_performer = false;

        listings[_listing_idx].abort_requester = false;
        listings[_listing_idx].abort_performer = false;

        listings[_listing_idx].basic_info = ListingMetadata(_basic_name,_basic_location,_basic_description,_basic_category);
        listings[_listing_idx].extended_info = ListingMetadata(_extended_name,_extended_location,_extended_description,_extended_category);
    }

    function createListingRequest(uint _listing_idx, address _requester_addr, uint _cost_fvr,
            bytes32 _basic_name, bytes32 _basic_location, bytes32 _basic_description, uint _basic_category,
            bytes32 _extended_name, bytes32 _extended_location, bytes32 _extended_description, uint _extended_category) external {
        require(isListingEmpty(_listing_idx),"Not empty listing");
        require(users[_requester_addr].balance_fvr >= 2 * _cost_fvr,"Insufficient funds");
        users[_requester_addr].balance_fvr -= 2 * _cost_fvr;
        _createListing(_listing_idx,_requester_addr,address(0),_cost_fvr,
                     _basic_name,_basic_location,_basic_description,_basic_category,
                     _extended_name,_extended_location,_extended_description,_extended_category);
        emit ListingCreated(_listing_idx, _requester_addr);
    }

    function createListingOffer(uint _listing_idx, address _performer_addr, uint _cost_fvr,
            bytes32 _basic_name, bytes32 _basic_location, bytes32 _basic_description, uint _basic_category,
            bytes32 _extended_name, bytes32 _extended_location, bytes32 _extended_description, uint _extended_category) external {
        require(isListingEmpty(_listing_idx),"Not empty listing");
        require(users[_performer_addr].balance_fvr >= _cost_fvr,"Insufficient funds");
        users[_performer_addr].balance_fvr -= _cost_fvr;
        _createListing(_listing_idx,address(0),_performer_addr,_cost_fvr,
                     _basic_name,_basic_location,_basic_description,_basic_category,
                     _extended_name,_extended_location,_extended_description,_extended_category);
        emit ListingCreated(_listing_idx, _performer_addr);
    }

    // accept listings
    function acceptListingRequest(uint _listing_idx, address _performer_addr) external {
        require(_isListingRequestPending(_listing_idx),"Not a pending listing request");
        require(users[_performer_addr].balance_fvr >= listings[_listing_idx].cost_fvr,"Insufficient funds");
        users[_performer_addr].balance_fvr -= listings[_listing_idx].cost_fvr;
        listings[_listing_idx].performer = _performer_addr;
        emit ListingAccepted(_listing_idx, _performer_addr);
    }

    function acceptListingOffer(uint _listing_idx, address _requeser_addr) external {
        require(_isListingOfferPending(_listing_idx),"Not a pending listing offer");
        require(users[_requeser_addr].balance_fvr >= 2 * listings[_listing_idx].cost_fvr,"Insufficient funds");
        users[_requeser_addr].balance_fvr -= 2 * listings[_listing_idx].cost_fvr;
        listings[_listing_idx].requester = _requeser_addr;
        emit ListingAccepted(_listing_idx, _requeser_addr);
    }

    // // get detailed info
    // function getExtendedInfo(address _addr) external view returns(bytes32,bytes32,bytes32,uint) {
    //     require(_addr == requester || _addr == performer, "Access denied");
    //     return (extended_info.name,extended_info.location,extended_info.description,extended_info.category);
    // }

    // wipe listing
    function _wipeListing(uint _listing_idx) private {
        listings[_listing_idx].requester = address(0);
        listings[_listing_idx].performer = address(0);
        listings[_listing_idx].cost_fvr = 0;

        listings[_listing_idx].complete_requester = false;
        listings[_listing_idx].complete_performer = false;

        listings[_listing_idx].abort_requester = false;
        listings[_listing_idx].abort_performer = false;

        listings[_listing_idx].basic_info = ListingMetadata("","","",0);
        listings[_listing_idx].extended_info = ListingMetadata("","","",0);
    }

    // request for abort
    function requestAbortListing(uint _listing_idx, address _user_addres) external {
        require(_isListingActive(_listing_idx),"Not an active listing");
        require(_isUserInvolved(_user_addres, _listing_idx),"Access denied");

        // record request
        if(_user_addres == listings[_listing_idx].requester) {
            listings[_listing_idx].abort_requester = true;
        } else {
            listings[_listing_idx].abort_performer = true;
        }
        emit ListingAbortRequest(_listing_idx, _user_addres);

        if(listings[_listing_idx].abort_requester && listings[_listing_idx].abort_performer) {
            // revert fvr transaction
            users[listings[_listing_idx].requester].balance_fvr += 2 * listings[_listing_idx].cost_fvr;
            users[listings[_listing_idx].performer].balance_fvr += listings[_listing_idx].cost_fvr;
            // clean up
            _wipeListing(_listing_idx);
            emit ListingAborted(_listing_idx);
        }
    }

    // request for completion
    function requestCompleteListing(uint _listing_idx, address _user_addres) external {
        require(_isListingActive(_listing_idx),"Not an active listing");
        require(_isUserInvolved(_user_addres, _listing_idx),"Access denied");

        // record request
        if(_user_addres == listings[_listing_idx].requester) {
            listings[_listing_idx].complete_requester = true;
        } else {
            listings[_listing_idx].complete_performer = true;
        }
        emit ListingCompleteRequest(_listing_idx, _user_addres);

        if(listings[_listing_idx].complete_requester && listings[_listing_idx].complete_performer) {
            // finalize transaction
            users[listings[_listing_idx].requester].balance_fvr += listings[_listing_idx].cost_fvr;
            users[listings[_listing_idx].performer].balance_fvr += 2 * listings[_listing_idx].cost_fvr;
            // clean up
            _wipeListing(_listing_idx);
            emit ListingCompleted(_listing_idx);
        }
    }
}

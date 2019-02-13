pragma solidity ^0.5.1;

contract Master {

    event FavorCreated();   // todo
    event FavorAccepted();  // todo
    event FavorComplete();  // todo
    event FavorAborted();   // todo

    // note: this will be publicly visible on the whole blockchain! are we OK with that?
    struct FavorMetadata {
        string name;
        string location;
        string description;
        uint category;
    }

    struct Favor {
        address requester;
        address performer;
        uint cost_fvr;

        bool complete_requester;
        bool complete_performer;

        bool abort_requester;
        bool abort_performer;

        FavorMetadata basic_info;
        FavorMetadata extended_info;  // todo: this should be hidden from public and only available to requester and performer!
    }

    struct User {
        uint balance_fvr;  // fvr

        // // todo:
        // bool is_old;
        // uint performed_count;
        // uint rep;
    }

    uint constant MAX_NUM_FAVORS = 10;
    Favor[MAX_NUM_FAVORS] favors;

    mapping(address => User) public users;

    // states of favors
    function _isFavorEmpty(uint _favor_idx) private returns(bool) {
        return (favors[_favor_idx].requester == 0x0) && (favors[_favor_idx].performer == 0x0);
    }

    function _isFavorRequestPending(uint _favor_idx) private returns(bool) {
        return (favors[_favor_idx].requester != 0x0) && (favors[_favor_idx].performer == 0x0);
    }

    function _isFavorOfferPending(uint _favor_idx) private returns(bool) {
        return (favors[_favor_idx].requester == 0x0) && (favors[_favor_idx].performer != 0x0);
    }

    function _isFavorActive(uint _favor_idx) private returns(bool) {
        return (favors[_favor_idx].requester != 0x0) && (favors[_favor_idx].performer != 0x0);
    }

    // check if user is requester or performer
    function _isUserInvolved(address _user_addres, uint _favor_idx) private returns(bool) {
        return (_user_address == favors[_favor_idx].requester) || (_user_addres == favors[_favor_idx].performer);
    }

    // get basic information about favors
    function getNumFavors() external view returns(uint) {
        return MAX_NUM_FAVORS;
    }

    function getFavorBasicInfo(uint _favor_idx) external view returns(address,address,uint,string,string,string,uint) {
        return (favors[_favor_idx].requester,favors[_favor_idx].performer,favors[_favor_idx].cost_fvr,
                favors[_favor_idx].basic_info.name,favors[_favor_idx].basic_info.location,favors[_favor_idx].basic_info.description,favors[_favor_idx].basic_info.category);
    }

    // create favors
    function _createFavor(uint _favor_idx, address _requester_addr, address _performer_addr, uint _cost_fvr,
            string _basic_name, string _basic_location, string _basic_description, uint _basic_category,
            string _extended_name, string _extended_location, string _extended_description, uint _extended_category) private {
        favors[_favor_idx].requester = _requester_addr;
        favors[_favor_idx].performer = _performer_addr;
        favors[_favor_idx].cost_fvr = _cost_fvr;

        favors[_favor_idx].complete_requester = false;
        favors[_favor_idx].complete_performer = false;

        favors[_favor_idx].abort_requester = false;
        favors[_favor_idx].abort_performer = false;

        favors[_favor_idx].basic_info = FavorMetadata(_basic_name,_basic_location,_basic_description,_basic_category);
        favors[_favor_idx].extended_info = FavorMetadata(_extended_name,_extended_location,_extended_description,_extended_category);
    }

    function createFavorRequest(address _requester_addr, uint _cost_fvr,
            string _basic_name, string _basic_location, string _basic_description, uint _basic_category,
            string _extended_name, string _extended_location, string _extended_description, uint _extended_category) external returns(uint) {
        require (users[_requester_addr].balance_fvr >= 2 * _cost_fvr);
        for(int i = 0; i < MAX_NUM_FAVORS; ++i) {
            if(_isFavorEmpty(i)) {
                users[_requester_addr].balance_fvr -= 2 * _cost_fvr;
                _createFavor(i,_requester_addr,0x0,_cost_fvr,
                             _basic_name,_basic_location,_basic_description,_basic_category,
                             _extended_name,_extended_location,_extended_description,_extended_category);
                return i;
            }
        }
        // failed to add new favor: all spots taken
        return MAX_NUM_FAVORS;
    }

    function createFavorOffer(address _performer_addr, uint _cost_fvr,
            string _basic_name, string _basic_location, string _basic_description, uint _basic_category,
            string _extended_name, string _extended_location, string _extended_description, uint _extended_category) external returns(uint) {
        require(users[_performer_addr].balance_fvr >= _cost_fvr);
        for(int i = 0; i < MAX_NUM_FAVORS; ++i) {
            if(_isFavorEmpty(i)) {
                users[_performer_addr].balance_fvr -= _cost_fvr;
                favors[i] = Favor(favors_list_head,0x0,_performer_addr,_cost_fvr,
                                  FavorMetadata(_basic_name,_basic_location,_basic_description,_basic_category),
                                  FavorMetadata(_extended_name,_extended_location,_extended_description,_extended_category));
                return i;
            }
        }
        // failed to add new favor: all spots taken
        return MAX_NUM_FAVORS;
    }

    // accept favors
    function acceptFavorRequest(address _performer_addr, uint _favor_idx) external {
        require(_isFavorRequestPending(_favor_idx));
        require(users[_performer_addr].balance_fvr >= _cost_fvr);
        users[_performer_addr].balance_fvr -= _cost_fvr;
        favors[i].performer = _performer_addr;
    }

    function acceptFavorOffer(address _requeser_addr, uint _favor_idx) external {
        require(_isFavorRequestPending(_favor_idx));
        require(users[_requeser_addr].balance_fvr >= 2 * _cost_fvr);
        users[_requeser_addr].balance_fvr -= 2 * _cost_fvr;
        favors[i].requester = _requeser_addr;
    }

    // // get detailed info
    // function getExtendedInfo(address _addr) external view returns(string,string,string,uint) {
    //     require(_addr == requester || _addr == performer, "Access denied");
    //     return (extended_info.name,extended_info.location,extended_info.description,extended_info.category);
    // }

    // abort favor
    function _wipeFavor(uint _favor_idx) private {
        favors[_favor_idx].requester = 0x0;
        favors[_favor_idx].performer = 0x0;
        favors[_favor_idx].cost_fvr = 0;

        favors[_favor_idx].complete_requester = false;
        favors[_favor_idx].complete_performer = false;

        favors[_favor_idx].abort_requester = false;
        favors[_favor_idx].abort_performer = false;

        favors[_favor_idx].basic_info = FavorMetadata("","","",0);
        favors[_favor_idx].extended_info = FavorMetadata("","","",0);
    }

    function requestAbortFavor(address _user_addres, uint _favor_idx) external {
        require(_isFavorActive(_favor_idx));
        require(_isUserInvolved(_user_addres, _favor_idx));

        if(_user_addres == favors[_favor_idx].requester) {
            favors[_favor_idx].abort_requester = true;
        } else {
            favors[_favor_idx].abort_performer = true;
        }

        if(favors[_favor_idx].abort_requester && favors[_favor_idx].abort_performer) {
            // revert fvr transaction
            users[favors[_favor_idx].requester].balance_fvr += 2 * favors[_favor_idx].cost_fvr;
            users[favors[_favor_idx].performer].balance_fvr += favors[_favor_idx].cost_fvr;
            // clean up
            _wipeFavor(_favor_idx);
        }
    }

    // complete favor
    function requestCompleteFavor(address _user_addres, uint _favor_idx) external {
        require(_isFavorActive(_favor_idx));
        require(_isUserInvolved(_user_addres, _favor_idx));

        if(_user_addres == favors[_favor_idx].requester) {
            favors[_favor_idx].complete_requester = true;
        } else {
            favors[_favor_idx].complete_performer = true;
        }

        if(favors[_favor_idx].complete_requester && favors[_favor_idx].complete_performer) {
            // finalize transaction
            users[favors[_favor_idx].requester].balance_fvr += favors[_favor_idx].cost_fvr;
            users[favors[_favor_idx].performer].balance_fvr += 2 * favors[_favor_idx].cost_fvr;
            // clean up
            _wipeFavor(_favor_idx);
        }
    }
}

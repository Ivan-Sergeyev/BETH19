pragma solidity ^0.5.1;

contract Master {

    event FavorComplete();  // todo

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

        FavorMetadata basic_info;
        FavorMetadata extended_info;  // todo: should be hidden from public and only available to requester and performer!
    }

    struct User {
        bool is_new = true;
        uint performed_count;

        uint balance;  // fvr
        uint rep;
    }

    mapping(address => User) public users;

    uint constant MAX_NUM_FAVORS = 10;
    Favor[MAX_NUM_FAVORS] favors;

    // favor states
    function _isFavorEmpty(uint _favor_idx) private returns(bool) {
        return (favors[_favor_idx].requester == 0x0) && (favors[_favor_idx].performer == 0x0);
    }

    function _isFavorPending(uint _favor_idx) private returns(bool) {
        return (favors[_favor_idx].requester != 0x0) ^ (favors[_favor_idx].performer != 0x0);
    }

    function _isFavorActive(uint _favor_idx) private returns(bool) {
        return (favors[_favor_idx].requester != 0x0) && (favors[_favor_idx].performer != 0x0);
    }

    function newFavor(address _requester, uint _cost_fvr,
            string _basic_name, string _basic_location, string _basic_description, uint _basic_category,
            string _extended_name, string _extended_location, string _extended_description, uint _extended_category) external returns(uint) {
        for(int i = 0; i < MAX_NUM_FAVORS; ++i) {
            if(_isFavorEmpty(i)) {
                favors[i] = Favor(favors_list_head,_requester,0x0,_cost_fvr,
                                  FavorMetadata(_basic_name,_basic_location,_basic_description,_basic_category),
                                  FavorMetadata(_extended_name,_extended_location,_extended_description,_extended_category));
                return i;
            }
        }
        // failed to add new favor: all spots taken
        return MAX_NUM_FAVORS;
    }

    function getNumFavors() external view returns(uint) {
        return MAX_NUM_FAVORS;
    }

    function getFavorBasicInfo(uint _favor_idx) external view returns(address,address,uint,string,string,string,uint) {
        return (favors[_favor_idx].requester,favors[_favor_idx].performer,favors[_favor_idx].cost_fvr,
                favors[_favor_idx].basic_info.name,favors[_favor_idx].basic_info.location,favors[_favor_idx].basic_info.description,favors[_favor_idx].basic_info.category);
    }

    function getExtendedInfo(address _addr) external view returns(string,string,string,uint) {
        require(_addr == requester || _addr == performer, "Access denied");
        return (extended_info.name,extended_info.location,extended_info.description,extended_info.category);
    }



}

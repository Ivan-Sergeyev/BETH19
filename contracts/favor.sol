pragma solidity ^0.5.1;

contract Master {

    // note: this will be publicly visible on the whole blockchain! are we OK with that?
    struct FavorMetadata {
        string name;
        string location;
        string description;
        uint category;
    }

    struct Favor {
        uint next_favors_list_idx;  // link to next favor in list

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

        mapping(uint => uint) active_favors;  // linked list
        uint active_favors_head = 0;
    }

    mapping(address => User) public users;
    uint user_count = 0;

    uint fvr_count = 0;

    mapping(uint => Favor) favors_list;  // linked list
    uint favors_list_head = 0;

    function isFavorEmpty(Favor memory _favor) internal returns(bool) {
        ;
    }

    function isUserFavorEmpty(address _user, uint _favor_idx) internal returns(bool) {
        Favor memory favor = users[_user].active_favors[_favor_idx];
        return (favor.requester == 0x0) && (favor.performer == 0x0);
    }

    function nextFavorsListHead() internal {
        while(!isFavorEmpty(,active_favors_head) != 0x0) {
            ++active_favors_head;
        }
    }

    function isFavorEmpty(uint _favor_idx) internal returns (bool) {
        Favor memory favor = favors_list[_favor_idx];
        return (favor.requester == 0x0) && (favor.performer == 0x0);
    }

    function isFavorActive(uint _favor_idx) internal returns (bool) {
        return (favors_list[_favor_idx].requester != 0x0) &&
               (favors_list[_favor_idx].performer != 0x0);
    }

    function nextFavorsListHead() internal {
        while(!isFavorEmpty(favors_list_head) != 0x0) {
            ++favors_list_head;
        }
    }

    function newFavor(address _requester, uint _cost_fvr,
            string _basic_name, string _basic_location, string _basic_description, uint _basic_category,
            string _extended_name, string _extended_location, string _extended_description, uint _extended_category) public returns(uint) {
        // create new favor
        FavorMetadata memory basic_info = FavorMetadata(_basic_name,_basic_location,_basic_description,_basic_category);
        FavorMetadata memory extended_info = FavorMetadata(_extended_name,_extended_location,_extended_description,_extended_category);
        Favor memory new_favor = Favor(favors_list_head,_requester,0x0,_cost_fvr,basic_info,extended_info);

        // add favor to user's list of active favors
        // todo

        // add favor to list
        uint cur_head = favors_list_head;
        favors_list[favors_list_head] = new_favor;
        nextFavorsListHead();
        return cur_head;
    }

    function getBasicInfo(address addr) external view returns(string,string,string,uint) {
        return (basic_info.name,basic_info.location,basic_info.description,basic_info.category);
    }

    function getExtendedInfo(address addr) external view returns(string,string,string,uint) {
        require(addr == requester || addr == performer);
        return (extended_info.name,extended_info.location,extended_info.description,extended_info.category);
    }



}

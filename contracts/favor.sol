pragma solidity ^0.5.1;

contract Favor {

	struct BasicInfo {
		bytes32 name;
		bytes32 location;
		bytes32 description;
		uint category;
	}

	// note: this will be publicly visible on the whole blockchain! we don't want that!
	struct ExtendedInfo {
		bytes32 name;
		bytes32 location;
		bytes32 description;
		uint category;
	}

	uint prev_favor_idx;
	uint next_favor_idx;

	BasicInfo basic_info;
	ExtendedInfo extended_info;

	address requester;
	address performer;
	uint cost;

	function getBasicInfo(address addr) external view returns(bytes32,bytes32,bytes32,uint) {
		return ;
	}

	function getExtendedInfo(address addr) external view returns(ExtendedInfo) {
		require(addr == requester || addr == performer);
		return ExtendedInfo;
	}

	function 

}


contract Master {
	
	struct User {
		uint balance;
		mapping(uint => uint) favors_requesting;
		mapping(uint => uint) favors_performing;
		bool is_new;
		uint performed_count;
		uint rep;
	}

	mapping(address => User) public users;
	uint user_count;

	mapping(uing =>Favor) favors;
	uint head_favor;

	uint fvr_count;

}


contract LinkedList {

  event AddEntry(bytes32 head,uint number,bytes32 name,bytes32 next);

  uint public length = 0;//also used as nonce

  struct Object{
    bytes32 next;
    uint number;
    bytes32 name;
  }

  bytes32 public head;
  mapping (bytes32 => Object) public objects;

  function LinkedList(){}

  function addEntry(uint _number,bytes32 _name) public returns (bool){
    Object memory object = Object(head,_number,_name);
    bytes32 id = sha3(object.number,object.name,now,length);
    objects[id] = object;
    head = id;
    length = length+1;
    AddEntry(head,object.number,object.name,object.next);
  }

  //needed for external contract access to struct
  function getEntry(bytes32 _id) public returns (bytes32,uint,bytes32){
    return (objects[_id].next,objects[_id].number,objects[_id].name);
  }


  //------------------ totalling stuff to explore list mechanics 

  function total() public constant returns (uint) {
    bytes32 current = head;
    uint totalCount = 0;
    while( current != 0 ){
      totalCount = totalCount + objects[current].number;
      current = objects[current].next;
    }
    return totalCount;
  }

  function setTotal() public returns (bool) {
    writtenTotal = total();
    return true;
  }

  function resetTotal() public returns (bool) {
    writtenTotal = 0;
    return true;
  }

  uint public writtenTotal;

}

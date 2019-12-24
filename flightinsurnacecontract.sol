pragma solidity ^0.4.22;
import "github.com/provable-things/ethereum-api/provableAPI_0.4.25.sol";
import "github.com/Arachnid/solidity-stringutils/strings.sol";


contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    
    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract ExampleContract is usingProvable, Owned {

    struct Customer {
        string flightno;
        string query;
        bool boarded;
    }
    struct Flight {
        bool late;
        Customer[] customers;
    }
    
    //public variables
    string public status;
    bool public late;
    uint public lateseconds;
    uint flightprice;
    mapping(address => Customer) customer;
    mapping(string => address[]) flights;
    mapping(string => string) flightstatuses;
    mapping (bytes32 => string) requests;


    
    using strings for *;
    
    
    event LogConstructorInitiated(string nextStep);
    event LogPriceUpdated(string price);
    event LogNewProvableQuery(string description);
    
    //
    function parsestatus() {
        lateseconds = parseString(status);
        late = parselate(status);
        //return(true);
    }
    function lookupflight(string flight)public view returns (string r){
        return(flightstatuses[flight]);
    }
    //Call
    function __callback(bytes32 myid, string result) {
       if (msg.sender != provable_cbAddress()) revert();
       status = result;
       flightstatuses[requests[myid]] = result;
       
       //late = late(result);
       //lateseconds = parseRandomNumbers(result);
       
       LogPriceUpdated(result);
    }
    //flight status query
    function flightstatus(string flight) payable {
       if (provable_getPrice("URL") > this.balance) {
           LogNewProvableQuery("Provable query was NOT sent, please add some ETH to cover for the query fee");
       } else {
           LogNewProvableQuery("Provable query was sent, standing by for the answer..");
           bytes32 queryId = provable_query("WolframAlpha", strConcat(flight," delay time in seconds "));
           //bytes32 queryId = provable_query("URL", "json(https://www.wolframalpha.com/input/?i=JetBlue+Airways+flight+1723+delay).result");
           //provable_query("URL", append("https://www.wolframalpha.com/input/?i=",flight));
           requests[queryId] = flight;
       }
    }
    //Get numbers
    function parseString(string numbers) public view returns (uint number) {
        strings.slice memory s = numbers.toSlice();
        strings.slice memory delim = " ".toSlice();
    
        uint[] memory parts = new uint[](s.count(delim) + 1);
        for (uint i = 0; i < parts.length; i++) {
            parts[i] = parseInt(s.split(delim).toString());
        }
        return parts[0];
    }
    //Late or not
    function parselate(string numbers) public view returns(bool r ){
        strings.slice memory s = numbers.toSlice();
        late = s.contains("late".toSlice());
        return(s.contains("late".toSlice()));
    }
    
    //Register customers. Turn into ownable?
    function registerflight(string flightno) public payable{
        require(msg.value >= flightprice);
        flights[flightno].push(msg.sender);
        customer[msg.sender].flightno = flightno;
        
    }
    function customerregistered(string flightno) public view returns(bool r){
        address[] storage custs = flights[flightno];
        address sender = msg.sender;
        for (uint i = 0; i <custs.length; i++) {
            if(sender == custs[i]){
                return(true);
            }
        }
        return(false);
    }
    function customerregistered2(string flightno) public view returns(address r){
        address[] storage custs = flights[flightno];
        return(custs[0]);
    }
    function refundcustomer(string flightno) public{
        flightstatus(flightno);
        if(late){
            msg.sender.transfer(flightprice);
        }
    }


}

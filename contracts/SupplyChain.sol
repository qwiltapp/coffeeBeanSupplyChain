// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
import '../node_modules/@openzeppelin/contracts/access/Ownable.sol';
import '../node_modules/@openzeppelin/contracts/access/AccessControl.sol';


contract SupplyChain is Ownable, AccessControl {

    address payable contractOwner;

    bytes32 public constant FARMER_ROLE = keccak256('FARMER_ROLE');
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256('DISTRIBUTOR_ROLE');
    bytes32 public constant RETAILER_ROLE = keccak256('RETAILER_ROLE');
    bytes32 public constant CONSUMER_ROLE = keccak256('CONSUMER_ROLE');

    uint sku;

    mapping(bytes32 => Item) items;
    mapping(bytes32 => Exist) exists;
    mapping(uint => string[]) itemHistory;

    enum State {
        Harvested,  // 0
        Processed,  // 1
        Packed,     // 2
        AddedToPalette,    // 3
        Sold,       // 4
        Shipped,    // 5
        Received,   // 6
        SaleInitialized, // 7
        Bought   // 8
    }

    State constant defaultState = State.Harvested;

    struct Exist {
        bytes32 upc;
    }

    struct Item {
        uint    sku;  // Stock Keeping Unit (SKU)
        bytes32    upc; // Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
        address payable ownerID;  // Metamask-Ethereum address of the current owner as the product moves through 8 stages
        address payable originFarmerID; // Metamask-Ethereum address of the Farmer
        string  originFarmName; // Farmer Name
        string  originFarmInformation;  // Farmer Information
        string  originFarmLatitude; // Farm Latitude
        string  originFarmLongitude;  // Farm Longitude
        string  productName; // Product Notes
        uint    productPrice; // Product Price
        State   itemState;  // Product State as represented in the enum above
        address payable distributorID;  // Metamask-Ethereum address of the Distributor
        address payable retailerID; // Metamask-Ethereum address of the Retailer
        address payable consumerID; // Metamask-Ethereum address of the Consumer
    }

    event Harvested(bytes32 upc);
    event Processed(bytes32 upc);
    event Packed(bytes32 upc);
    event AddedToPalette(bytes32 upc);
    event Sold(bytes32 upc);
    event Shipped(bytes32 upc);
    event Received(bytes32 upc);
    event SaleInitialized(bytes32 upc);
    event Bought(bytes32 upc);

    modifier verifyCaller (address _address) {
        require(msg.sender == _address, 'Error: Caller is unverified');
        _;
    }
    modifier paidEnough(uint _price) {
        require(msg.value >= _price, 'Error: Not enough paid');
        _;
    }
    modifier refundExcess(uint _upc, address payable _address) {
        _;
        uint _price = items[keccak256(abi.encodePacked(_upc))].productPrice;
        uint amountToReturn = msg.value - _price;
        _address.transfer(amountToReturn);
    }
    modifier notContractOwner(address _address) {
        require(contractOwner != _address, 'Error: Active chain participant cannot be contract owner');
        _;
    }
    modifier onlyContractOwner(address _address) {
        require(contractOwner == _address, 'Error: Not contract owner');
        _;
    }
    modifier onlyFarmer(address _address) {
        require(hasRole(FARMER_ROLE, _address), 'Error: Not a farmer');
        _;
    }
    modifier onlyDistributor(address _address) {
        require(hasRole(DISTRIBUTOR_ROLE, _address), 'Error: Not a distributor');
        _;
    }
    modifier onlyRetailer(address _address) {
        require(hasRole(RETAILER_ROLE, _address), 'Error: Not a retailer');
        _;
    }
    modifier onlyConsumer(address _address) {
        require(hasRole(CONSUMER_ROLE, _address), 'Error: Not a consumer');
        _;
    }
    modifier harvested(uint _upc) {
        require(items[keccak256(abi.encodePacked(_upc))].itemState == State.Harvested, 'Error: Item not yet harvested');
        _;
    }
    modifier processed(uint _upc) {
        require(items[keccak256(abi.encodePacked(_upc))].itemState == State.Processed, 'Error: Item not yet processed');
        _;
    }
    modifier packed(uint _upc) {
        require(items[keccak256(abi.encodePacked(_upc))].itemState == State.Packed, 'Error: Item not yet packed');
        _;
    }
    modifier addedToPalette(uint _upc) {
        require(items[keccak256(abi.encodePacked(_upc))].itemState == State.AddedToPalette, 'Error: Item not yet added to palette');
        _;
    }
    modifier sold(uint _upc) {
        require(items[keccak256(abi.encodePacked(_upc))].itemState == State.Sold, 'Error: Item not sold');
        _;
    }
    modifier shipped(uint _upc) {
        require(items[keccak256(abi.encodePacked(_upc))].itemState == State.Shipped, 'Error: Item not shipped');
        _;
    }
    modifier received(uint _upc) {
        require(items[keccak256(abi.encodePacked(_upc))].itemState == State.Received, 'Error: Item not received');
        _;
    }
    modifier saleInitialized(uint _upc) {
        require(items[keccak256(abi.encodePacked(_upc))].itemState == State.SaleInitialized, 'Error: Sale not initialized');
        _;
    }
    modifier bought(uint _upc) {
        require(items[keccak256(abi.encodePacked(_upc))].itemState == State.Bought, 'Error: Item not bought');
        _;
    }

    constructor(
    address initialFarmer,
    address initialDistributor,
    address initialRetailer
    ) public payable notContractOwner(initialFarmer) notContractOwner(initialDistributor) notContractOwner(initialRetailer) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(FARMER_ROLE, initialFarmer);
        grantRole(DISTRIBUTOR_ROLE, initialDistributor);
        grantRole(RETAILER_ROLE, initialRetailer);
        _setRoleAdmin(CONSUMER_ROLE, RETAILER_ROLE);
        contractOwner = msg.sender;
        sku = 1;
    }

    function kill() public {
        if (msg.sender == contractOwner) {
            selfdestruct(contractOwner);
        }
    }

    function addFarmer(
    address payable farmer
    )  public onlyContractOwner(msg.sender) {
        grantRole(FARMER_ROLE, farmer);
    }

    function addDistributor(
    address payable distributor
    ) public onlyContractOwner(msg.sender) {
        grantRole(DISTRIBUTOR_ROLE, distributor);
    }

    function addRetailer(
    address payable retailer
    ) public onlyContractOwner(msg.sender) {
        grantRole(RETAILER_ROLE, retailer);
    }

    function getUserRole() public view returns (
        string memory
    ) {
        if (hasRole(FARMER_ROLE, msg.sender)) return 'farmer';
        if (hasRole(DISTRIBUTOR_ROLE, msg.sender)) return 'distributor';
        if (hasRole(RETAILER_ROLE, msg.sender)) return 'retailer';
        if (hasRole(CONSUMER_ROLE, msg.sender)) return 'consumer';
        if (contractOwner == msg.sender) return 'owner';
        return 'none';
    }

    function harvest(
    uint _upc,
    address payable _originFarmerId,
    string memory _originFarmName,
    string memory _originFarmInformation,
    string  memory _originFarmLatitude,
    string  memory _originFarmLongitude,
    string  memory _productName
    ) public onlyFarmer(msg.sender) {
        require(exists[keccak256(abi.encodePacked(_upc))].upc != keccak256(abi.encodePacked(_upc)), 'Error: UPC Exists');
        items[keccak256(abi.encodePacked(sku))].sku = sku;
        items[keccak256(abi.encodePacked(_upc))].upc = keccak256(abi.encodePacked(sku));
        items[keccak256(abi.encodePacked(_upc))].originFarmerID = _originFarmerId;
        items[keccak256(abi.encodePacked(_upc))].originFarmName = _originFarmName;
        items[keccak256(abi.encodePacked(_upc))].originFarmInformation = _originFarmInformation;
        items[keccak256(abi.encodePacked(_upc))].originFarmLatitude = _originFarmLatitude;
        items[keccak256(abi.encodePacked(_upc))].originFarmLongitude = _originFarmLongitude;
        items[keccak256(abi.encodePacked(_upc))].productName = _productName;
        items[keccak256(abi.encodePacked(_upc))].ownerID = _originFarmerId;
        items[keccak256(abi.encodePacked(_upc))].itemState = State.Harvested;
        exists[keccak256(abi.encodePacked(_upc))].upc = keccak256(abi.encodePacked(_upc));
        emit Harvested(keccak256(abi.encodePacked(_upc)));
        sku = sku + 1;
    }

    function process(
    uint _upc
    ) public onlyFarmer(msg.sender) harvested(_upc) verifyCaller(items[keccak256(abi.encodePacked(_upc))].originFarmerID) {
        items[keccak256(abi.encodePacked(_upc))].itemState = State.Processed;
        emit Processed(keccak256(abi.encodePacked(_upc)));
    }

    function pack(
    uint _upc
    ) public onlyFarmer(msg.sender) processed(_upc) verifyCaller(items[keccak256(abi.encodePacked(_upc))].originFarmerID) {
        items[keccak256(abi.encodePacked(_upc))].itemState = State.Packed;
        emit Packed(keccak256(abi.encodePacked(_upc)));
    }

    function addToPalette(
    uint _upc,
    uint _productPrice
    )  public onlyFarmer(msg.sender) packed(_upc) verifyCaller(items[keccak256(abi.encodePacked(_upc))].originFarmerID) {
        items[keccak256(abi.encodePacked(_upc))].productPrice = _productPrice;
        items[keccak256(abi.encodePacked(_upc))].itemState = State.AddedToPalette;
        emit AddedToPalette(keccak256(abi.encodePacked(_upc)));
    }

    function buyPalette(
    uint _upc
    ) public payable onlyDistributor(msg.sender)
     addedToPalette(_upc) paidEnough(items[keccak256(abi.encodePacked(_upc))].productPrice) refundExcess(_upc, msg.sender) {
        items[keccak256(abi.encodePacked(_upc))].ownerID = msg.sender;
        items[keccak256(abi.encodePacked(_upc))].distributorID = msg.sender;
        items[keccak256(abi.encodePacked(_upc))].itemState = State.Sold;
        items[keccak256(abi.encodePacked(_upc))].originFarmerID.transfer(items[keccak256(abi.encodePacked(_upc))].productPrice);
        emit Sold(keccak256(abi.encodePacked(_upc)));
    }

    function shipPalette(
    uint _upc
    ) public onlyDistributor(msg.sender)  sold(_upc) verifyCaller(items[keccak256(abi.encodePacked(_upc))].ownerID) {
        items[keccak256(abi.encodePacked(_upc))].itemState = State.Shipped;
        emit Shipped(keccak256(abi.encodePacked(_upc)));
    }

    function receivePalette(
    uint _upc
    ) public onlyRetailer(msg.sender) shipped(_upc) {
        items[keccak256(abi.encodePacked(_upc))].ownerID = msg.sender;
        items[keccak256(abi.encodePacked(_upc))].retailerID = msg.sender;
        items[keccak256(abi.encodePacked(_upc))].itemState = State.Received;
        emit Received(keccak256(abi.encodePacked(_upc)));
    }

    function initializeSale(
    uint _upc,
    address _consumerID
    ) public onlyRetailer(msg.sender) received(_upc) {
        items[keccak256(abi.encodePacked(_upc))].itemState = State.SaleInitialized;
        grantRole(CONSUMER_ROLE, _consumerID);
        emit SaleInitialized(keccak256(abi.encodePacked(_upc)));
    }

    function buy(
    uint _upc
    ) public payable onlyConsumer(msg.sender) saleInitialized(_upc)
    paidEnough(items[keccak256(abi.encodePacked(_upc))].productPrice) refundExcess(_upc, msg.sender) {
        items[keccak256(abi.encodePacked(_upc))].ownerID = msg.sender;
        items[keccak256(abi.encodePacked(_upc))].consumerID = msg.sender;
        items[keccak256(abi.encodePacked(_upc))].itemState = State.Bought;
        emit Bought(keccak256(abi.encodePacked(_upc)));
    }

    function fetchProduct(
    uint _upc
    ) public view returns (
    uint itemSKU,
    uint itemUPC,
    uint itemState,
    address ownerID,
    address originFarmerID,
    string memory originFarmName,
    string memory originFarmInformation,
    string memory originFarmLatitude,
    string memory originFarmLongitude,
    string memory productName
    ) {
        Item memory item = items[keccak256(abi.encodePacked(_upc))];

        itemSKU = item.sku;
        itemUPC = item.sku;
        itemState = uint(item.itemState);
        ownerID = item.ownerID;
        originFarmerID = item.originFarmerID;
        originFarmName = item.originFarmName;
        originFarmInformation = item.originFarmInformation;
        originFarmLatitude = item.originFarmLatitude;
        originFarmLongitude = item.originFarmLongitude;
        productName = item.productName;
    }

    function fetchProductHistory(
    uint _upc
    ) public view returns (
    address ownerID,
    address originFarmerID,
    address distributorID,
    address retailerID,
    address consumerID,
    uint itemState,
    uint productPrice
    ) {
        Item memory item = items[keccak256(abi.encodePacked(_upc))];

        ownerID = item.ownerID;
        originFarmerID = item.originFarmerID;
        distributorID = item.distributorID;
        retailerID = item.retailerID;
        consumerID = item.consumerID;
        itemState = uint(item.itemState);
        productPrice = item.productPrice;
    }
}
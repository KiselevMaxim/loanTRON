pragma solidity ^0.5.4;

import "./TRC20.sol";

contract loanTRON {
    // Only owner can do
    address public owner;
    address public oracle;
    uint256 public trxAvailable;
    uint256 public trxProfit;
    uint256 MaxLoanPeriodBlocks; //28800 blocks is 1 day
    uint256 PeriodBlocks;  //1200 blocks ~ 1 hour is smallest loan period
    uint256 MinimumLoan;  // minimum loan size
    uint256 MaximumLoan; // maximum loan size   
    uint8 LoanPercentbyPeriod;    //for percent calculation,  percent 1.5% is 15 
    TRC20 Token;
    
    struct assetInfo{
        uint8   Type;           // 0 - TRC10 1-TRC20
        uint    TypeID;         // TRC token ID, actual only for trc10, other types is 0
        string  Name;           // 'SEED'
        uint8   Decimals;       // 8
        bool    Activated;      // true
        uint256 Price;          // price for buy asset, if price 6.5 TRX value is 6500000 (6.5*10**6)
        uint256 ActuatedBlock;  // actuated block for price
        address TRC20Contract;  // TRC-20 token contract
    }
    assetInfo[] public assetList;  // list of assets with ID
    mapping (string => uint8) assets; // assets numbers name 
    uint8 public assetAmount = 0;
    
    //common loan data
    struct loanInfo{
        uint8   AssetID;
        uint256 AssetValue; 
        uint256 NeedTRX;
        uint256 Price;
        uint256 StartBlock;
        bool    LoanRepaid;
        uint8   LoanPercentbyPeriod;
        uint256 PeriodBlocks;
    }
    // users loans, LoanID is index in loanInfo[]
    mapping (address => loanInfo[]) public AddressLoans;
    
    // User - UserLoanID
    struct AddressLoan {
        address User;
        uint256 UserLoanID;
    }
    
    // total loan set of blocks#, every block is array of address borrower
    mapping (uint256 => address[]) AllLoans;
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
    // Only Oracle Pulsar can do
    modifier onlyOracle {
        require(oracle == msg.sender);
        _;
    }
    constructor() public{
        owner = msg.sender;
        assetInfo memory newAsset;
        MaxLoanPeriodBlocks = 28800;        //28800 blocks is 1 day
        PeriodBlocks        = 10;           //1200 blocks ~ 1 hour is smallest loan period
        MinimumLoan         = 10  * 10**6;  // minimum loan size
        MaximumLoan         = 1000* 10**6;  // maximum loan size   
        LoanPercentbyPeriod = 15;           //for percent calculation,  percent 1.5% is 15
        trxProfit           = 0;            //set start profit
        newAsset.Type       = 0;
        newAsset.TypeID     = 0;
        newAsset.Name       = '';
        newAsset.Decimals   = 0;
        newAsset.Activated  = false;
        newAsset.Price      = 0;
        newAsset.ActuatedBlock = 0;        
        assetList.push(newAsset);
    }
    function() external payable {
        trxAvailable += msg.value;
    }
    // Change owner
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    // Set Oracle 
    function setOracle(address addressOracle) public onlyOwner {
        oracle = addressOracle;
    }
    // Actuate asset minimum price for buy now
    function actuateAsset(uint8 AssetID, uint256 AssetPrice) public onlyOracle {
        require(AssetID >= 0);
        require(AssetPrice > 0);
        assetList[AssetID].Price = AssetPrice;
        assetList[AssetID].ActuatedBlock = block.number;
    }
    // register only new asset
    function setAsset(uint8 Type, uint TypeID, string memory Name, uint8 Decimals, 
                      bool Activated, address TRC20Token) public onlyOwner returns(uint8) {
        uint8 foundAssetNumber = assets[Name];
        // if not found - register new record
        if (foundAssetNumber == 0){
            assetAmount += 1;
            foundAssetNumber = assetAmount;
            assets[Name] = foundAssetNumber;
            assetInfo memory newAsset;
            newAsset.Type = Type;
            newAsset.TypeID = TypeID;
            newAsset.Name = Name;
            newAsset.Decimals = Decimals;
            newAsset.Activated = Activated;
            newAsset.Price = 0;
            newAsset.ActuatedBlock = 0;
            newAsset.TRC20Contract = TRC20Token;
            assetList.push(newAsset);
        } else {
            assetList[foundAssetNumber].Type = Type;
            assetList[foundAssetNumber].TypeID = TypeID;
            assetList[foundAssetNumber].Name = Name;
            assetList[foundAssetNumber].Decimals = Decimals;
            assetList[foundAssetNumber].Activated = Activated;
            assetList[foundAssetNumber].TRC20Contract = TRC20Token;
        }
        return(foundAssetNumber);
    }
    // get asset by number
    function GetAsset(uint assetNumber) 
        public view returns (uint8, uint, string memory, uint8, bool, uint256, uint256) {
        require(assetNumber >= 0);
        require(assetNumber <= assetAmount);
        return(
            assetList[assetNumber].Type,
            assetList[assetNumber].TypeID,
            assetList[assetNumber].Name,
            assetList[assetNumber].Decimals,
            assetList[assetNumber].Activated,
            assetList[assetNumber].Price,
            assetList[assetNumber].ActuatedBlock);
    }
    // get additional asset by number
    function GetAsset2(uint assetNumber) public view returns (address) {
        require(assetNumber >= 0);
        require(assetNumber <= assetAmount);
        return(assetList[assetNumber].TRC20Contract);
    }
    function DepositeTRX() public payable onlyOwner{
        require(msg.value > 0);
        trxAvailable += msg.value;
    }
    function WithdrawTRX() public payable onlyOwner{
        require(msg.value > 0);
        require(msg.value <= trxAvailable);
        trxAvailable -= msg.value;
        address(uint160(owner)).transfer(msg.value);
    }
    // user asks for get asset ability
    function getAssetAbility(uint8 AssetID) public view returns(uint256) {
        require(assetList[AssetID].Activated);
        require((block.number - assetList[AssetID].ActuatedBlock) < 600 );
        require(assetList[AssetID].Price > 0);
        return(trxAvailable / assetList[AssetID].Price);
    }
    // start loan with trc20
    function startLoan(uint8 AssetID, uint256 AssetValue, uint256 NeedTRX) public payable {
        require(trxAvailable >= MinimumLoan);
        require(NeedTRX >= MinimumLoan);
        require(NeedTRX <= MaximumLoan);
        require(assetList[AssetID].Activated);
        require(assetList[AssetID].Price > 0);
        uint256 _calcedAssetValue = NeedTRX / assetList[AssetID].Price;
        require(_calcedAssetValue == AssetValue);        
        // check allowence for TRC20 
        /*if (assetList[AssetID].Type == 1) {
            if (Token(assetList[AssetID].TRC20Contract).allowance(msg.sender, owner)){                
                if (Token(assetList[AssetID].TRC20Contract).transferFrom(msg.sender, this, AssetValue)){
                    //TODO finish it
                }
            }
            // its from etherdelta
            if (token==0) throw;
            if (!Token(token).transferFrom(msg.sender, this, amount)) throw;
            tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
            Deposit(token, msg.sender, amount, tokens[token][msg.sender])
        }*/

        // allowance(        address owner,        address spender    )
        // Create loan record unique for this address, get LoanID for the address, add Address-LoanID to AddressList, add LoanID to TotalList
        loanInfo memory _loan; 
        _loan.AssetID               = AssetID;
        _loan.AssetValue            = AssetValue;
        _loan.NeedTRX               = NeedTRX;
        _loan.Price                 = assetList[AssetID].Price;
        _loan.StartBlock            = block.number;
        _loan.LoanRepaid            = false;
        _loan.LoanPercentbyPeriod   = LoanPercentbyPeriod;
        _loan.PeriodBlocks          = PeriodBlocks;
        AddressLoans[msg.sender].push(_loan);        
        AllLoans[block.number].push(msg.sender);
        trxAvailable -= NeedTRX;
        // Send TRX from USER to CONTRACT
        address(msg.sender).transfer(NeedTRX);
        // Transfer tokens from user to contract        
    }
    // Get loans count at block
    function getBlockLoansCount(uint256 _blockNum) public view onlyOracle returns(uint256) {
        return(AllLoans[_blockNum].length);
    }
    // Get loan address at block number by number 
    function getAddrByBlockLoanNum(uint256 _blockNum, uint256 _loanNum) public view onlyOracle returns(address) {
        //address[] memory Borrowers = AllLoans[_blockNum];
        //return(Borrowers[_loanNum]);
        return(AllLoans[_blockNum][_loanNum]);
    }
    // Get count of loans
    function getMyLoansCount() public view returns(uint256){
        return AddressLoans[msg.sender].length;
    }
    // Get loan details by ID
    function getLoanByID(uint256 i, address _user) public view returns(uint8, uint256, uint256, uint256, uint256, bool){        
        return ( 
            AddressLoans[_user][i].AssetID,
            AddressLoans[_user][i].AssetValue,
            AddressLoans[_user][i].NeedTRX,
            AddressLoans[_user][i].Price,
            AddressLoans[_user][i].StartBlock,
            AddressLoans[_user][i].LoanRepaid);
    }
    // Get all my loan details by ID
    function getMyLoanByID(uint256 i) public view returns(uint8, uint256, uint256, uint256, uint256, bool){        
        return (getLoanByID(i, msg.sender));
    }
    // Get loan details extension by ID
    function getLoanByID2(uint256 i, address _user) public view returns(uint8, uint256, uint256, uint256){
        uint8   _LoanPercentbyPeriod = AddressLoans[_user][i].LoanPercentbyPeriod;
        uint256 _PeriodBlocks        = AddressLoans[_user][i].PeriodBlocks;
        uint256 _StartBlock          = AddressLoans[_user][i].StartBlock;
        uint256 _loanpercent = (block.number - _StartBlock + _PeriodBlocks) / _PeriodBlocks * _LoanPercentbyPeriod;
        uint256 _amounttorepaid = AddressLoans[_user][i].NeedTRX + AddressLoans[_user][i].NeedTRX * _loanpercent / 1000;
        return (
            _LoanPercentbyPeriod,
            _PeriodBlocks,
            _loanpercent,
            _amounttorepaid);
    }
    // Get all my loan details extension by ID
    function getMyLoanByID2(uint256 i) public view returns(uint8, uint256, uint256, uint256){        
        return (getLoanByID2(i, msg.sender));
    }
    // Close loan by Oracle
    function OracleLoanRepay(uint256 i, address addressBorrower) public payable onlyOracle{
        require(addressBorrower != address(0x0));
        require(i <= AddressLoans[addressBorrower].length);
        require(!AddressLoans[addressBorrower][i].LoanRepaid);
        uint256 _amounttorepaid;
        (, , , _amounttorepaid) = getLoanByID2(i, addressBorrower);
        require(msg.value == _amounttorepaid);
        AddressLoans[addressBorrower][i].LoanRepaid = true;
        trxProfit += msg.value - AddressLoans[addressBorrower][i].NeedTRX;
        trxAvailable += AddressLoans[addressBorrower][i].NeedTRX;
    }
    // Close loan by user-borrower
    function ILoanRepay(uint256 i) public payable{
        //require(msg.sender != address(0x0));
        if (!(msg.sender != address(0x0))) revert('account must be not 0x0');
        //require(i <= AddressLoans[msg.sender].length);
        if (!(i <= AddressLoans[msg.sender].length)) revert('i < AddressLoans');
        //require(!AddressLoans[msg.sender][i].LoanRepaid);
        if (!(!AddressLoans[msg.sender][i].LoanRepaid)) revert('loan already repaid!');
        uint256 _amounttorepaid;
        (, , , _amounttorepaid) = getMyLoanByID2(i);
        //require(msg.value == _amounttorepaid);
        if (!(msg.value == _amounttorepaid)) revert('msg.value not satisfy _amounttorepaid!');

        AddressLoans[msg.sender][i].LoanRepaid = true;
        trxProfit += msg.value - AddressLoans[msg.sender][i].NeedTRX;
        trxAvailable += AddressLoans[msg.sender][i].NeedTRX;
        // send tokens
    }    
    // TODO: paid feature
    // TODO: add events: started loan, loan reapid, closed uotdated loan
}
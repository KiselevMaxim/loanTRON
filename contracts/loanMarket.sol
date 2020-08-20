pragma solidity ^0.5.4;

contract TRC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract loanMarket {
    // Only owner can do
    address public owner;
    address public oracle;
    uint256 public trxAvailable;
    uint256 public trxProfit;
    uint256 MaxLoanPeriodBlocks; //28800 blocks is 1 day
    uint256 MinimumLoan;         // minimum loan size
    uint256 MaximumLoan;         // maximum loan size
    uint256 AssetFee;            //service fee on main asset profit 10% is value 1000
    uint256 SecuredAssetFee;     //service fee on secured asset 0.1% is value 10
    TRC20 Token;

    // Base structure
    struct assetInfo{
        uint8   Type;           // 0 - TRC10 1-TRC20
        uint    TypeID;         // TRC token ID, actual only for trc10, other types is 0
        string  Name;           // 'SEED'
        uint8   Decimals;       // 8
        bool    Activated;      // true
        uint256 ActuatedBlock;  // actuated block for price
        address TRC20Contract;  // TRC-20 token contract
    }
    assetInfo[] public assetList;  // list of assets with ID
    mapping (string => uint256) assets; // assets numbers name 
    uint8 public assetAmount = 0;    
    mapping (address => 
        mapping(uint256 => uint256)) assetProfit; // address - assetID - value
    // Loan status: (create->) open (accept->) accepted (repay->) paid (close->) closed
    struct LoanStatus{
        bool isOpened;
        bool isAccepted;
        bool isPaid;
        bool isClosed;
    }
    //common loan data, connected to assetid 
    struct LoanInfo{
        address Creditor;           // Creditor address
        address Borrower;           // Borrower address
        uint256 CreditAssetID;      // Credit asset: creditor give it to borrower
        uint256 CreditAssetValue; 
        uint256 CreditAssetRepaidValue; 
        uint256 SecuredAssetID;     // Borrower send it to creditor to secure credit
        uint256 SecuredAssetValue;
        uint256 StartBlock;
        LoanStatus Status;          // Loan status
        uint256 LoanPercentbyPeriod;// % for one period, example 10% is value 1000, 0.1% is value 10
        uint256 PeriodBlocks;       // period length mesured in blocks
        uint256 LiveTimeBlocks;     // credit livetime in blocks, opened credit become closed after StartBlock+LiveTimeBlocks
        uint256 AssetFee;           // service fee on main asset profit 10% is value 1000
        uint256 SecuredAssetFee;    // service fee on secured asset 0.1% is value 10
    }
    // common contracts for creditors, borrowers and all assets
    LoanInfo[] Loans;
    // creditor's structure to collect created loan IDs 
    mapping (address => uint256[]) public Creditor;
    // borrower's structure to collect created loan IDs
    mapping (address => uint256[]) public Borrower;
    // Credit asset loan IDs
    mapping (uint256 => uint256[]) public CreditAssets;
    // Secured asset loan IDs
    mapping (uint256 => uint256[]) public SecuredAssets;
    // Credit asset-secured asset Loan IDs 
    mapping (uint256 => mapping (uint256 => uint256[])) public CreditSecuredAssets;

    modifier onlyOwner {
        require(owner == msg.sender);
        _;}
    // Only Oracle Pulsar can do
    modifier onlyOracle {
        require(oracle == msg.sender);
        _;}
    
    /* adding events raise contract energy overflow...
    event CreditorGrantsLoanToBorrower(address _creditor, address _borrower, uint256 _loanID);
    event BorrowerTakesLoanFromCreditor(address _creditor, address _borrower, uint256 _loanID);
    event BorrowerRepayCredit(address _creditor, address _borrower, uint256 _loanID);
    event CreditClosed(address _creditor, address _borrower, uint256 _loanID); */
    constructor() public{
        owner = msg.sender;        
        MaxLoanPeriodBlocks = 28800;        //28800 blocks is 1 day
        MinimumLoan         = 10  * 10**6;  // minimum loan size
        MaximumLoan         = 1000* 10**6;  // maximum loan size
        trxProfit           = 0;            //set start profit

        setAsset(0, 0, 'TRX', 6, true, address(0x0));
        AssetFee            = 1000;         //service fee on main asset profit 10% is value 1000
        SecuredAssetFee     = 10;           //service fee on secured asset 0.1% is value 10
    }
    function() external payable {
        trxAvailable += msg.value;
    }
    // Change owner
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;}
    // Set Oracle 
    function setOracle(address addressOracle) public onlyOwner {
        oracle = addressOracle;}
    // Actuate asset minimum price for buy now
    function actuateAsset(uint8 AssetID, uint256 AssetPrice) public onlyOracle {
        require(AssetID >= 0);
        require(AssetPrice > 0);
        assetList[AssetID].ActuatedBlock = block.number;}
    // register new asset or update existing
    function setAsset(uint8 Type, uint TypeID, string memory Name, uint8 Decimals, 
                      bool Activated, address TRC20Token) public onlyOwner {
        uint256 foundAssetNumber = assets[Name];
        // if not found - register new record
        if (foundAssetNumber == 0){
            assetAmount += 1;
            assetInfo memory newAsset;
            newAsset.Type = Type;
            newAsset.TypeID = TypeID;
            newAsset.Name = Name;
            newAsset.Decimals = Decimals;
            newAsset.Activated = Activated;
            newAsset.ActuatedBlock = 0;
            newAsset.TRC20Contract = TRC20Token;
            assetList.push(newAsset);
            assets[Name] = assetList.length - 1;
        } else {
            assetList[foundAssetNumber].Type = Type;
            assetList[foundAssetNumber].TypeID = TypeID;
            assetList[foundAssetNumber].Name = Name;
            assetList[foundAssetNumber].Decimals = Decimals;
            assetList[foundAssetNumber].Activated = Activated;
            assetList[foundAssetNumber].TRC20Contract = TRC20Token;
        }
    }
    // get asset by number
    function GetAsset(uint assetNumber) 
        public view returns (uint8, uint, string memory, uint8, bool, uint256) {
        require(assetNumber >= 0);
        require(assetNumber < assetAmount);
        return(
            assetList[assetNumber].Type,
            assetList[assetNumber].TypeID,
            assetList[assetNumber].Name,
            assetList[assetNumber].Decimals,
            assetList[assetNumber].Activated,
            assetList[assetNumber].ActuatedBlock);}
    // get additional asset by number
    function GetAsset2(uint assetNumber) public view returns (address) {        
        require(assetNumber >= 0);
        require(assetNumber < assetAmount);
        return(assetList[assetNumber].TRC20Contract);}
    // Get assetID by AssetName
    function GetAssetIDbyName(string memory AssetName) public view returns (uint256) {
        return(assets[AssetName]);
    }
    // Contract deposite TRX
    function DepositeTRX() public payable onlyOwner{
        TRXTransferFrom(msg.sender, msg.value);
    }
    // Contract deposite TRC20
    function DepositeTRC20(uint256 assetID, uint256 amount) public onlyOwner{
        uint8 Type; 
        uint TypeID; 
        string memory Name; 
        uint8 Decimals; 
        bool Activated; 
        uint256 ActuatedBlock;
        (Type, TypeID, Name, Decimals, Activated, ActuatedBlock) = GetAsset(assetID);
        require (Type == 1);                
        if (AssetTransferFrom(msg.sender, address(this), assetID, amount)) {
            assetProfit[msg.sender][assetID] += amount;
        }
    }
    // Contract withdraw
    function WithdrawTRX(address _toAddress) public payable onlyOwner{
        require(msg.value > 0);
        //require(msg.value <= trxAvailable);
        trxAvailable -= msg.value;
        //address(/*owner*/_toAddress).transfer(msg.value);
        address(uint160(_toAddress)).transfer(msg.value);
    }
    // Withdraw TRC20
    function WithdrawTRC20(uint256 AssetID, uint256 Amount) public onlyOwner{
        uint8 Type; 
        uint TypeID; 
        string memory Name; 
        uint8 Decimals; 
        bool Activated; 
        uint256 ActuatedBlock;
        (Type, TypeID, Name, Decimals, Activated, ActuatedBlock) = GetAsset(AssetID);
        require (Type == 1);
        if (AssetTransferTo(msg.sender, AssetID, Amount)) {
            assetProfit[msg.sender][AssetID] -= Amount;
        }
    }
    // Get user asset value
    function GetUserAssetValue(uint256 AssetID) public view returns (uint256) {
        require(AssetID >= 0);
        require(AssetID < assetAmount);
        return(assetProfit[msg.sender][AssetID]);
    }
    // Creditor propose loan by making record on open loans market
    function ProposeLoan(uint256 CreditAssetID, uint256 CreditAssetValue, uint256 SecuredAssetID, uint256 SecuredAssetValue, 
        uint256 LoanPercentbyPeriod, uint256 PeriodBlocks, uint256 LiveTimeBlocks) public payable{
        require(CreditAssetValue > 0);
        require(SecuredAssetValue > 0);
        require(LoanPercentbyPeriod > 0);
        require(PeriodBlocks > 0);
        require(assetList[CreditAssetID].Activated);
        require(assetList[SecuredAssetID].Activated);
        bool CreditAssetDeposited = false;
        
        if (assetList[CreditAssetID].Type == 1) { // if assset == 1 is TRC-20
            CreditAssetDeposited = AssetTransferFrom(msg.sender, address(this), CreditAssetID, CreditAssetValue);
        } else if (assetList[CreditAssetID].Type == 0 && assetList[CreditAssetID].TypeID == 0) { // if type == 0 and typeID = 0 is TRX
            TRXTransferFrom(msg.sender, msg.value);
            CreditAssetDeposited = true;
        }        
        if (CreditAssetDeposited){
            addLoanRecord(msg.sender, address(0x0), CreditAssetID, CreditAssetValue, SecuredAssetID, SecuredAssetValue, LoanPercentbyPeriod, PeriodBlocks, LiveTimeBlocks);
        }
    }
    // Borrower ask for a loan
    function AskLoan(uint256 CreditAssetID, uint256 CreditAssetValue, uint256 SecuredAssetID, uint256 SecuredAssetValue, 
        uint256 LoanPercentbyPeriod, uint256 PeriodBlocks, uint256 LiveTimeBlocks) public payable{
        require(CreditAssetValue > 0);
        require(SecuredAssetValue > 0);
        require(LoanPercentbyPeriod > 0);
        require(PeriodBlocks > 0);
        require(assetList[CreditAssetID].Activated);
        require(assetList[SecuredAssetID].Activated);
        bool SecuredAssetDeposited = false;
        
        if (assetList[SecuredAssetID].Type == 1) { // if assset == 1 is TRC-20
            SecuredAssetDeposited = AssetTransferFrom(msg.sender, address(this), SecuredAssetID, SecuredAssetValue);
        } else if (assetList[SecuredAssetID].Type == 0 && assetList[SecuredAssetID].TypeID == 0) { // if type == 0 and typeID = 0 is TRX
            TRXTransferFrom(msg.sender, msg.value);
            SecuredAssetDeposited = true;
        }        
        if (SecuredAssetDeposited){
            addLoanRecord(address(0x0), msg.sender, CreditAssetID, CreditAssetValue, SecuredAssetID, SecuredAssetValue, LoanPercentbyPeriod, PeriodBlocks, LiveTimeBlocks);
        }
    }    
    // Send some asset from this contract
    function AssetTransferTo(address aTo, uint256 AssetID, uint256 AssetValue) private returns(bool) {
        address aToken = GetAsset2(AssetID);
        require(aToken != address(0x0)/* 0 */);
        Token = TRC20(aToken);
        return(Token.transfer(aTo, AssetValue));
    }
    // Receive TRX to this contract
    function TRXTransferFrom(address aFrom, uint256 AssetValue) private {
        require(AssetValue > 0);        
        assetProfit[aFrom][0] += AssetValue;
    }
    // Receive some asset to this contract
    function AssetTransferFrom(address aFrom, address aTo, uint256 AssetID, uint256 AssetValue) private returns(bool) {
        address aToken = GetAsset2(AssetID);
        require(aToken != address(0x0)/* 0 */);
        Token = TRC20(aToken);
        return(Token.transferFrom(aFrom, aTo, AssetValue));
    }
    // utility function to add loan record
    function addLoanRecord(address aCreditor, address aBorrower, uint256 CreditAssetID, uint256 CreditAssetValue, uint256 SecuredAssetID, 
        uint256 SecuredAssetValue, uint256 LoanPercentbyPeriod, uint256 PeriodBlocks, uint256 LiveTimeBlocks) private {
        LoanInfo memory theLoan;
        theLoan.Creditor            = aCreditor;                  // Creditor address
        theLoan.Borrower            = aBorrower;           // Borrower address
        theLoan.CreditAssetID       = CreditAssetID;        // Credit asset: creditor give it to borrower
        theLoan.CreditAssetValue    = CreditAssetValue; 
        theLoan.SecuredAssetID      = SecuredAssetID;       // Borrower send it to creditor to secure credit
        theLoan.SecuredAssetValue   = SecuredAssetValue;
        theLoan.StartBlock          = 0;
        theLoan.Status.isOpened     = true;                 // Loan status
        theLoan.LoanPercentbyPeriod = LoanPercentbyPeriod;  // % for one period, example 10% is value 1000, 0.1% is value 10
        theLoan.PeriodBlocks        = PeriodBlocks;         // period length mesured in blocks
        theLoan.LiveTimeBlocks      = LiveTimeBlocks;       // credit livetime in blocks, opened credit become closed after StartBlock+LiveTimeBlocks
        theLoan.AssetFee            = AssetFee;             // service fee on main asset profit 10% is value 1000
        theLoan.SecuredAssetFee     = SecuredAssetFee;      // service fee on secured asset 0.1% is value 10

        // add to common loans list
        Loans.push(theLoan);
        uint256 CreatedLoanID = Loans.length - 1;
        // register created loan to user-creator
        if (aCreditor == address(0x0)) {
            Borrower[aBorrower].push(CreatedLoanID);
        } else {
            Creditor[aCreditor].push(CreatedLoanID);
        }
        // register created loan to  asset lists
        CreditAssets[CreditAssetID].push(CreatedLoanID);
        SecuredAssets[SecuredAssetID].push(CreatedLoanID);
        CreditSecuredAssets[CreditAssetID][SecuredAssetID].push(CreatedLoanID);
    }
    // get total loans count
    function getTotalLoansCount() public view returns(uint256) {
        return(Loans.length);
    }
    // get number of creditors loans
    function getCreditorTotalLoansCount() public view returns(uint256) {
        return(Creditor[msg.sender].length);
    }
    // get Creditors CreditID by number
    function getCreditorLoanIDBynumber(uint256 number) public view returns(uint256) {
        return(Creditor[msg.sender][number]);
    }
    // get number of borrower asked loans
    function getBorrowerTotalLoansCount() public view returns(uint256) {
        return(Borrower[msg.sender].length);
    }
    // get Borrowerss CreditID by number
    function getBorrowerLoanIDBynumber(uint256 number) public view returns(uint256) {
        return(Borrower[msg.sender][number]);
    }
    // get Credit Secured Assets Amount number
    function CreditSecuredAssetsNumber(uint256 CreditAssetID, uint256 SecuredAssetID) public view returns(uint256) {
        return(CreditSecuredAssets[CreditAssetID][SecuredAssetID].length);
    }
    // get Credit Secured AssetID by number
    function CreditSecuredAssetIDbyNumber(uint256 CreditAssetID, uint256 SecuredAssetID, uint256 number) public view returns(uint256) {
        return(CreditSecuredAssets[CreditAssetID][SecuredAssetID][number]);
    }
    // creditor grants loan, accept proposed loan by borrower
    function  CreditorGrantsLoan(uint256 LoanID) public payable{
        LoanInfo memory theLoan = Loans[LoanID];
        require(theLoan.Status.isOpened);
        require(!theLoan.Status.isAccepted);
        require(!theLoan.Status.isPaid);
        require(!theLoan.Status.isClosed);
        require(theLoan.Borrower != address(0x0));
        require(theLoan.Creditor == address(0x0));
        require(assetList[theLoan.CreditAssetID].Activated);
        require(assetList[theLoan.SecuredAssetID].Activated);
        bool LoanContractGranted = false;
        bool LoanPaid = false;
        if (assetList[theLoan.CreditAssetID].Type == 0) { // if assset == 0 creditor must send TRX 
            require(msg.value == theLoan.CreditAssetValue);
            LoanContractGranted = true;
        } else if (assetList[theLoan.CreditAssetID].Type == 1) { // if assset == 1 is TRC-20 creditor must send TRC-20
            LoanContractGranted = AssetTransferFrom(msg.sender, address(this), theLoan.CreditAssetID, theLoan.CreditAssetValue);
        }
        if (LoanContractGranted) { // if creditor send funds, lets send credit asset from contract to borrower
            if (assetList[theLoan.CreditAssetID].Type == 0) { // if assset == 0 borrower receive loan in TRX
                address(uint160(theLoan.Borrower)).transfer(theLoan.CreditAssetValue);
                LoanPaid = true;
            } else if (assetList[theLoan.CreditAssetID].Type == 1) { // if assset == 1 is TRC-20 borrower receive loan in TRC-20
                LoanPaid = AssetTransferTo(theLoan.Borrower, theLoan.CreditAssetID, theLoan.CreditAssetValue);
            }
        }
        require(LoanContractGranted && LoanPaid);
        Loans[LoanID].Creditor = msg.sender;
        Loans[LoanID].Status.isAccepted = true;
        Loans[LoanID].StartBlock = block.number;
        // emit CreditorGrantsLoanToBorrower(msg.sender, theLoan.Borrower, LoanID);
    }
    // borrower accept loan
    function  borrowerTakesLoan(uint256 LoanID) public payable{
        LoanInfo memory theLoan = Loans[LoanID];
        require(theLoan.Status.isOpened);
        require(!theLoan.Status.isAccepted);
        require(!theLoan.Status.isPaid);
        require(!theLoan.Status.isClosed);
        require(theLoan.Borrower == address(0x0));
        require(theLoan.Creditor != address(0x0));
        require(assetList[theLoan.CreditAssetID].Activated);
        require(assetList[theLoan.SecuredAssetID].Activated);
        bool LoanSecured = false;
        bool LoanPaid = false;
        if (assetList[theLoan.SecuredAssetID].Type == 0) { // if assset == 0 borrower must send TRX as secure
            require(msg.value == theLoan.SecuredAssetValue);
            LoanSecured = true;
        } else if (assetList[theLoan.SecuredAssetID].Type == 1) { // if assset == 1 is TRC-20 borrower must send TRC-20 as secure
            LoanSecured = AssetTransferFrom(msg.sender, address(this), theLoan.SecuredAssetID, theLoan.SecuredAssetValue);
        }
        if (LoanSecured) { // if borrower secured funds, lets send loan's asset to borrower
            if (assetList[theLoan.CreditAssetID].Type == 0) { // if assset == 0 borrower receive loan in TRX
                address(msg.sender).transfer(theLoan.CreditAssetValue);
                LoanPaid = true;
            } else if (assetList[theLoan.CreditAssetID].Type == 1) { // if assset == 1 is TRC-20 borrower receive loan in TRC-20
                LoanPaid = AssetTransferTo(msg.sender, theLoan.CreditAssetID, theLoan.CreditAssetValue);
            }
        }
        require(LoanSecured && LoanPaid);
        Loans[LoanID].Borrower = msg.sender;
        Loans[LoanID].Status.isAccepted = true;
        Loans[LoanID].StartBlock = block.number;
        // emit BorrowerTakesLoanFromCreditor(theLoan.Creditor, msg.sender, LoanID);
    }
    // Borrower repays loan
    function borrowerRepay(uint256 LoanID) public payable{
        LoanInfo memory theLoan = Loans[LoanID];
        require(theLoan.Borrower == msg.sender);
        require(theLoan.Status.isOpened);
        require(theLoan.Status.isAccepted);
        require(!theLoan.Status.isPaid);
        require(!theLoan.Status.isClosed);
        require((theLoan.StartBlock + theLoan.LiveTimeBlocks) >= block.number); // the loan is not overdue, StartBlock + LiveTimeBlocks must be lower block.number        
        bool LoanSecuritySentBack = false; 
        bool LoanRepaid = false;
        uint256 CreditAssetVallueToRepay = getRepaySumCalc(theLoan.StartBlock, theLoan.PeriodBlocks, theLoan.LoanPercentbyPeriod, theLoan.CreditAssetValue);
        
        if (assetList[theLoan.CreditAssetID].Type == 0) { // if assset == 0 borrower repay loan in TRX, sending TRX+interest
            require(msg.value == CreditAssetVallueToRepay);
            LoanRepaid = true;
        } else if (assetList[theLoan.CreditAssetID].Type == 1) { // if assset == 1 is TRC-20 borrower repay loan in TRC-20 + interest
            LoanRepaid = AssetTransferFrom(msg.sender, address(this), theLoan.CreditAssetID, CreditAssetVallueToRepay);
        }
        if (LoanRepaid){
            if (assetList[theLoan.SecuredAssetID].Type == 0) { // if assset == 0 borrower must get back secured TRX
                address(msg.sender).transfer(theLoan.SecuredAssetValue);
                LoanSecuritySentBack = true;
            } else if (assetList[theLoan.SecuredAssetID].Type == 1) { // if assset == 1 is TRC-20 borrower must get back secured TRC-20
                LoanSecuritySentBack = AssetTransferTo(msg.sender, theLoan.SecuredAssetID, theLoan.SecuredAssetValue);
            }
        }
        require(LoanRepaid && LoanSecuritySentBack);
        Loans[LoanID].CreditAssetRepaidValue = CreditAssetVallueToRepay;
        Loans[LoanID].Status.isPaid = true;
        // emit BorrowerRepayCredit(theLoan.Creditor, msg.sender, LoanID);
    }
    // Get loan repayment details by LoanID
    function getRepaySumCalc(uint256 StartBlock, uint256 PeriodBlocks, uint256 LoanPercentbyPeriod, uint256 LoanValue) public view returns(uint256){
        return (LoanValue + LoanValue * (((block.number - StartBlock + PeriodBlocks) - 1) / PeriodBlocks) * LoanPercentbyPeriod / 10000);
    }
    // calculations from credit the profit commission and the rest 
    function getFeeRestCalc(uint256 FirstSum, uint256 RepaymentSum, uint256 Percent) public pure returns(uint256, uint256){
        if (RepaymentSum == 0)
            return (FirstSum * Percent / 10000, FirstSum - FirstSum * Percent / 10000);
        else
            return ((RepaymentSum - FirstSum) * Percent / 10000, RepaymentSum - (RepaymentSum - FirstSum) * Percent / 10000);
    }
    // Get loan info by LoanID: assets, status
    function getLoanByID(uint256 LoanID) public view returns(uint256, uint256, uint256, uint256, bool, bool, bool, bool){
        LoanInfo memory Loan = Loans[LoanID];        
        return(Loan.CreditAssetID, Loan.CreditAssetValue, Loan.SecuredAssetID, Loan.SecuredAssetValue, Loan.Status.isOpened, Loan.Status.isAccepted, Loan.Status.isPaid, Loan.Status.isClosed);
    }
    // Get loan info by LoanID #2: blocks amount to repay, 
    function getLoanByID2(uint256 LoanID) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool, bool){
        LoanInfo memory Loan = Loans[LoanID];
        uint256 SumRepay = 0;
        if (Loan.Status.isOpened && Loan.Status.isAccepted && !Loan.Status.isPaid && !Loan.Status.isClosed){
            SumRepay = getRepaySumCalc(Loan.StartBlock, Loan.PeriodBlocks, Loan.LoanPercentbyPeriod, Loan.CreditAssetValue);
        }
        return(Loan.StartBlock, Loan.LoanPercentbyPeriod, Loan.PeriodBlocks, Loan.LiveTimeBlocks, Loan.AssetFee, Loan.SecuredAssetFee, SumRepay, 
            (Loan.Creditor == address(0x0)), (Loan.Borrower == address(0x0)));
    }
    // Send multitype asset to address
    function SendAsset(uint256 AssetID, uint256 AssetValue, address ToAddress) private {
        address _token;
        if (assetList[AssetID].Type == 1) { // if assset == 1 is TRC-20
            _token = GetAsset2(AssetID);
            require(_token != address(0x0));
            TRC20(_token).transfer(ToAddress, AssetValue);
        }
    }
    // Close credit
    function CloseCredit(uint256 LoanID) public payable{
        LoanInfo memory theLoan = Loans[LoanID];
        require(!theLoan.Status.isClosed);
        // Only creditor or borrower
        require(theLoan.Borrower == msg.sender || theLoan.Creditor == msg.sender);
        uint256 _Fee;
        uint256 _Rest;
        // 1) asset->Creditor  secured->Borrower - in ideal case when credit accepted and paid, fee will charged from asset, creditor and borrower can close
        // 2) asset->Creditor  secured->Creditor - in not good case when credit accepted and not paid and overdue, fee will charged from secured, only creditor close
        // 3) asset->Creditor no secured         - credit not accepted - not working, no fee charged, only creditor close
        // 4) no asset        secured->Borrower  - loan created by borrower, not accepted only borrower close
        if (theLoan.Status.isOpened && theLoan.Status.isAccepted && theLoan.Status.isPaid) { // Case #1
            // Access: Creditor | Borrower
            // asset    -> Creditor
            (_Fee, _Rest) = getFeeRestCalc(theLoan.CreditAssetValue, theLoan.CreditAssetRepaidValue, theLoan.AssetFee);
            if (assetList[theLoan.CreditAssetID].Type == 0) {address(uint160(theLoan.Creditor)).transfer(_Rest);} else {
                SendAsset(theLoan.CreditAssetID, _Rest, theLoan.Creditor);}
            // secured  -> Borrower
            //if (assetList[theLoan.SecuredAssetID].Type == 0) {address(theLoan.Borrower).transfer(theLoan.SecuredAssetValue);} else {
            //    SendAsset(theLoan.SecuredAssetID, theLoan.SecuredAssetValue, theLoan.Borrower);}
            theLoan.Status.isClosed = true;
            //emit CreditClosed(theLoan.Creditor, theLoan.Borrower, LoanID);
            return;
        }
        if (theLoan.Status.isOpened && theLoan.Status.isAccepted && !theLoan.Status.isPaid && (block.number > (theLoan.StartBlock + theLoan.LiveTimeBlocks))) { // Case #2
            // Access: Creditor
            require(theLoan.Creditor == msg.sender);
            // asset    -> Creditor            
            SendAsset(theLoan.CreditAssetID, theLoan.CreditAssetValue, theLoan.Creditor);
            // secured  -> Creditor            
            (_Fee, _Rest) = getFeeRestCalc(theLoan.SecuredAssetValue, 0, theLoan.SecuredAssetFee);
            SendAsset(theLoan.SecuredAssetID, theLoan.SecuredAssetValue, theLoan.Creditor);
            theLoan.Status.isClosed = true;
            //emit CreditClosed(theLoan.Creditor, theLoan.Borrower, LoanID);
            return;
        }
        if (theLoan.Status.isOpened && !theLoan.Status.isAccepted) { // Case #3, #4
            // Access: only creator can close, Creditor | Borrower
            if (theLoan.Creditor == msg.sender) {
                // asset    -> Creditor by Creditor
                SendAsset(theLoan.CreditAssetID, theLoan.CreditAssetValue, theLoan.Creditor);
            }
            if (theLoan.Borrower == msg.sender) {
                // secured  -> Borrower by Borrower
                SendAsset(theLoan.SecuredAssetID, theLoan.SecuredAssetValue, theLoan.Borrower);
            }
            theLoan.Status.isClosed = true;
            //emit CreditClosed(theLoan.Creditor, theLoan.Borrower, LoanID);
            return;
        }
    }
}
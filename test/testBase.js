var loanTRON      = artifacts.require("./loanTRON.sol");
var tokenANTE     = artifacts.require("./ANTE.sol");
var token888      = artifacts.require("./Token888.sol");
var tokenTWX      = artifacts.require("./TWX.sol");


contract('Test #1 loanTRON test', async (accounts) => {
  it("initiate", async () => {
    function timeout(ms) {return new Promise(resolve => setTimeout(resolve, ms));}
    let ownerAddress    = accounts[0];
    let oracleAddress   = accounts[1];
    let instanceloanTRON  = await loanTRON.deployed();
    await instanceloanTRON.setOracle(oracleAddress);

    let instanceANTE  = await tokenANTE.deployed();
    let instance888   = await token888.deployed();
    let instancTWX    = await tokenTWX.deployed();

    //const _resANTEniitial = await instanceANTE.transfer(ownerAddress, 100*10**6, {from: ownerAddress});
    // ownerAddress has all ANTE ballance 
    {      
      test_name = "ANTE transfer check ";
      const _ANTEbalance = await instanceANTE.balanceOf(ownerAddress);
      assert.equal(_ANTEbalance, 100000*10**6, test_name + ' _ANTEbalance=' + _ANTEbalance);
    }

    const returnedOracle = await instanceloanTRON.oracle();{
      test_name = "oracle address check ";
      assert.equal(returnedOracle, tronWeb.address.toHex(oracleAddress), test_name + ' returnedOracle ' + returnedOracle + ' oracleAddress ' + tronWeb.address.toHex(oracleAddress /*base58 to hex*/) );
    };

    const testDepo = 500*10**6;         //{from: accounts[0], callValue: 20*10**6}
    await instanceloanTRON.DepositeTRX({from: ownerAddress, callValue: testDepo});
    await timeout(8000);
    const _trxAvailable = await instanceloanTRON.trxAvailable();{
      test_name = "Deposite TRX ";
      assert.equal(testDepo, _trxAvailable, test_name + ' testDepo ' + testDepo + ' _trxAvailable ' + _trxAvailable);
    };

    const _assetPrice = 5*10**5;
    //let _token_address = '0x0000000000000000000000000000000000000000';//tronWeb.address.fromHex("0x0");
    let _token_address = instanceANTE.address;//tronWeb.address.fromHex(instanceANTE.address);
    await instanceloanTRON.setAsset(1, 0, 'ANTE', 6, true, _token_address);
    await timeout(8000);
    await instanceloanTRON.actuateAsset(1, _assetPrice, {from: oracleAddress});
    await timeout(8000);
    const _resAsset  = await instanceloanTRON.GetAsset(1);
    const _resAsset2 = await instanceloanTRON.GetAsset2(1);{
      test_name = "Set and get asset";
      assert.equal(_resAsset[0], 1,           test_name + ' ' + _resAsset);
      assert.equal(_resAsset[1], 0,           test_name + ' ' + _resAsset);
      assert.equal(_resAsset[2], 'ANTE',      test_name + ' ' + _resAsset);
      assert.equal(_resAsset[3], 6,           test_name + ' ' + _resAsset);
      assert.equal(_resAsset[4], true,        test_name + ' ' + _resAsset);
      assert.equal(_resAsset[5], _assetPrice, test_name + ' ' + _resAsset);
      assert.equal(_resAsset2, _token_address,test_name + ' ' + _resAsset2);
    };

    const assetAmount = await instanceloanTRON.getAssetAbility(1);{    
    const assetCalc   = testDepo / _assetPrice
      test_name = "get asset ability";
      assert.equal(assetAmount, assetCalc, test_name + ' assetAmount ' + assetAmount);
    };    

    // Get loan for 20 ANTE, ANTE price is 0.5 TRX, so we can get 20*0.5=10TRX loan
    let pledgeAssets     = 20;
    let LoanTRX          = 10*10**6;    
    const _resLoan = await instanceloanTRON.startLoan(1, pledgeAssets, LoanTRX);{
      await timeout(8000);
      test_name = "start Loan _resLoan " + _resLoan;
      let _myLoanscount = await instanceloanTRON.getMyLoansCount();
      assert.equal(_myLoanscount, 1, test_name + ' ' + _myLoanscount);

      const _myLoan = await instanceloanTRON.getMyLoanByID(_myLoanscount-1);
      test_name = "get Loan by ID loans=" + _myLoanscount;
      let firstLoanBlockNumber = parseInt(_myLoan[4]);
      assert.equal(1, _myLoanscount, test_name + ' _myLoanscount ' + _myLoanscount);
      assert.equal(_myLoan[0], 1, test_name);
      assert.equal(_myLoan[1], pledgeAssets, test_name + ' ' + _myLoan[1]);
      assert.equal(_myLoan[2], LoanTRX, test_name + ' ' + _myLoan[2]);      
      assert.equal(_myLoan[3], _assetPrice, test_name);
      assert.isAbove(firstLoanBlockNumber, 0, test_name + ' _myLoan[4]='+ _myLoan[4] + ' firstLoanBlockNumber=' + firstLoanBlockNumber);
      assert.equal(_myLoan[5], false, test_name);         

      pledgeAssets     = 40;
      LoanTRX          = 20*10**6;      
      const _resLoan2 = await instanceloanTRON.startLoan(1, pledgeAssets, LoanTRX);
      await timeout(8000);
      test_name = "start 2nd Loan";
      _myLoanscount = await instanceloanTRON.getMyLoansCount();
      assert.equal(_myLoanscount, 2, test_name + ' ' + _resLoan2); 

      const _myLoan2 = await instanceloanTRON.getMyLoanByID(_myLoanscount-1);
      test_name = "get Loan by ID, part 2 loans=" + _myLoanscount + ' _resLoan2 ' + _resLoan2;
      let SecondLoanBlockNumber = parseInt(_myLoan2[4]);
      assert.equal(2, _myLoanscount, test_name + ' _myLoanscount ' + _myLoanscount);
      assert.equal(_myLoan2[0], 1, test_name);
      assert.equal(_myLoan2[1], pledgeAssets, test_name + ' ' + _myLoan2[1]);
      assert.equal(_myLoan2[2], LoanTRX, test_name + ' ' + _myLoan2[2]);
      assert.equal(_myLoan2[3], _assetPrice, test_name);
      assert.isAbove(SecondLoanBlockNumber, 0, test_name + ' _myLoan2[4]='+ _myLoan2[4] + ' secondLoanBlockNumber=' + SecondLoanBlockNumber);
      assert.equal(_myLoan2[5], false, test_name);

      // wait for 30 sec for blocks amount
      await timeout(30000);
            
      test_name = "get Loan by ID2, part 2 loans=" + _myLoanscount + ' _resLoan2 ' + _resLoan2;
      const _myLoan21 = await instanceloanTRON.getMyLoanByID2(_myLoanscount-1);      
      assert.equal(_myLoan21[0], 15, test_name);
      assert.equal(_myLoan21[1], 10, test_name + ' #1 ' + _myLoan21[1]);
      assert.equal(_myLoan21[2], 15*2, test_name + ' #2=' + _myLoan21[2]);
      assert.equal(_myLoan21[3], LoanTRX + (LoanTRX * 15*2 / 1000), test_name + ' #3 ' + _myLoan21[3]);      

      test_name = "Repay";
      const _resRepay = await instanceloanTRON.ILoanRepay(_myLoanscount-1, {callValue: LoanTRX + (LoanTRX * 15*2 / 1000)});
      await timeout(8000);
      const _myLoanAfterRepay = await instanceloanTRON.getMyLoanByID(_myLoanscount-1);
      await timeout(8000);      
      assert.equal(_myLoanAfterRepay[5], true, test_name + ' _resRepay ' + _resRepay);    

      test_name = "get count of loans on some block";
      const _resFirstLoansCount  = parseInt(await instanceloanTRON.getBlockLoansCount(firstLoanBlockNumber,  {from: oracleAddress}), 10);
      const _resSecondLoansCount = parseInt(await instanceloanTRON.getBlockLoansCount(SecondLoanBlockNumber, {from: oracleAddress}), 10);
      let firstAddress = await instanceloanTRON.getAddrByBlockLoanNum(firstLoanBlockNumber,  _resFirstLoansCount-1,  {from: oracleAddress});
      let secondAddress= await instanceloanTRON.getAddrByBlockLoanNum(SecondLoanBlockNumber, _resSecondLoansCount-1, {from: oracleAddress});

      //assert.isAbove(parseInt(_resFirstLoansCount, 10), 0, test_name + ' first: (parseInt(_resFirstLoansCount, 10)' + parseInt(_resFirstLoansCount, 10) + ' firstLoanBlockNumber:' + firstLoanBlockNumber);
      assert.isAbove(_resFirstLoansCount, 0, test_name + ' first:' + _resFirstLoansCount + ' firstLoanBlockNumber:' + firstLoanBlockNumber);
      assert.isAbove(_resSecondLoansCount, 0, test_name + ' second:' + _resSecondLoansCount);
      assert.equal(tronWeb.address.toHex(firstAddress), tronWeb.address.toHex(secondAddress), test_name + ' firstAddress:' + tronWeb.address.toHex(firstAddress) + ' secondAddress:' + tronWeb.address.toHex(secondAddress));
      

      test_name = "get loan info for first address";
      let _loanfirst = await instanceloanTRON.getLoanByID(0, tronWeb.address.toHex(firstAddress));      
      assert.equal(_loanfirst[0], 1, test_name);
      assert.equal(_loanfirst[1], 20, test_name + ' ' + _loanfirst[1]);
      assert.equal(_loanfirst[2], 10*10**6, test_name + ' ' + _loanfirst[2]);
      assert.equal(_loanfirst[3], _assetPrice, test_name);
      //assert.isAbove(firstLoanBlockNumber, 0, test_name + ' _myLoan[4]='+ _myLoan[4] + ' firstLoanBlockNumber=' + firstLoanBlockNumber);
      assert.equal(_loanfirst[5], false, test_name);    

      test_name = "get loan info for second address"; {
        let _loansecond = await instanceloanTRON.getLoanByID(1, tronWeb.address.toHex(secondAddress));
        assert.equal(_loansecond[0], 1, test_name);
        assert.equal(_loansecond[1], 40, test_name + ' ' + _loansecond[1]);
        assert.equal(_loansecond[2], 20*10**6, test_name + ' ' + _loansecond[2]);
        assert.equal(_loansecond[3], _assetPrice, test_name);
        //assert.isAbove(firstLoanBlockNumber, 0, test_name + ' _myLoan[4]='+ _myLoan[4] + ' firstLoanBlockNumber=' + firstLoanBlockNumber);
        assert.equal(_loansecond[5], true, test_name); // second loan is already closed by account
      }

      let _firstLoanDetails = await instanceloanTRON.getLoanByID2(0, tronWeb.address.toHex(firstAddress));

      //OracleLoanRepay(uint256 i, address addressBorrower)
      test_name = "repay and close first loan from oracle account";{
        const _repayResult = await instanceloanTRON.OracleLoanRepay(0, tronWeb.address.toHex(firstAddress), 
          {callValue: _firstLoanDetails[3], from: oracleAddress});
        await timeout(8000);
        _loanfirst = await instanceloanTRON.getLoanByID(0, tronWeb.address.toHex(firstAddress));
        assert.equal(_loanfirst[5], true, test_name + ' ' + _repayResult);
      }
    }
  });
});
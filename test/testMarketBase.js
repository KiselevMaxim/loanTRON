var loanMarket = artifacts.require("./loanMarket.sol");
var tokenANTE = artifacts.require("./ANTE.sol");
var tokenUSDT = artifacts.require("./USDT.sol");

contract('Test #1 loanMarket test', async(accounts) => {
    it("initiate", async() => {
        function timeout(ms) { return new Promise(resolve => setTimeout(resolve, ms)); }
        let ownerAddress = accounts[0];
        let oracleAddress = accounts[1];
        let Alice = accounts[2];
        let Bob = accounts[3];
        let Carol = accounts[4];
        let instanceloanMarket = await loanMarket.deployed();
        await instanceloanMarket.setOracle(oracleAddress);

        let instanceANTE = await tokenANTE.deployed();
        let instanceUSDT = await tokenUSDT.deployed();


        //const _resANTEniitial = await instanceANTE.transfer(ownerAddress, 100*10**6, {from: ownerAddress});
        // ownerAddress has all ANTE ballance 
        {
            test_name = "ANTE transfer check ";
            const _ANTEbalance = await instanceANTE.balanceOf(ownerAddress);
            assert.equal(_ANTEbalance, 100000 * 10 ** 6, test_name + ' _ANTEbalance=' + _ANTEbalance);
        }

        {
            test_name = "USDT transfer check ";
            const _USDTbalance = await instanceUSDT.balanceOf(ownerAddress);
            assert.equal(_USDTbalance, 100000 * 10 ** 6, test_name + ' _ANTEbalance=' + _USDTbalance);
        }

        const _USDTValue = 25 * 10 ** 6;
        await instanceUSDT.transfer(Bob, _USDTValue, { from: ownerAddress }); // Send Bob 25 USDT
        await instanceUSDT.approve(instanceloanMarket.address, _USDTValue, { from: Bob });

        const returnedOracle = await instanceloanMarket.oracle(); {
            test_name = "oracle address check ";
            assert.equal(returnedOracle, tronWeb.address.toHex(oracleAddress), test_name + ' returnedOracle ' + returnedOracle + ' oracleAddress ' + tronWeb.address.toHex(oracleAddress /*base58 to hex*/ ));
        };

        const testDepo = 500 * 10 ** 6; //{from: accounts[0], callValue: 20*10**6}
        await instanceloanMarket.DepositeTRX({ from: ownerAddress, callValue: testDepo });
        await timeout(8000);
        //const _trxAvailable = await instanceloanMarket.trxProfit();
        {
            const _trxAvailable = await instanceloanMarket.GetUserAssetValue(0);
            test_name = "Deposite TRX ";
            assert.equal(testDepo, _trxAvailable, test_name + ' testDepo=' + testDepo + ' _trxAvailable=' + _trxAvailable);
        };

        let _ownerTRXBefore = await tronWeb.trx.getBalance(Carol);
        let _res1 = await instanceloanMarket.WithdrawTRX(Carol, { from: ownerAddress, callValue: 1 * 10 ** 6 });
        await timeout(20000);
        let _ownerTRXAfter = await tronWeb.trx.getBalance(Carol); {
            test_name = "Withdraw TRX ";
            assert.isAbove(_ownerTRXAfter, _ownerTRXBefore, test_name + ' _ownerTRXAfter=' + _ownerTRXAfter + ' _ownerTRXBefore=' + _ownerTRXBefore + ' _res1 = ' + _res1);
        };

        //let _token_address = '0x0000000000000000000000000000000000000000';//tronWeb.address.fromHex("0x0");
        let _token_address = instanceANTE.address; /*tronWeb.address.fromHex(instanceANTE.address);*/
        let _USDT_token_address = instanceUSDT.address;
        // Sent asset type TRC-20 ANTE
        await instanceloanMarket.setAsset(1, 0, 'ANTE', 6, true, _token_address);
        await instanceloanMarket.setAsset(1, 0, 'USDT', 6, true, _USDT_token_address);

        const testDepoANTE = 500 * 10 ** 6;
        await instanceANTE.approve(instanceloanMarket.address, testDepoANTE);
        await timeout(8000);
        let ANTE_id = await Number(await instanceloanMarket.GetAssetIDbyName('ANTE'));
        let TRX_id = await Number(await instanceloanMarket.GetAssetIDbyName('TRX'));
        let USDT_id = await Number(await instanceloanMarket.GetAssetIDbyName('USDT'));
        //USDT_id = Number(USDT_id);
        const _resAsset = await instanceloanMarket.GetAsset(Number(ANTE_id));
        const _resAsset2 = await instanceloanMarket.GetAsset2(1); {
            test_name = "Set and get asset";
            assert.equal(_resAsset[0], 1, test_name + ' ' + _resAsset);
            assert.equal(_resAsset[1], 0, test_name + ' ' + _resAsset);
            assert.equal(_resAsset[2], 'ANTE', test_name + ' ' + _resAsset);
            assert.equal(_resAsset[3], 6, test_name + ' ' + _resAsset);
            assert.equal(_resAsset[4], true, test_name + ' ' + _resAsset);
            assert.equal(_resAsset2, _token_address, test_name + ' ' + _resAsset2);
            assert.equal(TRX_id, 0, test_name + ' TRX_id=' + TRX_id);
            assert.equal(ANTE_id, 1, test_name + ' ANTE_id=' + ANTE_id);
            assert.equal(USDT_id, 2, test_name + ' USDT_id=' + USDT_id);
        };

        // DepositeTRC20 test
        await instanceloanMarket.DepositeTRC20(1, testDepoANTE, { from: ownerAddress });
        await timeout(7000); {
            const _ANTEAvailable = await instanceloanMarket.GetUserAssetValue(1, { from: ownerAddress });
            test_name = "Deposite ANTE ";
            assert.equal(testDepoANTE, _ANTEAvailable, test_name + ' testDepoANTE=' + testDepoANTE + ' _ANTEAvailable=' + _ANTEAvailable);
        };

        // WithdrawTRC20 test
        await instanceloanMarket.WithdrawTRC20(1, testDepoANTE, { from: ownerAddress });
        await timeout(7000); {
            const _ANTEAvailable = await instanceloanMarket.GetUserAssetValue(1, { from: ownerAddress });
            test_name = "Withdraw ANTE ";
            assert.equal(0, _ANTEAvailable, test_name + ' testDepoANTE=' + testDepoANTE + ' _ANTEAvailable=' + _ANTEAvailable);
        };

        // create loan proposal for 1000 TRX for 25 USDT
        const _TRXValue = 1000 * 10 ** 6;
        const _LoanPercentbyPeriod = 100; //1% is value 100
        const _PeriodBlocks = 1200; // 1 hour is 1200 blocks (3sec/block)
        const _LiveTimeBlocks = 4800; // 4 hours * 1200 blocks = 4800 blocks
        let _TRXBalBefore = await tronWeb.trx.getBalance(Alice);
        let _TRXBalBeforeContract = await tronWeb.trx.getBalance(instanceloanMarket.address);
        const resLoan = await instanceloanMarket.ProposeLoan(TRX_id, _TRXValue, USDT_id, _USDTValue, _LoanPercentbyPeriod, _PeriodBlocks, _LiveTimeBlocks, { from: Alice, callValue: _TRXValue });
        await timeout(12000); // curuiose to update trx ballance after solidity update need more time...
        const totalLoans = await instanceloanMarket.getTotalLoansCount();
        let _TRXBalAfter = await tronWeb.trx.getBalance(Alice);
        let _TRXBalAfterContract = await tronWeb.trx.getBalance(instanceloanMarket.address);
        let CreditorLoans = await instanceloanMarket.getCreditorTotalLoansCount({ from: Alice });
        let _TRX_USDTloanID = await instanceloanMarket.getCreditorLoanIDBynumber(CreditorLoans - 1, { from: Alice });
        let TRXUSDloans = await instanceloanMarket.CreditSecuredAssetsNumber(TRX_id, USDT_id);
        let _TRX_USDTloanID_1 = await instanceloanMarket.CreditSecuredAssetIDbyNumber(TRX_id, USDT_id, TRXUSDloans - 1);
        let propose_loan_info_res2 = await instanceloanMarket.getLoanByID2(Number(_TRX_USDTloanID));
        test_name = "Create loan";
        let _TRXdif = _TRXBalBefore - _TRXBalAfter;
        let _TRXContractdif = _TRXBalAfterContract - _TRXBalBeforeContract;
        assert.equal(1,        totalLoans,       test_name + ' totalLoans=' + totalLoans);
        assert.equal(CreditorLoans,     1,       test_name + ' CreditorLoans=' + CreditorLoans);
        assert.isAbove(_TRXdif, _TRXValue,       test_name + ' _TRXdif=' + _TRXdif + ' _TRXBalBefore=' + _TRXBalBefore + ' _TRXBalAfter=' + _TRXBalAfter);
        assert.equal(_TRXValue, _TRXContractdif, test_name + ' _TRXContractdif=' + _TRXContractdif + ' _TRXBalBeforeContract=' + _TRXBalBeforeContract + ' _TRXBalAfterContract=' + _TRXBalAfterContract);
        assert.equal(_TRX_USDTloanID,   0,       test_name + ' _TRX_USDTloanID=' + _TRX_USDTloanID);
        assert.equal(TRXUSDloans,       1,       test_name + ' TRXUSDloans=' + TRXUSDloans);
        assert.equal(_TRX_USDTloanID_1, 0,       test_name + ' _TRX_USDTloanID_1=' + _TRX_USDTloanID_1);
        assert.equal(propose_loan_info_res2[7], false, test_name + ' propose_loan_info_res2[7]=' + propose_loan_info_res2[7]); // have creditor
        assert.equal(propose_loan_info_res2[8], true,  test_name + ' propose_loan_info_res2[8]=' + propose_loan_info_res2[8]); // no borrower


        // borrowerTakesLoan test, scenario Bob have 25 USD and takes TRX loan secured USDT
        let _BobUSDTBefore = await instanceUSDT.balanceOf(Bob);
        let _BobTRXBefore = await tronWeb.trx.getBalance(Bob);
        _TRXBalBeforeContract = await tronWeb.trx.getBalance(instanceloanMarket.address);
        //await timeout(12000);
        let borrow_res = await instanceloanMarket.borrowerTakesLoan(_TRX_USDTloanID, { from: Bob })
        await timeout(20000);
        let _BobUSDTAfter = await instanceUSDT.balanceOf(Bob);
        let _BobTRXAfter = await tronWeb.trx.getBalance(Bob);
        _TRXBalAfterContract = await tronWeb.trx.getBalance(instanceloanMarket.address);
        test_name = "borrowerTakesLoan: Bob takes 1000TRX secured 25USDT";
        _TRXdif = Math.abs(_BobTRXBefore - _BobTRXAfter);
        _USDTdif = Math.abs(_BobUSDTBefore - _BobUSDTAfter);
        _TRXContractdif = _TRXBalBeforeContract - _TRXBalAfterContract;
        assert.equal(_TRXContractdif, _TRXValue, test_name + ' _TRXContractdif=' + _TRXContractdif + ' _TRXBalBeforeContract=' + _TRXBalBeforeContract + ' _TRXBalAfterContract=' + _TRXBalAfterContract + ' borrow_res= ' + borrow_res);
        assert.isAbove(_TRXdif, _TRXValue - 10 * 10 ** 6, test_name + ' _TRXdif=' + _TRXdif + ' borrow_res= ' + borrow_res + ' _BobTRXBefore=' + _BobTRXBefore + ' _BobTRXAfter=' + _BobTRXAfter);
        assert.equal(_USDTdif, _USDTdif, test_name + ' _USDTdif=' + _USDTdif + ' borrow_res= ' + borrow_res);

        await timeout(6000);

        // get loan info by ID
        const loan_info_res = await instanceloanMarket.getLoanByID(Number(_TRX_USDTloanID));
        let loan_info_res2 = await instanceloanMarket.getLoanByID2(Number(_TRX_USDTloanID));
        test_name = "get loan info by ID";
        assert.equal(loan_info_res[0], TRX_id, test_name + ' loan_info_res[0]=' + loan_info_res[0]);
        assert.equal(loan_info_res[1], _TRXValue, test_name + ' loan_info_res[1]=' + loan_info_res[1]);
        assert.equal(loan_info_res[2], USDT_id, test_name + ' loan_info_res[2]=' + loan_info_res[2]);
        assert.equal(loan_info_res[3], _USDTValue, test_name + ' loan_info_res[3]=' + loan_info_res[3]);
        assert.equal(loan_info_res[4], true, test_name + ' loan_info_res[4]=' + loan_info_res[4]);
        assert.equal(loan_info_res[5], true, test_name + ' loan_info_res[5]=' + loan_info_res[5]);
        assert.equal(loan_info_res[6], false, test_name + ' loan_info_res[6]=' + loan_info_res[6]);
        assert.equal(loan_info_res[7], false, test_name + ' loan_info_res[7]=' + loan_info_res[7]);
        assert.equal(loan_info_res2[1], _LoanPercentbyPeriod, test_name + ' loan_info_res2[1]=' + loan_info_res2[1]);
        assert.equal(loan_info_res2[2], _PeriodBlocks, test_name + ' loan_info_res2[2]=' + loan_info_res2[2]);
        assert.equal(loan_info_res2[3], _LiveTimeBlocks, test_name + ' loan_info_res2[3]=' + loan_info_res2[3]);
        assert.equal(loan_info_res2[4], 1000, test_name + ' loan_info_res2[4]=' + loan_info_res2[4]);
        assert.equal(loan_info_res2[5], 10, test_name + ' loan_info_res2[5]=' + loan_info_res2[5]);
        assert.equal(loan_info_res2[6], 1010 * 10 ** 6, test_name + ' loan_info_res2[6]=' + loan_info_res2[6]);
        assert.equal(loan_info_res2[7], false, test_name + ' loan_info_res2[7]=' + loan_info_res2[7]);
        assert.equal(loan_info_res2[8], false, test_name + ' loan_info_res2[8]=' + loan_info_res2[8]);

        _BobUSDTBefore = await instanceUSDT.balanceOf(Bob);
        _BobTRXBefore = await tronWeb.trx.getBalance(Bob);
        let borrowerRepay_res = await instanceloanMarket.borrowerRepay(_TRX_USDTloanID, { from: Bob, callValue: loan_info_res2[6] });
        await timeout(20000);
        _BobUSDTAfter = await instanceUSDT.balanceOf(Bob);
        _BobTRXAfter = await tronWeb.trx.getBalance(Bob);
        _TRXdif = Math.abs(_BobTRXBefore - _BobTRXAfter);
        _USDTdif = Math.abs(_BobUSDTBefore - _BobUSDTAfter);
        test_name = "borrower repay loan with 1010 TRX 1000+interest";
        assert.isAbove(_TRXdif, loan_info_res2[6] - 10 * 10 ** 6, test_name + ' _TRXdif=' + _TRXdif + ' borrowerRepay_res= ' + borrowerRepay_res + ' _BobTRXBefore=' + _BobTRXBefore + ' _BobTRXAfter=' + _BobTRXAfter);
        assert.equal(_USDTdif, 25 * 10 ** 6, test_name + ' _USDTdif=' + _USDTdif + ' borrowerRepay_res= ' + borrowerRepay_res);

        await timeout(20000);

        _AliceTRXBefore = await tronWeb.trx.getBalance(Alice);
        let CloseCredit_res = await instanceloanMarket.CloseCredit(_TRX_USDTloanID, { from: Bob });
        await timeout(20000);
        _AliceTRXAfter = await tronWeb.trx.getBalance(Alice);
        _TRXdif = Math.abs(_AliceTRXAfter - _AliceTRXBefore);
        test_name = "close loan ";
        /*Alices profit 1000 + 10, 10-10%fee = 9, total 1009*/
        assert.equal(_TRXdif, 1009 * 10 ** 6, test_name + ' _TRXdif=' + _TRXdif + ' _AliceTRXBefore=' + _AliceTRXBefore + ' _AliceTRXAfter=' + _AliceTRXAfter + ' CloseCredit_res= ' + CloseCredit_res);

        // Borrower ask loan for 2000 TRX for 50 USDT
        let _TRXValueAsk = 2000 * 10 ** 6;
        let _USDTValueAsk = 50 * 10 ** 6;
        let _LoanPercentbyPeriodAsk = 100; //1% is value 100
        await instanceUSDT.transfer(Bob, _USDTValueAsk, { from: ownerAddress }); // Send Bob 50 USDT
        await instanceUSDT.approve(instanceloanMarket.address, _USDTValueAsk, { from: Bob });
        await timeout(6000);

        _BobUSDTBefore = await instanceUSDT.balanceOf(Bob);
        _ContractUSDTBefore = await instanceUSDT.balanceOf(instanceloanMarket.address);
        let resAskLoan = await instanceloanMarket.AskLoan(TRX_id, _TRXValueAsk, USDT_id, _USDTValueAsk, _LoanPercentbyPeriodAsk, _PeriodBlocks, _LiveTimeBlocks, { from: Bob });
        await timeout(12000); // curuiose to update trx ballance after solidity update need more time...        
        _ContractUSDTAfter = await instanceUSDT.balanceOf(instanceloanMarket.address);
        _BobUSDTAfter = await instanceUSDT.balanceOf(Bob);
        test_name = "Ask loan";

        let BorrowerLoans = await instanceloanMarket.getBorrowerTotalLoansCount({ from: Bob });
        _TRX_USDTloanID = await Number(await instanceloanMarket.getBorrowerLoanIDBynumber(BorrowerLoans - 1, { from: Bob }));
        TRXUSDloans = await instanceloanMarket.CreditSecuredAssetsNumber(TRX_id, USDT_id);
        _TRX_USDTloanID_1 = await Number(await instanceloanMarket.CreditSecuredAssetIDbyNumber(TRX_id, USDT_id, TRXUSDloans - 1));

        let _USDTBobdif = _BobUSDTBefore - _BobUSDTAfter;
        let _USDTContractdif = _ContractUSDTAfter - _ContractUSDTBefore;
        assert.equal(_USDTBobdif, _USDTValueAsk, test_name + ' _USDTBobdif=' + _USDTBobdif + ' _BobUSDTBefore=' + _BobUSDTBefore + ' _BobUSDTAfter=' + _BobUSDTAfter);
        assert.equal(_USDTContractdif, _USDTValueAsk, test_name + ' _USDTContractdif=' + _USDTContractdif + ' _ContractUSDTBefore=' + _ContractUSDTBefore + ' _ContractUSDTAfter=' + _ContractUSDTAfter);
        assert.equal(_TRX_USDTloanID, _TRX_USDTloanID_1, test_name + ' _TRX_USDTloanID=' + _TRX_USDTloanID + ' _TRX_USDTloanID_1=' + _TRX_USDTloanID_1);

        //CreditorGrantsLoan test, scenario Bob ask for loan 2000TRX, secured 50USDT
        _BobTRXBefore = await tronWeb.trx.getBalance(Bob);
        let creditor_grants_res = await instanceloanMarket.CreditorGrantsLoan(_TRX_USDTloanID, { from: Alice, callValue: _TRXValueAsk })
        await timeout(20000);
        _BobTRXAfter = await tronWeb.trx.getBalance(Bob);
        test_name = "CreditorGrantsLoan, Bob asks loan 2000TRX, secured 50USDT";
        _TRXdif = Math.abs(_BobTRXBefore - _BobTRXAfter);
        _TRXContractdif = _TRXBalBeforeContract - _TRXBalAfterContract;
        assert.equal(_TRXdif, _TRXValueAsk, test_name + ' _TRXdif=' + _TRXdif + ' creditor_grants_res= ' + creditor_grants_res + ' _BobTRXBefore=' + _BobTRXBefore + ' _BobTRXAfter=' + _BobTRXAfter);
    });
});
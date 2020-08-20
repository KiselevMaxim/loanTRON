const port = process.env.HOST_PORT || 9090

module.exports = {
  networks: {
    dev: {      
      privateKey: 'da146374a75310b9666e834ee4ad0866d6f4035967bfc76217c5a495fff9f0d0',
      fullHost: "http://127.0.0.1:9090",
      network_id: "9",
      feeLimit: 1e9,  // Set fee limit
      originEnergyLimit: 1e7
    },
    mainnet: {
      // Don't put your private key here:
      privateKey: process.env.PRIVATE_KEY_MAINNET,
      /*
Create a .env file (it must be gitignored) containing something like

  export PRIVATE_KEY_MAINNET=4E7FECCB71207B867C495B51A9758B104B1D4422088A87F4978BE64636656243

Then, run the migration with:

  source .env && tronbox migrate --network mainnet

*/
      userFeePercentage: 100,
      feeLimit: 1e8,
      fullHost: "https://api.trongrid.io",
      network_id: "1"
    },
    shasta: {
      privateKey: '15E154EC644A8E59FE343D6B72AA92CFA0951BB78810ECBE9536EBF50352BE75', /*TPHRh8Lca8FBRMqaFnBd5SSYiq39RtqS2R*/ /* process.env.PRIVATE_KEY_SHASTA, */
      userFeePercentage: 100,
      feeLimit: 1e9,  // Set fee limit
      originEnergyLimit: 1e7,
      fullHost: "https://api.shasta.trongrid.io",
      /* fullNode: "https://api.shasta.trongrid.io",
      solidityNode: "https://api.shasta.trongrid.io",
      eventServer: "https://api.shasta.trongrid.io", */
      network_id: "*"
    },
    development: {
      // For trontools/quickstart docker image
      privateKey: 'da146374a75310b9666e834ee4ad0866d6f4035967bfc76217c5a495fff9f0d0',
      userFeePercentage: 50,
      feeLimit: 1e9,
      fullHost: 'http://127.0.0.1:' + port,
      network_id: "9"
    },
    compilers: {
      solc: {
        version: '0.5.4'
      }
    }

  }
}

/*
*************** SHASTA deployed ********************

Using network 'shasta'.

Running migration: 1_initial_migration.js
  Replacing Migrations...
  Migrations:
    (base58) TGkPVMADffGB5dMSpTaCbyQUAanjscW6Bz
    (hex) 414a5c3a4b7cbf2d8b30a081eab61ddab245ac93fc
Saving successful migration to network...
Saving artifacts...
Running migration: 2_deploy_contracts.js
  Deploying loanMarket...
  loanMarket:
    (base58) TPD59nGQAJ6JbZgV4QKg6PV6H9SkuRxTY8
    (hex) 419138e7f7c647da6e78f8927b087e0c6fdd145b63
  Replacing ANTE...
  ANTE:
    (base58) TUk4LM595RbpLi97RcpLxCXXtNoqxtk69Q
    (hex) 41cdedbf4638fd3ede0b484fa04515f87ab3c8ff59
  Deploying TWX...
  TWX:
    (base58) TLtWam9wwpVUdrAyeWK9acpbmyFW4wk3Qx
    (hex) 4177c5fad1ecd48a757268a41ba492dffe35799fdb
  Deploying Token888...
  Token888:
    (base58) TCkvkEYVpupVJtD4pnBcDPXyzXjyEjRJPW
    (hex) 411e95d0fa5995b6408fc4ff2c7edfd562c3f41f6e
  Deploying USDT...
  USDT:
    (base58) TDZseKm9NyKSVNZTd8yWWTsmhFXUb4DMSi
    (hex) 412776c6f5fa0d7c85671e581dcaec754c2acb2d1f
Saving successful migration to network...
Saving artifacts...

*************************************************************************
************************ SHASTA 2nd attempt *****************************
*************************************************************************

Running migration: 1_initial_migration.js
  Replacing Migrations...
  Migrations:
    (base58) TTx7mdCYTBNEuN5E9c6BbXqDzRbtGvYBX3
    (hex) 41c53d7b235c0214db48e91ccf35c616bfeb15e59a
Saving successful migration to network...
Saving artifacts...
Running migration: 2_deploy_contracts.js
  Replacing loanMarket...
  loanMarket:
    (base58) TABdtVcLXT7kTRUa5J3kecrbmM8vQ5JwnN
    (hex) 410259c418f335157443feaf7b43c8e1dc42c9998b
  Replacing ANTE...
  ANTE:
    (base58) TCNcUPqxtJDYRsxLd3Zz6Covnxk46bXLkp
    (hex) 411a5d695b2a6dadb9fbb335ab7546ac4578a49a4b
  Replacing TWX...
  TWX:
    (base58) TLzShPz6XZXGyfEyxcfvtgHVnHTS1yzso1
    (hex) 4178e53b6439862225669f2d56f7ed5e94be837255
  Replacing Token888...
  Token888:
    (base58) TKvn82576t1hAxDZNyJJcHdtyTckwVttL5
    (hex) 416d3ba83a55c0d6104d2f04bf84028d750cd187c2
  Replacing USDT...
  USDT:
    (base58) THyoJUhrDR4i2e8sjoEyDmkh6ahvGAoWiJ
    (hex) 4157dda38507e26061f1e4d06adbb8e8f5ef1a4b82
Saving successful migration to network...
Saving artifacts...

*************************************************************************
************************ SHASTA 3d attempt ******************************
*************************************************************************

Running migration: 1_initial_migration.js
  Deploying Migrations...
  Migrations:
    (base58) TSzJh2qksEjrGFMCUmmEEqDYTtmUSvtFrd
    (hex) 41baaf4daafce3974873bf5723f8f0c1a1858f9a4d
Saving successful migration to network...
Saving artifacts...
Running migration: 2_deploy_contracts.js
  Deploying loanMarket...
  loanMarket:
    (base58) TQpvEo6zJDaXgYwfqfDzCsBXz5BQYNksyB
    (hex) 41a2f890dd905829e661ccc59728664cf95b1b953d
  Deploying ANTE...
  ANTE:
    (base58) TBwieFohp5e32ZjE8NPwQ5DuJnNYthHDre
    (hex) 4115a829b9036ef454ed3dff4d4032db8163caa4b9
  Deploying TWX...
  TWX:
    (base58) THUzF5abMUrc4VXdrdzDdp5K6dZGbSCftN
    (hex) 41526ab5934c183c7bd53b8966dfca0ba84359b7bf
  Deploying Token888...
  Token888:
    (base58) THgMPzVq73Vg2DEbYttWHMeVXtEdWG7Xfo
    (hex) 415490f16b76bad1a1a5c3d4dd3fb45aaad6641de9
  Deploying USDT...
  USDT:
    (base58) TB5ayn3AbfNqNHcZMsDUq97sVdcpT33xWV
    (hex) 410c2cf7c0a56073a1bcdc4cc3341287c51f9c4289
Saving successful migration to network...
Saving artifacts...


*/
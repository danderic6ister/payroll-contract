const EmployeePaymentToken = artifacts.require('EmployeePaymentToken');
const Payroll = artifacts.require('Payroll');

module.exports = async function (deployer) {

  console.log("About to deploy the  token's contract");
  await deployer.deploy(EmployeePaymentToken);
  
  console.log("Token's contract deployed successfully");
  const tokenContract = await EmployeePaymentToken.deployed();
  let tokenCA = tokenContract.address;
  console.log("The contract address of the token is:",tokenCA)
  return deployer.deploy(Payroll, tokenCA);
  
};

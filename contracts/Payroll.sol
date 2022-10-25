// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Payroll is Ownable{
    /// bytes32 private merklerootOfEmployees ;
    address public _owner;
    uint256 public salaryWaitWindow = 30 seconds;
   IERC20 public employeePaymentToken;

   constructor(address _paymentTokenAddress){
    employeePaymentToken = IERC20(_paymentTokenAddress);
    _owner = msg.sender;
   

   }

    struct NewEmployee{
        address employee;
        string name;
        uint256 age;
        uint256 salaryAmount;
        // bool hasInteractedWithSalary;
        uint256 timeOfEmployment;
        // uint256 estimatedtimeOfSalary;
        // bool    receivedFullPayment;
        mapping(address => uint256) balance;
        uint256 EmissionRatePerMinute;
        mapping(address => uint256) employeeWithdrawalTime;
        mapping(address => bool) claimedPaymentAtAnyTime;
        mapping(address => bool) isEmployeeOnLeave;
        mapping(address => uint256) balanceBeforeLeave;
        uint256 timeOfLeaveRequest;
        uint256 timeOfLeaveResumption;
        bool hasBeenOnLeave;
    }
     uint256 public employed;
    //  mapping(uint256 =>NewEmployee) employedWorkers;
    
    mapping(address => NewEmployee) public employeeRecord;
    mapping(address => bool) public isEmployed;

    event NewEmployeeAdded(address indexed _employee,uint256 _timeOfEmployment);
    event RemovedEmployee(address indexed _exEmployee,uint256 _timeOfRemoval);
    event SalaryChanged(address indexed _employee,uint256 oldSalary, uint256 newSalary, uint256 _timeOfUpdate);

    event ClaimedSalary(address indexed,uint256 _amountClaimed,uint256 _timeOfClaim);
    event severanceFeePaid(address indexed _employee,uint256 _amountPaid,uint256 _timeOfSeverance);

    event EmployeeLeaveRequest(address indexed , uint256 _timeOfLeave);
    event EmployeeResumeLeave(address indexed, uint256 _durationOfLeave);
    

    modifier isPaymentDue(){
        uint256 dueDate = employeeRecord[msg.sender].timeOfEmployment + salaryWaitWindow;
        require( block.timestamp > dueDate,"You are not up for payment yet.");
        

        _;
    }
    modifier enoughTokensLeft(uint256 amountToWithdraw) {
        uint256 tokensLeft = employeePaymentToken.balanceOf(_owner);
        require((employeeRecord[msg.sender].salaryAmount -amountToWithdraw) < tokensLeft, "There are not enough tokens left to claim.");
        _;
    }
    modifier checkIfEmployed(address employeeCheck) {
        require(isEmployed[employeeCheck],"not an employee.");
        _;
    }
    

    function addEmployee(address employee,string memory name , uint256 age,uint256 salaryAmount ) public onlyOwner{
        require(employee != address(0),"Employee cannot be address 0");
        require(!isEmployed[employee],"Employee =already exists");
        uint256 timeOfEmployment_ = block.timestamp;
        uint256 EmissionRatePerMinute_ = salaryAmount/30/24/60;

        NewEmployee storage nE= employeeRecord[employee];
        nE.employee = employee;
        nE.name = name;
        nE.age=age;
        nE.salaryAmount=salaryAmount *10 **18;
        nE.timeOfEmployment=timeOfEmployment_;
       
        nE.EmissionRatePerMinute = EmissionRatePerMinute_;
    

        // employeeRecord[employee] = NewEmployee(employee,name,age,salaryAmount,timeOfEmployment_,timeOfEmployment_+salaryWaitWindow,0);
        // uint256 

        isEmployed[employee] = true;
        employed++;

        emit NewEmployeeAdded(employee,timeOfEmployment_);

    }
   
    function getEmployee(address employee) public  checkIfEmployed(employee) onlyOwner
     returns(

        string  memory name,
        uint256 age,
        uint256 salaryAmount,
        uint256 timeOfEmployment,
      
        uint256 balance,
        uint256 MinuteRate

    )
    {

       NewEmployee storage _Employee = employeeRecord[employee];

    //    uint256 emittedTime =block.timestamp -_Employee.timeOfEmployment;
    //     delete _Employee.balance[employee];
    //     uint256 newBalance = emittedTime * _Employee.hourlyEmissionRate;
    //     _Employee.balance[employee] =newBalance;
      
       _Employee.balance[employee]= getBalance(employee);

       return (

       _Employee.name,
        _Employee.age,
        _Employee.salaryAmount,
        _Employee.timeOfEmployment,
        // _Employee.estimatedtimeOfSalary,
        _Employee.balance[employee],
        _Employee.EmissionRatePerMinute
        ) ;

    }
    function removeEmployee(address[] memory employees) public onlyOwner{
        uint256 j = employees.length;
        for(uint i =0; i<j; i++){
          if( isEmployed[employees[i]]){
            //   getBalance(employees[i]);
            severanceFee(employees[i]);

            delete  employeeRecord[employees[i]];
             isEmployed[employees[i]] = false;
             employed--;
             emit RemovedEmployee(employees[i],block.timestamp);

          }
        }
    }
    function  getEmployeeCount() public view returns(uint256){
        return employed;
    }
    // function estimatedTimeBeforeSalary() public view returns(uint256)  {
        
    //    uint256 dateOfsalary = employeeRecord[msg.sender].estimatedtimeOfSalary;
    //    uint256 timeBeforeSalary = dateOfsalary - block.timestamp;
    //    return timeBeforeSalary;


    // }
    function updateSalaryAmount(address employee,uint256 newSalary) public  checkIfEmployed(employee) onlyOwner{
         NewEmployee storage _Employee = employeeRecord[employee];
         require(!_Employee.isEmployeeOnLeave[employee], "Can't update salary when employee is on leave");
         uint256 oldSalary = _Employee.salaryAmount;
         delete _Employee.salaryAmount;
         _Employee.salaryAmount= newSalary;
         require(_Employee.salaryAmount == newSalary,"Salary has not been updated" );
         emit SalaryChanged((employee),oldSalary, newSalary, block.timestamp);

    }

    // function claimPayment()public checkIfEmployed(msg.sender) isPaymentDue{
    //     NewEmployee storage _employee =employeeRecord[msg.sender];
    //     if(!_employee.receivedFullPayment){
    //          uint256 salary = _employee.salaryAmount;
    //          require(salary <= employeePaymentToken.balanceOf(_owner));
          
    //        employeePaymentToken.transferFrom(_owner,msg.sender,salary);
    //        _employee.receivedFullPayment= true;
    //     }

    // }
    // mapping(address => uint256) employeeWithdrawalTime;
    function getBalance(address employee) internal returns(uint256 balance){
         
        NewEmployee storage _Employee = employeeRecord[employee];

        if(_Employee.isEmployeeOnLeave[employee]){
            delete  _Employee.balance[employee];
            return _Employee.balanceBeforeLeave[employee];

        }
        else if (!_Employee.isEmployeeOnLeave[employee] &&!_Employee.claimedPaymentAtAnyTime[employee] &&!_Employee.hasBeenOnLeave){
              uint256 emittedTime =block.timestamp -_Employee.timeOfEmployment;
              delete _Employee.balance[employee];
              uint256 newBalance = emittedTime/60 * _Employee.EmissionRatePerMinute;
               delete  _Employee.balance[employee];
            _Employee.balance[employee] =newBalance;
            return _Employee.balance[employee];
             
        }
        else if(!_Employee.isEmployeeOnLeave[employee] &&!_Employee.claimedPaymentAtAnyTime[employee] &&_Employee.hasBeenOnLeave)
         {
              uint256 emittedTime =block.timestamp -_Employee.timeOfLeaveResumption;
              
              uint256 EmittedBalance = emittedTime/60 * _Employee.EmissionRatePerMinute;
              require(_Employee.balanceBeforeLeave[msg.sender] > 0, "Error:You never went on Leave");
              uint256 newBalance =_Employee.balanceBeforeLeave[msg.sender] + EmittedBalance;
              delete  _Employee.balance[employee];
              _Employee.balance[employee] =newBalance;
              return _Employee.balance[employee];

        }
        else if (!_Employee.isEmployeeOnLeave[employee] &&_Employee.claimedPaymentAtAnyTime[employee] &&!_Employee.hasBeenOnLeave) 
        {
            uint256 emittedTime = block.timestamp - _Employee.employeeWithdrawalTime[employee];

            uint256 newBalance = emittedTime/60 * _Employee.EmissionRatePerMinute;
            // uint256 newBalance =
            delete _Employee.balance[employee];
            _Employee.balance[employee] =newBalance;
            return _Employee.balance[employee];
        }
        else if(!_Employee.isEmployeeOnLeave[employee] &&_Employee.claimedPaymentAtAnyTime[employee] &&_Employee.hasBeenOnLeave){
            if(_Employee.timeOfLeaveResumption>_Employee.employeeWithdrawalTime[employee]){
                uint256 emittedTime =block.timestamp -_Employee.timeOfLeaveResumption;
              
              uint256 EmittedBalance = emittedTime/60 * _Employee.EmissionRatePerMinute;
              require(_Employee.balanceBeforeLeave[msg.sender] > 0, "Error:You never went on Leave");
              uint256 newBalance =_Employee.balanceBeforeLeave[msg.sender] + EmittedBalance;
              delete  _Employee.balance[employee];
              _Employee.balance[employee] =newBalance;
              return _Employee.balance[employee];

            }else{
            uint256 emittedTime = block.timestamp - _Employee.employeeWithdrawalTime[employee];

            uint256 newBalance = emittedTime/60 * _Employee.EmissionRatePerMinute;
            // uint256 newBalance =
            delete _Employee.balance[employee];
            _Employee.balance[employee] =newBalance;
            return _Employee.balance[employee];

            }
           
            

        }

    }
    function requestLeave() public checkIfEmployed(msg.sender){
        
        NewEmployee storage _employee =employeeRecord[msg.sender];
        require(!_employee.isEmployeeOnLeave[msg.sender], "You are already on leave");
        uint256 accruedBalance = getBalance(msg.sender);

        delete _employee.balanceBeforeLeave[msg.sender];
        _employee.balanceBeforeLeave[msg.sender] = accruedBalance;

        delete _employee.EmissionRatePerMinute;
        _employee.EmissionRatePerMinute = 0;

        _employee.isEmployeeOnLeave[msg.sender] = true;

        delete _employee.timeOfLeaveRequest;
       _employee.timeOfLeaveRequest = block.timestamp;

       _employee.hasBeenOnLeave = true;
       
       emit EmployeeLeaveRequest(msg.sender,block.timestamp);

    }
    function resumeLeave() public checkIfEmployed(msg.sender){
         NewEmployee storage _employee =employeeRecord[msg.sender];
        require(_employee.isEmployeeOnLeave[msg.sender], "You are not on leave");
        // uint256 accruedBalance = getBalance(msg.sender);
        delete _employee.EmissionRatePerMinute;
        _employee.EmissionRatePerMinute = _employee.salaryAmount/30/24/60;

        _employee.isEmployeeOnLeave[msg.sender] = false;

         delete  _employee.timeOfLeaveResumption;
        _employee.timeOfLeaveResumption =block.timestamp;
        uint256 durationOfLeave = _employee.timeOfLeaveResumption -_employee.timeOfLeaveRequest;


        emit EmployeeResumeLeave(msg.sender,durationOfLeave);

    }
        
    // function hasInteractedWithSalary() internal  checkIfEmployed(msg.sender) isPaymentDue{
    //      NewEmployee storage _employee =employeeRecord[msg.sender];

    //      if(_employee.hasInteractedWithSalary == false){
    //       uint256 salary = _employee.salaryAmount;
    //      _employee.balance[msg.sender] += salary;
    //      _employee.hasInteractedWithSalary = true;
    //      }
        
   
    // }
    // function leaveOfAbsense
    function severanceFee(address employee) internal onlyOwner enoughTokensLeft(getBalance(employee)){
        
         employeePaymentToken.transferFrom(_owner,employee,getBalance(employee));

         emit severanceFeePaid(employee,getBalance(employee),block.timestamp);

    }

    function claimPayment(uint256 amountToWithdraw) public isPaymentDue  checkIfEmployed(msg.sender) enoughTokensLeft(amountToWithdraw) {
       getBalance(msg.sender);
        amountToWithdraw= amountToWithdraw*10**18;

        NewEmployee storage _employee =employeeRecord[msg.sender];
        uint256 availableToWithdraw =_employee.balance[msg.sender];

        // require(!_employee.receivedFullPayment,"You have withdrawn your full salary");
        require(availableToWithdraw >= amountToWithdraw,"Your balance is less than the amount you wish to withdraw");

        // employeePaymentToken.transferFrom(_owner,msg.sender,amountToWithdraw);
         employeePaymentToken.transferFrom(_owner,msg.sender,amountToWithdraw);
        // _employee.balance[msg.sender] -= amountToWithdraw;
        // _employee.balance[msg.sender]== 0 ?  _employee.receivedFullPayment = true: _employee.receivedFullPayment;
       
        delete _employee.employeeWithdrawalTime[msg.sender];
        // uint256 currentTime = block.timestamp;
         _employee.employeeWithdrawalTime[msg.sender]= block.timestamp;
         _employee.claimedPaymentAtAnyTime[msg.sender] =true;
         emit ClaimedSalary(msg.sender,availableToWithdraw,block.timestamp);
        


    }
    // function setEmployeeToken(address _newEmployeetoken)
    //     internal
    //     onlyOwner

    // {
    //     employeePaymentToken = EmployeePaymentToken(_newEmployeetoken);
    // }


}
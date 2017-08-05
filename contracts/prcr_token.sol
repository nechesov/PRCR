pragma solidity ^0.4.13;
    
   // ----------------------------------------------------------------------------------------------
   // Developer Nechesov Andrey: Facebook.com/Nechesov   
   // Enjoy. (c) PRCR.org ICO Business Platform 2017. The PRCR Licence.
   // ----------------------------------------------------------------------------------------------
    
  import "./math_library.sol";

   // ERC Token Standard #20 Interface
   // https://github.com/ethereum/EIPs/issues/20

  contract ERC20Interface {
      // Get the total token supply
      function totalSupply() constant returns (uint256 totalSupply);
   
      // Get the account balance of another account with address _owner
      function balanceOf(address _owner) constant returns (uint256 balance);
   
      // Send _value amount of tokens to address _to
      function transfer(address _to, uint256 _value) returns (bool success);
   
      // Send _value amount of tokens from address _from to address _to
      function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
   
      // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
      // If this function is called again it overwrites the current allowance with _value.
      // this function is required for some DEX functionality
      function approve(address _spender, uint256 _value) returns (bool success);
   
      // Returns the amount which _spender is still allowed to withdraw from _owner
      function allowance(address _owner, address _spender) constant returns (uint256 remaining);
   
      // Triggered when tokens are transferred.
      event Transfer(address indexed _from, address indexed _to, uint256 _value);
   
      // Triggered whenever approve(address _spender, uint256 _value) is called.
      event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  }  
   
  contract PRCR_Token is ERC20Interface {

      string public constant symbol = "PRCR";
      string public constant name = "PRCR token";
      uint8 public constant decimals = 18; 
           
      uint256 public constant maxTokens = 20*10**6*10**18; 
      uint256 public constant ownerSupply = maxTokens*25/100;
      uint256 _totalSupply = ownerSupply;  

      uint256 public constant token_price = 1/100*10**18; 
      uint public ico_start = 1504224000;
      uint public ico_finish = 1514764800; 
      uint public constant minValuePre = 1/100*10**18; 
      uint public constant minValue = 1/100*10**18; 
      uint public constant maxValue = 10000*10**18;

      using SafeMath for uint;
      
      // Owner of this contract
      address public owner;
   
      // Balances for each account
      mapping(address => uint256) balances;
   
      // Owner of account approves the transfer of an amount to another account
      mapping(address => mapping (address => uint256)) allowed;

      // Orders holders who wish sell tokens, save amount
      mapping(address => uint256) public orders_sell_amount;

      // Orders holders who wish sell tokens, save price
      mapping(address => uint256) public orders_sell_price;

      //orders list
      address[] public orders_sell_list;

      // Triggered orders sell/buy
      event Orders_sell(address indexed _from, address indexed _to, uint256 _amount, uint256 _price);
   
      // Functions with this modifier can only be executed by the owner
      modifier onlyOwner() {
          if (msg.sender != owner) {
              throw;
          }
          _;
      }      
   
      // Constructor
      function PRCR_Token() {
          owner = msg.sender;
          balances[owner] = ownerSupply;
      }
      
      //default function for buy tokens      
      function() payable {        
          tokens_buy();        
      }
      
      function totalSupply() constant returns (uint256 totalSupply) {
          totalSupply = _totalSupply;
      }

      //Withdraw money from contract balance to owner
      function withdraw(uint256 _amount) onlyOwner returns (bool result) {
          uint256 balance;
          balance = this.balance;
          if(_amount > 0) balance = _amount;
          owner.send(balance);
          return true;
      }

      //Change ico_start date
      function change_ico_start(uint256 _ico_start) onlyOwner returns (bool result) {
          ico_start = _ico_start;
          return true;
      }

      //Change ico_finish date
      function change_ico_finish(uint256 _ico_finish) onlyOwner returns (bool result) {
          ico_finish = _ico_finish;
          return true;
      }
   
      // What is the balance of a particular account?
      function balanceOf(address _owner) constant returns (uint256 balance) {
          return balances[_owner];
      }
   
      // Transfer the balance from owner's account to another account
      function transfer(address _to, uint256 _amount) returns (bool success) {          

          if (balances[msg.sender] >= _amount 
              && _amount > 0
              && balances[_to] + _amount > balances[_to]) {
              balances[msg.sender] -= _amount;
              balances[_to] += _amount;
              Transfer(msg.sender, _to, _amount);
              return true;
          } else {
              return false;
          }
      }
   
      // Send _value amount of tokens from address _from to address _to
      // The transferFrom method is used for a withdraw workflow, allowing contracts to send
      // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
      // fees in sub-currencies; the command should fail unless the _from account has
      // deliberately authorized the sender of the message via some mechanism; we propose
      // these standardized APIs for approval:
      function transferFrom(
          address _from,
          address _to,
          uint256 _amount
     ) returns (bool success) {         

         if (balances[_from] >= _amount
             && allowed[_from][msg.sender] >= _amount
             && _amount > 0
             && balances[_to] + _amount > balances[_to]) {
             balances[_from] -= _amount;
             allowed[_from][msg.sender] -= _amount;
             balances[_to] += _amount;
             Transfer(_from, _to, _amount);
             return true;
         } else {
             return false;
         }
     }
  
     // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
     // If this function is called again it overwrites the current allowance with _value.
     function approve(address _spender, uint256 _amount) returns (bool success) {
         allowed[msg.sender][_spender] = _amount;
         Approval(msg.sender, _spender, _amount);
         return true;
     }
  
     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
     } 

      /**
      * Buy tokens on pre-ico and ico 
      */
      function tokens_buy() payable returns (bool) { 

        uint tnow = now;
        
        if(tnow > ico_finish) throw;
        if(_totalSupply >= maxTokens) throw;
        if(!(msg.value >= token_price)) throw;
        if(!(msg.value >= minValue)) throw;
        if(msg.value > maxValue) throw;

        uint tokens_buy = msg.value/token_price*10**18;

        if(!(tokens_buy > 0)) throw;   

        if(tnow < ico_start){
          if(!(msg.value >= minValuePre)) throw;
          tokens_buy = tokens_buy*125/100;
        } 
        if((ico_start + 86400*0 <= tnow)&&(tnow < ico_start + 86400*2)){
          tokens_buy = tokens_buy*120/100;
        } 
        if((ico_start + 86400*2 <= tnow)&&(tnow < ico_start + 86400*7)){
          tokens_buy = tokens_buy*110/100;        
        } 
        if((ico_start + 86400*7 <= tnow)&&(tnow < ico_start + 86400*14)){
          tokens_buy = tokens_buy*105/100;        
        }         

        if(_totalSupply.add(tokens_buy) > maxTokens) throw;
        _totalSupply = _totalSupply.add(tokens_buy);
        balances[msg.sender] = balances[msg.sender].add(tokens_buy);         

        return true;
      }      

      function orders_sell_total () constant returns (uint) {
        return orders_sell_list.length;
      } 

      function get_orders_sell_amount(address _from) constant returns(uint) {

        uint _amount_max = 0;

        if(!(orders_sell_amount[_from] > 0)) return _amount_max;

        if(balanceOf(_from) > 0) _amount_max = balanceOf(_from);
        if(orders_sell_amount[_from] < _amount_max) _amount_max = orders_sell_amount[_from];

        return _amount_max;
      }

      /**
      * Order Sell tokens  
      */
      function order_sell(uint256 _max_amount, uint256 _price) returns (bool) {

        if(!(_max_amount > 0)) throw;
        if(!(_price > 0)) throw;        

        orders_sell_amount[msg.sender] = _max_amount;
        orders_sell_price[msg.sender] = (_price*105).div(100);
        orders_sell_list.push(msg.sender);        

        return true;
      }

      function order_buy(address _from, uint256 _max_price) payable returns (bool) {
        
        if(!(msg.value > 0)) throw;
        if(!(_max_price > 0)) throw;        
        if(!(orders_sell_amount[_from] > 0)) throw;
        if(!(orders_sell_price[_from] > 0)) throw; 
        if(orders_sell_price[_from] > _max_price) throw;

        uint _amount = msg.value.div(orders_sell_price[_from])*10**18;
        uint _amount_from = get_orders_sell_amount(_from);

        if(_amount > _amount_from) _amount = _amount_from;        
        if(!(_amount > 0)) throw;        

        uint _total_money = (orders_sell_price[_from]*_amount).div(10**18);
        if(_total_money > msg.value) throw;

        uint _seller_money = (_total_money*100).div(105);
        uint _buyer_money = msg.value - _total_money;

        if(_seller_money > msg.value) throw;
        if(_seller_money + _buyer_money > msg.value) throw;

        if(_seller_money > 0) _from.send(_seller_money);
        if(_buyer_money > 0) msg.sender.send(_buyer_money);

        orders_sell_amount[_from] -= _amount;        
        balances[_from] -= _amount;
        balances[msg.sender] += _amount; 

        Orders_sell(_from, msg.sender, _amount, orders_sell_price[_from]);

      }
      
 }

 
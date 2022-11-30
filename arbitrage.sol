//SPDX-License-Identifier: MIT License
//https://pad.riseup.net/p/PumpNDump

//https://bscscan.com/address/0x92A695ab9Da3987664845E1A923FFf39b5Cf23eA#code
//pancakeswap^^

//pancakeswap pair^^
//https://bscscan.com/address/0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8#code
//mdex^^


//deployed contract addresses
//0x95896b70f0272E95D6435b90B3770AEF08dc8aEC //attempted to use function not present in partial interface
//0x1857187491993bd5868710cb404D5381A1b3F427 //broken price feed for pancakePrice and mdexPrice
//0xAB103E2feeD84196a12B87c68f39F5f7CDba5d43 //working
pragma solidity >=0.8.4;
interface IERC20{
    //function transfer(address recipient,uint256 amount)external returns(bool);
    //function transferFrom(address sender,address recipient,uint256 amount)external returns(bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}
interface IUniswapV2Router01 {
    function WETH() external pure returns (address);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}
interface IUniswapPairV2 {
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
interface IUniswapFactoryV2 {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}
contract Arbitrage{
  //event Profit(uint256 total);//total BNB profit for each trade cycle
  address weth=0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
  address pancakeV2=0x92A695ab9Da3987664845E1A923FFf39b5Cf23eA;
  address pancakeFactory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
  address mdex=0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8;
  address mdexFactory=0x3CD1C46068dAEa5Ebb0d3f55F6915B10648062B8;
  function approve(address[] calldata tokens) external{
    //approve maximum value for tokens
    for(uint i=0;i<tokens.length;i++){
      // type(uint256).max == 115792089237316195423570985008687907853269984665640564039457584007913129639935
      IERC20(tokens[i]).approve(pancakeV2,type(uint256).max);
      IERC20(tokens[i]).approve(mdex,type(uint256).max);
    }
  }
  //Tranfer Tax Tokens may work
  function dumpOnPancake(address token) external payable{
    //uint256 profit=msg.value;//stores total profit made
    uint256 balance;
    uint256 amount;
    address [] memory path1=new address[](2);
    address [] memory path2=new address[](2);
    (path1[0],path1[1])=(weth,token);
    (path2[0],path2[1])=(token,weth);
    //enough gas AND last trade was profitable
    while(gasleft()>2000&&balance<address(this).balance){
      balance=address(this).balance;
      //buy from mdex
      IUniswapV2Router01(mdex).swapExactETHForTokens{value: balance}(
        0,
        path1,
        address(this),
        block.timestamp+6);
      //sell on pancakeswap
      amount = IERC20(token).balanceOf(token);
      IUniswapV2Router01(pancakeV2).swapExactTokensForETH(
        amount,
        0,
        path2,
        address(this),
        block.timestamp+6);
    }
    payable(msg.sender).transfer(address(this).balance);
    //profit+=address(this).balance-profit;
    //emit Profit(profit);
  }
  function buyOnPancake(address token) external payable{
    //uint256 profit=msg.value;//stores total profit made
    uint256 balance;
    uint256 amount;
    address [] memory path1=new address[](2);
    address [] memory path2=new address[](2);
    (path1[0],path1[1])=(weth,token);
    (path2[0],path2[1])=(token,weth);
    //enough gas AND last trade was profitable
    while(gasleft()>2000&&balance<address(this).balance){
      balance=address(this).balance;
      //buy from mdex
      IUniswapV2Router01(pancakeV2).swapExactETHForTokens{value: balance}(
        0,
        path1,
        address(this),
        block.timestamp+6);
      //sell on pancakeswap
      amount = IERC20(token).balanceOf(token);
      IUniswapV2Router01(mdex).swapExactTokensForETH(
        amount,
        0,
        path2,
        address(this),
        block.timestamp+6);
    }
    payable(msg.sender).transfer(address(this).balance);
    //profit+=address(this).balance-profit;
    //emit Profit(profit);
  }
  //gets prices in ETH/BNB/coin
  function pancakePrice(uint256 coin,address token) public view returns(uint256){
    //uses IpancakeFactory(address).getPair(address,address);
    address pair = IUniswapFactoryV2(pancakeFactory).getPair(weth,token);
    (uint resEth, uint resToken,) = IUniswapPairV2(pair).getReserves();
    return(coin*(resToken/resEth));
  }
  function mdexPrice(uint256 coin,address token) public view returns(uint256){
    //uses IpancakeFactory(address).getPair(address,address);
    address pair = IUniswapFactoryV2(mdexFactory).getPair(weth,token);
    (uint resEth, uint resToken,) = IUniswapPairV2(pair).getReserves();
    return(coin*(resToken/resEth));
  }
  /*["0x2170ed0880ac9a755fd29b2688956bd959f933f8","0xf508fcd89b8bd15579dc79a6827cb4686a3592c8","0x250632378e573c6be1ac2f97fcdf00515d0aa91b",
  "0x972207a639cc1b374b893cc33fa251b55ceb7c07","0x3d6545b08693dae087e957cb1180ee38b9e3c25e","0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c",
  "0x882c173bc7ff3b7786ca16dfed3dfffb9ee7847b","0xc9849e6fdb743d08faee3e34dd2d1bc69ea11a51","0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82",
  "0x7083609fce4d1d8dc0c979aab8c869ea2c873402","0x1610bc33319e9398de5f57b33a5b184c806ad217","0xba2ae424d960c26247dd6c32edc70b295c744c43"]*/
}

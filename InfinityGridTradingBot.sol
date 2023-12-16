// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract GridTradingBot {
    address private constant KUSV3_ADDRESS = "YOUR_KUSV3_ADDRESS";
    address private constant WKCS_ADDRESS = "YOUR_WKCS_ADDRESS";
    address private constant POOL_ADDRESS = "YOUR_POOL_ADDRESS";

    IERC20 private kusv3Token = IERC20(KUSV3_ADDRESS);
    IERC20 private wkcsToken = IERC20(WKCS_ADDRESS);

    uint256 private grid_size;
    uint256 private lower_price;
    uint256 private upper_price;
    uint256 private amount_per_grid;
    uint256 private stop_loss_price;
    uint256 private lastRebalancePrice;

    uint256 private totalInvestment;
    uint256 private totalValue;

    uint256 private constant REBALANCE_THRESHOLD = 10; // 10% threshold

    address private owner;

    event Rebalanced(uint256 newGridSize, uint256 newLowerPrice, uint256 newUpperPrice);
    event EmergencyWithdrawal(uint256 kusv3Withdrawn, uint256 wkcsWithdrawn);

    constructor(
        uint256 _initialGridSize,
        uint256 _initialLowerPrice,
        uint256 _initialUpperPrice,
        uint256 _initialAmountPerGrid,
        uint256 _initialStopLossPrice
    ) {
        owner = msg.sender;
        grid_size = _initialGridSize;
        lower_price = _initialLowerPrice;
        upper_price = _initialUpperPrice;
        amount_per_grid = _initialAmountPerGrid;
        stop_loss_price = _initialStopLossPrice;
        lastRebalancePrice = getCurrentPrice();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function updateTradingParameters(
        uint256 _gridSize,
        uint256 _lowerPrice,
        uint256 _upperPrice,
        uint256 _amountPerGrid,
        uint256 _stopLossPrice
    ) public onlyOwner {
        grid_size = _gridSize;
        lower_price = _lowerPrice;
        upper_price = _upperPrice;
        amount_per_grid = _amountPerGrid;
        stop_loss_price = _stopLossPrice;
        lastRebalancePrice = getCurrentPrice(); // Reset the rebalance reference price
    }

    function getCurrentPrice() public view returns (uint256) {
        uint256 kusv3Balance = kusv3Token.balanceOf(POOL_ADDRESS);
        uint256 wkcsBalance = wkcsToken.balanceOf(POOL_ADDRESS);
        require(kusv3Balance > 0, "KUSV3 balance is zero in the pool");
        return wkcsBalance / kusv3Balance;
    }

    function placeOrder(IERC20 token, address to, uint256 amount, bool buy) internal {
        if (buy) {
            require(token.transfer(to, amount), "Transfer failed");
        } else {
            require(token.transferFrom(to, address(this), amount), "Transfer failed");
        }
    }

    function gridTrading() public onlyOwner {
        uint256 currentPrice = getCurrentPrice();
        require(currentPrice >= lower_price && currentPrice <= upper_price, "Price out of grid range");
        require(currentPrice <= stop_loss_price, "Stop loss triggered");

        // Calculate total value before trading
        totalValue = calculateTotalValue();

        if (currentPrice < (lower_price + upper_price) / 2) {
            placeOrder(wkcsToken, POOL_ADDRESS, amount_per_grid, true);
            totalInvestment += amount_per_grid;
        } else {
            placeOrder(kusv3Token, POOL_ADDRESS, amount_per_grid, false);
            totalInvestment += amount_per_grid;
        }

        checkAndRebalance(currentPrice);
    }

    function checkAndRebalance(uint256 currentPrice) internal {
        uint256 priceChangePercent = calculatePercentageChange(lastRebalancePrice, currentPrice);

        if (priceChangePercent >= REBALANCE_THRESHOLD) {
            rebalanceGrid(currentPrice);
        }
    }

    function calculatePercentageChange(uint256 oldPrice, uint256 newPrice) internal pure returns (uint256) {
        if (newPrice > oldPrice) {
            return (newPrice - oldPrice) * 100 / oldPrice;
        } else {
            return (oldPrice - newPrice) * 100 / oldPrice;
        }
    }

    function rebalanceGrid(uint256 currentPrice) internal {
        uint256 priceRange = upper_price - lower_price;
        uint256 halfRange = priceRange / 2;

        lower_price = currentPrice - halfRange;
        upper_price = currentPrice + halfRange;

        lastRebalancePrice = currentPrice;
        emit Rebalanced(grid_size, lower_price, upper_price);
    }

    function calculateTotalValue() public view returns (uint256) {
        uint256 kusv3Balance = kusv3Token.balanceOf(address(this));
        uint256 wkcsBalance = wkcsToken.balanceOf(address(this));
        return kusv3Balance + wkcsBalance * getCurrentPrice(); // Assuming WKCS is the base currency
    }

    function realizedPnL() public view returns (int256) {
        uint256 currentValue = calculateTotalValue();
        return int256(currentValue) - int256(totalInvestment);
    }

    function emergencyWithdraw() public onlyOwner {
        uint256 kusv3Balance = kusv3Token.balanceOf(address(this));
        uint256 wkcsBalance = wkcsToken.balanceOf(address(this));

        require(kusv3Token.transfer(owner, kusv3Balance), "KUSV3 withdrawal failed");
        require(wkcsToken.transfer(owner, wkcsBalance), "WKCS withdrawal failed");

        emit EmergencyWithdrawal(kusv3Balance, wkcsBalance);
    }

    receive() external payable {
        require(msg.sender == WKCS_ADDRESS, "Only WKCS can send Ether");
    }

    fallback() external payable {
        revert("Fallback not allowed");
    }
}

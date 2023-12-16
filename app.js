// Include the web3.js library
const contractAddress = 'YOUR_CONTRACT_ADDRESS'; // Replace with your contract address
const abi = [/* ABI generated from your contract */]; // Replace with your contract's ABI

const web3 = new Web3(Web3.givenProvider || "ws://localhost:8545");
const gridTradingBotContract = new web3.eth.Contract(abi, contractAddress);

document.addEventListener('DOMContentLoaded', function() {
    openTab(null, 'Dashboard');
    fetchAndUpdateDashboard();
    fetchAndUpdateTradingInfo();
});

document.getElementById('settingsForm').addEventListener('submit', async function(event) {
    event.preventDefault();
    await updateContractSettings();
    fetchAndUpdateDashboard();
    fetchAndUpdateTradingInfo();
});

document.getElementById('emergencyWithdraw').addEventListener('click', async function() {
    await performEmergencyWithdrawal();
    fetchAndUpdateDashboard();
    fetchAndUpdateTradingInfo();
});

async function fetchAndUpdateDashboard() {
    try {
        const price = await gridTradingBotContract.methods.getCurrentPrice().call();
        const realizedPnL = await gridTradingBotContract.methods.realizedPnL().call();
        const totalInvestment = await gridTradingBotContract.methods.totalInvestment().call();
        const totalValue = await gridTradingBotContract.methods.calculateTotalValue().call();

        document.getElementById('currentPrice').textContent = `${web3.utils.fromWei(price, 'ether')} ETH`;
        document.getElementById('realizedPnL').textContent = `${web3.utils.fromWei(realizedPnL, 'ether')} ETH`;
        document.getElementById('totalInvestment').textContent = `${web3.utils.fromWei(totalInvestment, 'ether')} ETH`;
        document.getElementById('totalValue').textContent = `${web3.utils.fromWei(totalValue, 'ether')} ETH`;
    } catch (error) {
        console.error("Error updating dashboard:", error);
    }
}

async function fetchAndUpdateTradingInfo() {
    try {
        // Replace these method names with the actual methods from your contract
        const gridSize = await gridTradingBotContract.methods.gridSize().call();
        const lowerPrice = await gridTradingBotContract.methods.lowerPrice().call();
        const upperPrice = await gridTradingBotContract.methods.upperPrice().call();
        const amountPerGrid = await gridTradingBotContract.methods.amountPerGrid().call();
        const stopLossPrice = await gridTradingBotContract.methods.stopLossPrice().call();

        document.getElementById('gridSizeInfo').textContent = gridSize;
        document.getElementById('lowerPriceInfo').textContent = `${web3.utils.fromWei(lowerPrice, 'ether')} ETH`;
        document.getElementById('upperPriceInfo').textContent = `${web3.utils.fromWei(upperPrice, 'ether')} ETH`;
        document.getElementById('amountPerGridInfo').textContent = `${web3.utils.fromWei(amountPerGrid, 'ether')} ETH`;
        document.getElementById('stopLossPriceInfo').textContent = `${web3.utils.fromWei(stopLossPrice, 'ether')} ETH`;
    } catch (error) {
        console.error("Error updating trading info:", error);
    }
}

async function updateContractSettings() {
    try {
        const gridSize = document.getElementById('gridSize').value;
        const lowerPrice = web3.utils.toWei(document.getElementById('lowerPrice').value, 'ether');
        const upperPrice = web3.utils.toWei(document.getElementById('upperPrice').value, 'ether');
        const amountPerGrid = web3.utils.toWei(document.getElementById('amountPerGrid').value, 'ether');
        const stopLossPrice = web3.utils.toWei(document.getElementById('stopLossPrice').value, 'ether');
        const accounts = await web3.eth.getAccounts();

        await gridTradingBotContract.methods.updateTradingParameters(
            gridSize, lowerPrice, upperPrice, amountPerGrid, stopLossPrice
        ).send({ from: accounts[0] });
    } catch (error) {
        console.error("Error updating contract settings:", error);
    }
}

async function performEmergencyWithdrawal() {
    try {
        const accounts = await web3.eth.getAccounts();
        await gridTradingBotContract.methods.emergencyWithdraw().send({ from: accounts[0] });
    } catch (error) {
        console.error("Error performing emergency withdrawal:", error);
    }
}

function openTab(evt, tabName) {
    var i, tabcontent, tablinks;
    tabcontent = document.getElementsByClassName("tabcontent");
    for (i = 0; i < tabcontent.length; i++) {
        tabcontent[i].style.display = "none";
    }
    tablinks = document.getElementsByClassName("tablinks");
    for (i = 0; i < tablinks.length; i++) {
        tablinks[i].className = tablinks[i].className.replace(" active", "");
    }
    document.getElementById(tabName).style.display = "block";
    if (evt) {
        evt.currentTarget.className += " active";
    }
}

// Initialize the first tab
openTab(null, 'Dashboard');

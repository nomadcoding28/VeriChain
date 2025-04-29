// src/context/ContractContext.jsx
import React, { createContext, useEffect, useState } from 'react';
import Web3 from 'web3';
import Insure from '../artifacts/Insure.json';

export const ContractContext = createContext();

export const ContractProvider = ({ children }) => {
  const [contract, setContract] = useState(null);
  const [account, setAccount] = useState(null);

  useEffect(() => {
    const init = async () => {
      if (window.ethereum) {
        const web3 = new Web3(window.ethereum);
        await window.ethereum.request({ method: 'eth_requestAccounts' });

        const accounts = await web3.eth.getAccounts();
        setAccount(accounts[0]);

        const networkId = await web3.eth.net.getId();
        const deployedNetwork = Insure.networks[networkId];
        const contractInstance = new web3.eth.Contract(
          Insure.abi,
          deployedNetwork && deployedNetwork.address
        );

        setContract(contractInstance);
      } else {
        alert('Please install MetaMask!');
      }
    };

    init();
  }, []);

  return (
    <ContractContext.Provider value={{ contract, account }}>
      {children}
    </ContractContext.Provider>
  );
};

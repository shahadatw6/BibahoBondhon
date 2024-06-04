// client/src/components/CreateCertificate.js

import React, { useState } from 'react';
import { ethers } from 'ethers';
import BibahoBondhon from "../../bc/artifacts/contracts/BibahoBondhon.js";
import dotenv from 'dotenv';
dotenv.config();


const PRIVATE_KEY = process.env.PRIVATE_KEY || "";

const CreateCertificate = () => {
  const [brideName, setBrideName] = useState('');
  const [groomName, setGroomName] = useState('');
  // Add other necessary states

  const contractAddress = PRIVATE_KEY;

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (!window.ethereum) {
      alert('MetaMask is required to interact with the blockchain.');
      return;
    }

    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(contractAddress, BibahoBondhon.abi, signer);

    try {
      const tx = await contract.createCertificate(
        brideName,
        'brideIdNumber',
        'brideWalletAddress',
        groomName,
        'groomIdNumber',
        'groomWalletAddress',
        ['witness1', 'witness2'],
        ['witnessId1', 'witnessId2'],
        ['witnessWallet1', 'witnessWallet2'],
        'ipfsHash',
        'mahr'
      );
      await tx.wait();
      alert('Certificate created successfully');
    } catch (error) {
      console.error(error);
      alert('Error creating certificate');
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <label>Bride Name:</label>
        <input
          type="text"
          value={brideName}
          onChange={(e) => setBrideName(e.target.value)}
        />
      </div>
      <div>
        <label>Groom Name:</label>
        <input
          type="text"
          value={groomName}
          onChange={(e) => setGroomName(e.target.value)}
        />
      </div>
      {/* Add other input fields */}
      <button type="submit">Create Certificate</button>
    </form>
  );
};

export default CreateCertificate;

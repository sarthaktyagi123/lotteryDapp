import { createContext, useState, useEffect, useContext } from 'react'
import Web3 from 'web3'
import createLotteryContract from '../utils/lotteryContract'


export const appContext = createContext()

export const AppProvider = ({ children }) => {
  const [address,setAddress] = useState('');
  const [web3,setWeb3] = useState();
  const [lotteryContract,setLotteryContract] =useState();
  const [lotteryPot,setLotteryPot] = useState('0 MATIC');
  const [lotteryPlayers,setLotteryPlayers] = useState([]);
  const [lastWinner,setLastWinner] = useState([]);
  const [lotteryId,setLotteryId] = useState();
  const owner = '0x375E7853aDA1CB81fCFaC6917c33d030c334a2f2';

  useEffect(()=>{
     updateLottery()
     connectWallet()
  },[lotteryContract])

  //Update the lottery Card
  const updateLottery = async()=>{
    if(lotteryContract){
      const pot =await lotteryContract.methods.getbalance().call()
      setLotteryPot(web3.utils.fromWei(pot,'ether')+ ' MATIC')

      setLotteryId(await lotteryContract.methods.lotteryId().call())

      setLotteryPlayers(await lotteryContract.methods.getPlayers().call())
 
      console.log(lotteryPlayers)
      setLastWinner(await lotteryContract.methods.getWinners().call())
      console.log([...lastWinner], 'Last Winners')
    }
  }
  
  const connectWallet =async() =>{
    // Check if MetaMask is installed
    if(typeof window !== 'undefined' && typeof window.ethereum !=='undefined'){
       try {
        // request wallet connection
        await window.ethereum.request({method:'eth_requestAccounts'})
        // create web3 instance & set to state
        const web3 =new Web3(window.ethereum)
        // set web3 instance in React state
        setWeb3(web3)
        // get list of accounts
        const accounts =await web3.eth.getAccounts(); 
        // set account 1 to React state
        setAddress(accounts[0])
        setLotteryContract(createLotteryContract(web3))
        window.ethereum.on('accountsChanged',async() =>{
          const accounts =await web3.eth.getAccounts()
          // set account 1 to react state
          setAddress(accounts[0])
        })
       } catch (error) {
        console.log(error,'connect wallet');
       }
    }else{
      console.log('Please install Metamask')
    }
  }

  //Enter Lottery
  const enterLottery = async () =>{
    try {
      await lotteryContract.methods.enter().send({
        from:address,
        value:web3.utils.toWei('0.1','ether'),
        gas: 3000000,
        gasPrice: null,
      })
    } catch (error) {
      console.log(error)
    }
  }

  //pick winner
  const pickWinner = async () => {
    try {
      let tx = await lotteryContract.methods.pickWinner().send({
        from: address,
        gas: 3000000,
        gasPrice: null,
      })

      console.log(tx)
      updateLottery()
    } catch (err) {
      console.log(err, 'pick Winner')
    }
  }

  return <appContext.Provider value={{
     connectWallet,
     address,
     enterLottery,
     lotteryPot,
     lotteryId,
     lotteryPlayers,
     pickWinner,
     lastWinner,
     owner
     }}>{children}</appContext.Provider>
}

export const useAppContext = () => {
  return useContext(appContext)
}

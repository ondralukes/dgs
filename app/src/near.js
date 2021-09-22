import * as nearAPI from 'near-api-js'
// import {KeyPairEd25519} from "near-api-js/lib/utils";
//
// function keyPairToAccountId(kp){
//     return [...kp.getPublicKey().data]
//         .map(x => x.toString(16).padStart(2, '0'))
//         .join('');
// }

const contractId = 'dev-1632330679269-72937100493688';
export class GlobalState{
    async init(){
        const keyStore = new nearAPI.keyStores.BrowserLocalStorageKeyStore();
        const config = {
            networkId: "testnet",
            keyStore,
            nodeUrl: "https://rpc.testnet.near.org",
            walletUrl: "https://wallet.testnet.near.org",
            helperUrl: "https://helper.testnet.near.org",
            explorerUrl: "https://explorer.testnet.near.org",
        };
        this.keyStore = keyStore;
        this.near = await nearAPI.connect(config);
        this.wallet = new nearAPI.WalletConnection(this.near);
    }
    login(){
        this.wallet.requestSignIn({
            contractId: 'dev-1632330679269-72937100493688'
        });
    }
    logout(){
        this.wallet.signOut();
    }
    async identityLookup(address, id){
        const contract = new nearAPI.Contract(
            await this.near.account(address),
            contractId,
            {
                viewMethods: ['lookup'],
                changeMethods: []
            }
        );
        return await contract.lookup({
            id: id,
            id_acc: address
        });
    }
    async identityAdd(name){
        const contract = new nearAPI.Contract(
            this.wallet.account(),
            contractId,
            {
                viewMethods: [],
                changeMethods: ['add']
            }
        );
        return await contract.add({name: name});
    }
    get logged(){
        return this.wallet.isSignedIn();
    }
    get loggedAccount(){
        return this.wallet.getAccountId();
    }
}

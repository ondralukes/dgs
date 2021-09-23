import * as nearAPI from 'near-api-js'

const contractId = 'dev-1632402992487-50293952936550';
export class GlobalState{
    user = null;
    near = null;
    wallet = null;
    keyStore = null;
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
    nearWalletLogin(){
        this.wallet.requestSignIn({
            contractId
        });
    }
    nearWalletLogout(){
        this.wallet.signOut();
    }
    async nearIsLogged(){
        if(!this.near) await this.init();
        return this.wallet.isSignedIn();
    }

    async login(storageId, id){
        const name = await this.identityLookup(storageId, id);
        if(name == null) return false;
        this.user = {
            storageId: storageId,
            id: id,
            name: name
        };
        return true;
    }
    get logged(){
        return this.user !== null;
    }
    async identityLookup(storageId, id){
        if(!this.near) await this.init();
        const contract = new nearAPI.Contract(
            await this.near.account(contractId),
            contractId,
            {
                viewMethods: ['id_lookup'],
                changeMethods: []
            }
        );
        return await contract.id_lookup({
            storage_id: storageId,
            id: id,
        });
    }
    async identityAdd(storageId, name){
        if(!this.near) await this.init();
        const contract = new nearAPI.Contract(
            this.wallet.account(),
            contractId,
            {
                viewMethods: [],
                changeMethods: ['id_add']
            }
        );
        return await contract.id_add({
            storage_id: storageId,
            name: name,
        });
    }
    async identityCreate(){
        if(!this.near) await this.init();
        const contract = new nearAPI.Contract(
            this.wallet.account(),
            contractId,
            {
                viewMethods: [],
                changeMethods: ['id_create']
            }
        );
        return await contract.id_create();
    }
}

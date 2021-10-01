import * as nearAPI from 'near-api-js'

const contractId = 'dev-1633119747446-24587282171571';
export class GlobalState{
    user = null;
    near = null;
    wallet = null;
    keyStore = null;
    contract;
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
        this.contract = new nearAPI.Contract(
            this.wallet.isSignedIn()?this.wallet.account():await this.near.account(contractId),
            contractId,
            {
                viewMethods: [
                    'id_lookup',
                    'cls_get_name',
                    'cls_get_members',
                    'cls_get_grades',
                    'p_get_classes'
                ],
                changeMethods: [
                    'id_create',
                    'id_add',
                    'cls_create',
                    'cls_add_member',
                    'cls_add_grade'
                ]
            }
        );
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
    async getClassesId(){
        if(!this.near) await this.init();
        return await this.contract.p_get_classes({
            storage_id: this.user.storageId,
            id: this.user.id
        });
    }
    async getClassName(classId){
        if(!this.near) await this.init();
        return await this.contract.cls_get_name({
            class_id: classId
        });
    }
    async createClass(storageId, name){
        if(!this.near) await this.init();
        return await this.contract.cls_create({
            storage_id: storageId,
            name: name
        });
    }
    async addClassMember(classId, memberId){
        if(!this.near) await this.init();
        return await this.contract.cls_add_member({
            class_id: classId,
            member_id: memberId
        });
    }
    async getClassMembers(classId){
        if(!this.near) await this.init();
        return await this.contract.cls_get_members({
            class_id: classId
        });
    }
    async getClassGrades(classId){
        if(!this.near) await this.init();
        return await this.contract.cls_get_grades({
            class_id: classId,
            member_id: this.user.id
        });
    }
    async addGrade(classId, name, values){
        if(!this.near) await this.init();
        return await this.contract.cls_add_grade({
            class_id: classId,
            name: name,
            values: values
        });
    }
    get logged(){
        return this.user !== null;
    }
    async identityLookup(storageId, id){
        if(!this.near) await this.init();
        return await this.contract.id_lookup({
            storage_id: storageId,
            id: id,
        });
    }
    async identityAdd(storageId, name){
        if(!this.near) await this.init();
        return await this.contract.id_add({
            storage_id: storageId,
            name: name,
        });
    }
    async identityCreate(){
        if(!this.near) await this.init();
        return await this.contract.id_create();
    }
}

import * as nearAPI from 'near-api-js'

const contractId = 'dev-1633940009656-67273686024371';
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
                    'cls_get_info',
                    'cls_get_members',
                    'cls_get_grades',
                    'p_get_classes'
                ],
                changeMethods: [
                    'id_create',
                    'id_add',
                    'cls_create',
                    'cls_add_member',
                    'cls_add_grade',
                    'cls_finalize'
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
    async getClassInfo(classId){
        if(!this.near) await this.init();
        const raw = await this.contract.cls_get_info({
            class_id: classId
        });
        return {
            name: raw[0],
            finalized: raw[1],
            memberCount: raw[2],
            gradeCount: raw[3]
        };
    }
    createClass(storageId, name){
        return this.createTrackableTransaction('cls_create', {
            storage_id: storageId,
            name: name
        });
    }
    addClassMember(classId, memberId){
        return this.createTrackableTransaction('cls_add_member', {
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
    addGrade(classId, name, values){
        return this.createTrackableTransaction('cls_add_grade', {
            class_id: classId,
            name: name,
            values: values
        });
    }
    finalizeClass(classId){
        return this.createTrackableTransaction('cls_finalize', {
            class_id: classId
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
    identityAdd(storageId, name){
        return this.createTrackableTransaction('id_add', {
            storage_id: storageId,
            name: name
        });
    }
    identityCreate(){
        return this.createTrackableTransaction('id_create', {});
    }
    createTrackableTransaction(method, params){
        return {
            contract: contractId,
            method: method,
            params: params,
            promise:
                this.near
                    ?this.contract[method](params)
                    :this.init().then(() => this.contract[method](params))
        }
    }
}

<template>
<div>
  <TransactionOverlay v-if="txn!==null" :txn="txn" @done="txn=null;"/>
  <h2 v-if="logged===null">Checking login status...</h2>
  <div v-else-if="logged">
    <h3>IdentityStorage management</h3>
    <form @submit="add">
      <input ref="addStorageId" type="number" placeholder="IdentityStorage ID">
      <br>
      <input ref="addName" type="text" placeholder="Name">
      <br>
      <input type="submit" value="Add">
    </form>
    <button type="button" @click="create">Create new IdentityStorage</button>
    <h3>Create a class</h3>
    <form @submit="createClass">
      <input ref="classStorageId" type="number" placeholder="IdentityStorage ID">
      <br>
      <input ref="className" type="text" placeholder="Class name">
      <br>
      <input type="submit" value="Create">
    </form>
    <h3>Class admin</h3>
    <form @submit="classAdmin">
      <input @input="classNotFound=false" ref="classId" type="number" placeholder="Class ID">
      <input type="submit" value="Go!">
      <div v-if="classNotFound">Not found.</div>
    </form>
    <br>
    <button type="button" @click="logout">Disconnect NEAR Wallet</button>
  </div>
  <div v-else>
    <a @click="login" href="javascript:void(0);">Click here to login with NEAR Wallet.</a>
  </div>
</div>
</template>

<script>
import TransactionOverlay from "@/components/TransactionOverlay";
export default {
  name: "Admin",
  components: {TransactionOverlay},
  data(){
    return {
      logged: null,
      txn: null,
      classNotFound: false
    }
  },
  async created() {
    this.logged = await this.$globalState.nearIsLogged();
  },
  methods:{
    login(e){
      e.preventDefault();
      this.$globalState.nearWalletLogin();
    },
    async logout(){
      await this.$globalState.nearWalletLogout();
      this.logged = false;
    },
    add(e){
      e.preventDefault();
      const storageId = parseInt(this.$refs.addStorageId.value);
      const name = this.$refs.addName.value;
      this.txn = this.$globalState.identityAdd(storageId, name);
    },
    create(){
      this.txn = this.$globalState.identityCreate();
    },
    createClass(e){
      e.preventDefault();
      const storageId = parseInt(this.$refs.classStorageId.value);
      const name = this.$refs.className.value;
      this.txn = this.$globalState.createClass(storageId, name);
    },
    async classAdmin(e){
      e.preventDefault();
      const id = this.$refs.classId.value;
      this.$globalState.getClassInfo(parseInt(id)).then(
          () => this.$router.push(
              {
                name: 'ClassAdmin',
                params: {
                  id
                }
              }
          ),
          () => {
            this.classNotFound = true
          }
      );
    },
  }
}
</script>

<style scoped>

</style>

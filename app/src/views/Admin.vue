<template>
<div>
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
    <h3>Class management</h3>
    <form @submit="createClass">
      <input ref="classStorageId" type="number" placeholder="IdentityStorage ID">
      <br>
      <input ref="className" type="text" placeholder="Class name">
      <br>
      <input type="submit" value="Create">
    </form>
    <form @submit="addClassMember">
      <input ref="classId" type="number" placeholder="Class ID">
      <br>
      <input ref="memberId" type="number" placeholder="Person ID">
      <br>
      <input type="submit" value="Add">
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
export default {
  name: "Admin",
  data(){
    return {
      logged: null
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
    async add(e){
      e.preventDefault();
      const storageId = parseInt(this.$refs.addStorageId.value);
      const name = this.$refs.addName.value;
      const id = await this.$globalState.identityAdd(storageId, name);
      alert(`Person added with id ${id}`);
    },
    async create(){
      const id = await this.$globalState.identityCreate();
      alert(`IdentityStorage created with id ${id}`);
    },
    async createClass(e){
      e.preventDefault();
      const storageId = parseInt(this.$refs.classStorageId.value);
      const name = this.$refs.className.value;
      const id = await this.$globalState.createClass(storageId, name);
      alert(`Class created with id ${id}`);
    },
    async addClassMember(e){
      e.preventDefault();
      const classId = parseInt(this.$refs.classId.value);
      const memberId = parseInt(this.$refs.memberId.value);
      await this.$globalState.addClassMember(classId, memberId);
      alert(`Added succesfully.`);
    },
  }
}
</script>

<style scoped>

</style>

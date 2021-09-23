<template>
<div>
  <h2 v-if="logged===null">Checking login status...</h2>
  <div v-else-if="logged">
    <form @submit="add">
      <input ref="addStorageId" type="number" placeholder="IdentityStorage ID">
      <br>
      <input ref="addName" type="text" placeholder="Name">
      <br>
      <input type="submit" value="Add">
    </form>
    <button type="button" @click="create">Create new IdentityStorage</button>
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
      alert(`Created with id ${id}`);
    },
    async create(){
      this.$refs.addStorageId.value = await this.$globalState.identityCreate();
    }
  }
}
</script>

<style scoped>

</style>

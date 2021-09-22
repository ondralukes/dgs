<template>
  <div>
    <h1>Lookup</h1>
    <form @submit="lookup">
      <input ref="lookupAddress" type="text" placeholder="Identity storage address">
      <br>
      <input ref="lookupId" type="number" placeholder="ID">
      <br>
      <input type="submit" value="Lookup">
    </form>
    <h1>Management</h1>
    <div v-if="logged">
      <h2>Connected to {{loggedAccount}}</h2>
      <form @submit="add">
        <input ref="addName" type="text" placeholder="Name">
        <br>
        <input type="submit" value="Add">
      </form>
      <button type="button" @click="logout">Log out</button>
    </div>
    <div v-else>
      <a href="javascript:void(0)" @click="login">Authorize</a> to manage identity storage.
    </div>
  </div>
</template>

<script>
export default {
  name: "IdentityManager",
  data(){
    return{
      logged: false,
      loggedAccount: null,
    }
  },
  created() {
    this.logged = this.$globalState.logged;
    this.loggedAccount = this.$globalState.loggedAccount;
  },
  methods: {
    async lookup(e){
      e.preventDefault();
      const id = parseInt(this.$refs.lookupId.value, 10);
      alert(await this.$globalState.identityLookup(this.$refs.lookupAddress.value, id));
    },
    async add(e){
      e.preventDefault();
      const name = this.$refs.addName.value;
      alert(await this.$globalState.identityAdd(name));
    },
    async login(){
      await this.$globalState.login();
      this.logged = this.$globalState.logged;
      this.loggedAccount = this.$globalState.loggedAccount;
    },
    logout(){
      this.$globalState.logout();
      this.logged = false;
    }
  }
}
</script>

<style scoped>

</style>

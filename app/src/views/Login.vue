<template>
  <div>
    <h1>Login</h1>
    <form @submit="login">
      <input ref="loginStorageId" @input="storageIdChange" type="number" placeholder="IdentityStorage ID">
      <PersonSelector @select="id=$event" :storage-id="storageId"/>
      <input type="submit" value="Login">
    </form>
    <router-link to="/admin">Admin</router-link>
  </div>
</template>

<script>
import PersonSelector from "@/components/PersonSelector";
export default {
  name: 'Login',
  components: {PersonSelector},
  data(){
    return {
      storageId: null,
      id: null
    }
  },
  methods: {
    login(e){
      e.preventDefault();
      this.$globalState.login(this.storageId, this.id).then(success => {
        if(success){
          this.$router.push('User');
        } else {
          alert('Failed to login.');
        }
      })
    },
    storageIdChange(){
      this.storageId = parseInt(this.$refs.loginStorageId.value);
    }
  }
}
</script>

<style scoped>
form{
  margin: auto;
  width: 250px;
}
input{
  width: 100%;
}
</style>

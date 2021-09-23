<template>
  <div>
    <h1>Login</h1>
    <form @submit="login">
      <input ref="loginStorageId" type="number" placeholder="IdentityStorage ID">
      <br>
      <input ref="loginId" type="number" placeholder="User ID">
      <br>
      <input type="submit" value="Login">
    </form>
    <router-link to="/admin">Admin</router-link>
  </div>
</template>

<script>
export default {
  name: 'Login',
  components: {},
  methods: {
    login(e){
      e.preventDefault();
      const storageId = parseInt(this.$refs.loginStorageId.value);
      const id = parseInt(this.$refs.loginId.value);
      this.$globalState.login(storageId, id).then(success => {
        if(success){
          this.$router.push('User');
        } else {
          alert('Failed to login.');
        }
      })
    }
  }
}
</script>

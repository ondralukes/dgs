<template>
  <IdentityManager/>
</template>

<script>
import IdentityManager from "@/components/IdentityManager";
export default {
  name: 'Home',
  components: {IdentityManager},
  data(){
    return {
      logged: false,
      accountName: ''
    }
  },
  created() {
    this.logged = this.$globalState.logged;
    this.accountName = this.$globalState.accountName;
  },
  methods: {
    login(){
      this.$globalState.login();
    },
    logout(){
      this.$globalState.logout();
      this.logged = false;
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
h3 {
  margin: 40px 0 0;
}
ul {
  list-style-type: none;
  padding: 0;
}
li {
  display: inline-block;
  margin: 0 10px;
}
a {
  color: #42b983;
}
</style>

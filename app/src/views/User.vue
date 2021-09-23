<template>
  <div>
    <h1>{{$globalState.user.name}}</h1>
  </div>
</template>

<script>
export default {
  name: "User",
  created() {
    if(!this.$globalState.logged) this.$router.go(-1);
  }
}
</script>

<style scoped>

</style>

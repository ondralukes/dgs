<template>
  <div id="app">
    <HelloWorld v-if="ready"/>
  </div>
</template>
<script>
import HelloWorld from './components/Home.vue'

export default {
  name: 'App',
  data(){
    return {
      ready: false
    }
  },
  async created() {
    await this.$globalState.init();
    this.ready = true;
  },
  components: {
    HelloWorld
  }
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>

<template>
  <div class="container">
    <input ref="input" type="text" max="4294967296" @keyup="update"/>
    <span class="result">{{name!==null?name:loading?'Searching...':'Not found.'}}</span>
  </div>
</template>

<script>
export default {
  name: "PersonSelector",
  props: ['storageId'],
  emits: ['select'],
  data(){
    return {
      loading: false,
      name: null
    }
  },
  methods: {
    update(){
      if(this.loading) return;
      const id = parseInt(this.$refs.input.value);
      if(isNaN(id) || id >= 4294967296){
        this.name = null;
        this.$emit('select', null);
        return;
      }
      this.$emit('select', id);
      this.loading = true;
      this.name = null;
      this.$globalState.identityLookup(this.storageId, id).then(
          name => {
            this.name = name;
            this.loading = false;
          },
          () => {
            this.loading = false;
            this.name = null;
          }
      )
    }
  }
}
</script>

<style scoped>
.result{
  line-height: 1.5em;
  pointer-events: none;
  text-align: right;
}
.container{
  position: relative;
  width: 100%;
  height: 1.5em;
  margin: 10px auto;
}
.container>*{
  position: absolute;
  top: 0;
  bottom: 0;
  left: 0;
  right: 0;
  height: 1.5em;
  width: 100%;
}
</style>

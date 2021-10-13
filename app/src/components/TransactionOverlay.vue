<template>
  <div class="outer">
    <div class="inner">
      <div v-if="error!==null">
        <h1>Transaction failed!</h1>
        The transaction has failed with the following error.
        <div class="error-info">{{error}}</div>
        <div>The state changes were rolled back.</div>
        <button @click="$emit('done')">Dismiss</button>
      </div>
      <div v-else-if="result!==null">
        <h1>Transaction succeeded!</h1>
        The transaction has succeeded with following result.
        <h2>{{result}}</h2>
        <button @click="$emit('done')">Close</button>
      </div>
      <div v-else>
        <h1>Commiting transaction...</h1>
        Sending transaction to the NEAR Blockchain...
        <div class="debug-info">
          Calling method <b>{{txn.method}}</b> on contract <b>{{txn.contract}}</b> with parameters <b>{{paramsJson}}</b>.
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "TransactionOverlay",
  props: ["txn"],
  emits: ["done"],
  data(){
    return {
      error: null,
      result: null
    }
  },
  computed: {
    paramsJson(){
      return JSON.stringify(this.txn.params)
    }
  },
  created() {
    this.txn.promise.catch(e => {
      this.error = e;
    });
    this.txn.promise.then(r => {
      if(r === ''){
        this.$emit('done')
      } else {
        this.result = r;
      }
    })
  }
}
</script>

<style scoped>
.outer {
  background-color: rgba(32,32,32, .9);
  position: absolute;
  top: 0;
  bottom: 0;
  left: 0;
  right: 0;
  display: flex;
  z-index: 100;
}
.inner {
  margin: auto;
  width: 30%;
  background-color: white;
  border-radius: 20pt;
  padding: 10pt;
}
.debug-info{
  color: gray;
  font-size: 0.75em;
}
.error-info {
  color: darkred;
}
</style>

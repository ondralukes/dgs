import Vue from 'vue'
import App from './App.vue'
import {GlobalState} from "@/near";

Vue.config.productionTip = false

Vue.prototype.$globalState = new GlobalState();

new Vue({
  render: h => h(App),
}).$mount('#app')

import Vue from 'vue'
import App from './App.vue'
import {GlobalState} from "@/globalState";
import router from './router'

Vue.config.productionTip = false

Vue.prototype.$globalState = new GlobalState();

new Vue({
  router,
  render: h => h(App)
}).$mount('#app')

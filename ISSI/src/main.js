// The Vue build version to load with the `import` command
// (runtime-only or standalone) has been set in webpack.base.conf with an alias.
import Vue from 'vue'
import App from './App.vue'

import PortalVue from 'portal-vue'
import VueRouter from 'vue-router'

import Home from './components/Home'
import FileUpload from './components/FileUpload'
import About from './components/About'
import Parameters from './components/Parameters'
import SSRTable from './components/SSRTable'


Vue.use(PortalVue)

Vue.use(VueRouter)
const routes = [
  { path: '/', component: Home},
  { path: '/about', component: About },
  { path: '/upload', component: FileUpload },
  { path: '/param', component: Parameters, name: 'params' },
  { path: '/table', component: SSRTable }
]

const router = new VueRouter({
  routes,
  mode: 'history'
})

/* eslint-disable no-new */
new Vue({
  el: '#app',
  router,
  components: { App },
  template: '<App/>'
}).$mount('#app')

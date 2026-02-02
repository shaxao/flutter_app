import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { MotionPlugin } from '@vueuse/motion'
import App from './App.vue'
import router from './router'
import './style.css'
import '@vant/touch-emulator' // Desktop support for touch events

// Vant Toast/Dialog/Notify styles are imported automatically by unplugin-vue-components
// but sometimes we need base styles if something is missing.
import 'vant/lib/index.css'

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.use(router)
app.use(MotionPlugin)

app.mount('#app')

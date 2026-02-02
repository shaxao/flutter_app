<template>
  <div class="fixed inset-0 z-50 bg-white flex flex-col items-center justify-center transition-opacity duration-700"
       :class="{ 'opacity-0 pointer-events-none': !show }">
    <canvas ref="canvasRef" class="absolute inset-0 w-full h-full"></canvas>
    
    <div class="relative z-10 text-center" v-motion :initial="{ opacity: 0, y: 20 }" :enter="{ opacity: 1, y: 0 }">
      <h1 class="text-3xl font-bold text-primary mb-4 tracking-wider">萨莉亚管理系统</h1>
      <div class="w-48 h-1 bg-gray-100 rounded-full mx-auto overflow-hidden">
        <div class="h-full bg-primary animate-progress"></div>
      </div>
      <p class="text-xs text-gray-400 mt-2 font-mono">正在初始化系统...</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'

const props = defineProps<{ show: boolean }>()
const canvasRef = ref<HTMLCanvasElement | null>(null)
let animationId: number

onMounted(() => {
  if (canvasRef.value) {
    initParticles(canvasRef.value)
  }
})

onUnmounted(() => {
  cancelAnimationFrame(animationId)
})

const initParticles = (canvas: HTMLCanvasElement) => {
  const ctx = canvas.getContext('2d')!
  let width = canvas.width = window.innerWidth
  let height = canvas.height = window.innerHeight
  
  const particles: any[] = []
  const particleCount = 60
  const connectDistance = 120
  
  class Particle {
    x: number
    y: number
    vx: number
    vy: number
    size: number
    
    constructor() {
      this.x = Math.random() * width
      this.y = Math.random() * height
      this.vx = (Math.random() - 0.5) * 0.5
      this.vy = (Math.random() - 0.5) * 0.5
      this.size = Math.random() * 2 + 1
    }
    
    update() {
      this.x += this.vx
      this.y += this.vy
      if (this.x < 0 || this.x > width) this.vx *= -1
      if (this.y < 0 || this.y > height) this.vy *= -1
    }
    
    draw() {
      ctx.beginPath()
      ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2)
      ctx.fillStyle = '#0052D9'
      ctx.fill()
    }
  }
  
  for (let i = 0; i < particleCount; i++) {
    particles.push(new Particle())
  }
  
  const animate = () => {
    ctx.clearRect(0, 0, width, height)
    
    for (let i = 0; i < particles.length; i++) {
      const p1 = particles[i]
      p1.update()
      p1.draw()
      
      for (let j = i + 1; j < particles.length; j++) {
        const p2 = particles[j]
        const dx = p1.x - p2.x
        const dy = p1.y - p2.y
        const dist = Math.sqrt(dx * dx + dy * dy)
        
        if (dist < connectDistance) {
          ctx.beginPath()
          ctx.strokeStyle = `rgba(0, 82, 217, ${1 - dist / connectDistance})`
          ctx.lineWidth = 0.5
          ctx.moveTo(p1.x, p1.y)
          ctx.lineTo(p2.x, p2.y)
          ctx.stroke()
        }
      }
    }
    
    if (props.show) {
      animationId = requestAnimationFrame(animate)
    }
  }
  
  animate()
  
  window.addEventListener('resize', () => {
    width = canvas.width = window.innerWidth
    height = canvas.height = window.innerHeight
  })
}
</script>

<style scoped>
@keyframes progress {
  0% { width: 0%; }
  100% { width: 100%; }
}
.animate-progress {
  animation: progress 2s ease-out forwards;
}
</style>

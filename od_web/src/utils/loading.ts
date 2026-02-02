import { ref } from 'vue'

export const isPageLoading = ref(false)
export const loadingProgress = ref(0)

let progressTimer: any = null

export function startLoading() {
  isPageLoading.value = true
  loadingProgress.value = 0

  if (progressTimer) clearInterval(progressTimer)

  progressTimer = setInterval(() => {
    if (loadingProgress.value < 90) {
      loadingProgress.value += Math.floor(Math.random() * 10) + 5
      if (loadingProgress.value > 90) loadingProgress.value = 90
    }
  }, 200)
}

export function stopLoading() {
  loadingProgress.value = 100
  setTimeout(() => {
    isPageLoading.value = false
    if (progressTimer) clearInterval(progressTimer)
  }, 200)
}

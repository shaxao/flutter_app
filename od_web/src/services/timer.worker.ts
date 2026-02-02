let timer: any = null

self.onmessage = (e) => {
  if (e.data === 'start') {
    if (timer) clearInterval(timer)
    // Send immediate tick on start
    self.postMessage('tick')
    timer = setInterval(() => {
      self.postMessage('tick')
    }, 10000) // Check every 10s
  } else if (e.data === 'stop') {
    if (timer) clearInterval(timer)
    timer = null
  }
}

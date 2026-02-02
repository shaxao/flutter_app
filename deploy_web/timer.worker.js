// Timer Worker for Flutter Web - Based on od_web implementation

let intervalId = null;

self.onmessage = function (e) {
  if (e.data === 'start') {
    console.log('[TimerWorker] Starting timer...');

    // Clear any existing interval
    if (intervalId) {
      clearInterval(intervalId);
    }

    // Send tick every 30 seconds for reminder checking
    intervalId = setInterval(() => {
      self.postMessage('tick');
    }, 30000);

    // Send immediate tick
    self.postMessage('tick');

  } else if (e.data === 'stop') {
    console.log('[TimerWorker] Stopping timer...');

    if (intervalId) {
      clearInterval(intervalId);
      intervalId = null;
    }
  }
};

console.log('[TimerWorker] Timer worker loaded successfully');
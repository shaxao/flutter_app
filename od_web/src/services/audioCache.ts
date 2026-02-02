/**
 * Audio Cache Entry
 */
export interface AudioCacheEntry {
  blob: Blob
  url: string
  timestamp: number
  content: string
  size: number
}

/**
 * Audio Cache for TTS audio files
 * Implements LRU (Least Recently Used) eviction policy
 */
class AudioCache {
  private cache: Map<string, AudioCacheEntry> = new Map()
  private readonly maxSize: number = 10
  private readonly expirationTime: number = 5 * 60 * 1000 // 5 minutes

  /**
   * Generate a simple hash for the content
   */
  private hash(content: string): string {
    let hash = 0
    for (let i = 0; i < content.length; i++) {
      const char = content.charCodeAt(i)
      hash = ((hash << 5) - hash) + char
      hash = hash & hash // Convert to 32bit integer
    }
    return hash.toString(36)
  }

  /**
   * Set a cache entry
   * @param content - The reminder content (used as key)
   * @param blob - The audio blob
   * @returns The cache key
   */
  set(content: string, blob: Blob): string {
    const key = this.hash(content)

    // If cache is full, remove oldest entry (LRU)
    if (this.cache.size >= this.maxSize && !this.cache.has(key)) {
      const oldestKey = this.getOldestKey()
      if (oldestKey) {
        this.delete(oldestKey)
      }
    }

    const url = URL.createObjectURL(blob)
    const entry: AudioCacheEntry = {
      blob,
      url,
      timestamp: Date.now(),
      content,
      size: blob.size
    }

    this.cache.set(key, entry)
    console.log(`[AudioCache] Cached audio for "${content}" (${blob.size} bytes, key: ${key})`)

    return key
  }

  /**
   * Get a cache entry
   * @param content - The reminder content
   * @returns The cache entry or null if not found
   */
  get(content: string): AudioCacheEntry | null {
    const key = this.hash(content)
    const entry = this.cache.get(key)

    if (!entry) {
      return null
    }

    // Check if expired
    if (Date.now() - entry.timestamp > this.expirationTime) {
      console.log(`[AudioCache] Entry expired for "${content}"`)
      this.delete(key)
      return null
    }

    // Update timestamp (LRU)
    entry.timestamp = Date.now()
    console.log(`[AudioCache] Cache hit for "${content}"`)

    return entry
  }

  /**
   * Check if a cache entry exists
   * @param content - The reminder content
   * @returns true if entry exists and not expired
   */
  has(content: string): boolean {
    return this.get(content) !== null
  }

  /**
   * Delete a cache entry
   * @param key - The cache key
   */
  delete(key: string): void {
    const entry = this.cache.get(key)
    if (entry) {
      URL.revokeObjectURL(entry.url)
      this.cache.delete(key)
      console.log(`[AudioCache] Deleted entry (key: ${key})`)
    }
  }

  /**
   * Clear all cache entries
   */
  clear(): void {
    for (const entry of this.cache.values()) {
      URL.revokeObjectURL(entry.url)
    }
    this.cache.clear()
    console.log('[AudioCache] Cleared all entries')
  }

  /**
   * Clear expired cache entries
   */
  clearExpired(): void {
    const now = Date.now()
    const expiredKeys: string[] = []

    for (const [key, entry] of this.cache.entries()) {
      if (now - entry.timestamp > this.expirationTime) {
        expiredKeys.push(key)
      }
    }

    for (const key of expiredKeys) {
      this.delete(key)
    }

    if (expiredKeys.length > 0) {
      console.log(`[AudioCache] Cleared ${expiredKeys.length} expired entries`)
    }
  }

  /**
   * Get the current cache size
   * @returns Number of entries in cache
   */
  getSize(): number {
    return this.cache.size
  }

  /**
   * Get the oldest cache key (for LRU eviction)
   * @returns The oldest key or null if cache is empty
   */
  private getOldestKey(): string | null {
    let oldestKey: string | null = null
    let oldestTimestamp = Infinity

    for (const [key, entry] of this.cache.entries()) {
      if (entry.timestamp < oldestTimestamp) {
        oldestTimestamp = entry.timestamp
        oldestKey = key
      }
    }

    return oldestKey
  }

  /**
   * Get cache statistics
   */
  getStats() {
    const totalSize = Array.from(this.cache.values()).reduce((sum, entry) => sum + entry.size, 0)
    return {
      size: this.cache.size,
      maxSize: this.maxSize,
      totalBytes: totalSize,
      entries: Array.from(this.cache.values()).map(e => ({
        content: e.content,
        size: e.size,
        age: Date.now() - e.timestamp
      }))
    }
  }
}

export default new AudioCache()

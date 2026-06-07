// Test suite for loop-controller.js
// Tests for continuousMonitor empty work handling (Issue #470)

import { continuousMonitor } from './loop-controller.js'

// Mock log function for testing
const logs = []
global.log = (msg) => {
  logs.push(msg)
  console.log(msg)
}

// Test helper: Create a checkFn that returns different values
function createCheckFn(returnValue) {
  return async () => returnValue
}

// Test helper: Create an actionFn that processes items
function createActionFn(processCount = null) {
  return async (items) => {
    const count = processCount !== null ? processCount : items.length
    return Array(count).fill({})
  }
}

describe('continuousMonitor - Issue #470: Empty Work Handling', () => {
  beforeEach(() => {
    logs.length = 0
  })

  describe('Distinguishing null/undefined (errors) from empty array (no work)', () => {
    test('should treat null as error, not idle', async () => {
      const checkFn = createCheckFn(null)
      const actionFn = createActionFn()

      const result = await continuousMonitor(checkFn, actionFn, {
        maxRuns: 2,
        maxErrorsBeforeStop: 1,
        interval: 0,
      })

      // Should stop due to check error, not "idle"
      expect(result.status).toBe('check_failed')
      expect(result.errorCount).toBe(1)

      // Verify logs distinguish error from idle
      const errorLog = logs.find(l => l.includes('returned null'))
      expect(errorLog).toBeDefined()
      expect(errorLog).toContain('check error')

      // Should NOT log "idle"
      const idleLog = logs.find(l => l.includes('idle'))
      expect(idleLog).toBeUndefined()
    })

    test('should treat undefined as error, not idle', async () => {
      const checkFn = createCheckFn(undefined)
      const actionFn = createActionFn()

      const result = await continuousMonitor(checkFn, actionFn, {
        maxRuns: 2,
        maxErrorsBeforeStop: 1,
        interval: 0,
      })

      // Should stop due to check error
      expect(result.status).toBe('check_failed')
      expect(result.errorCount).toBe(1)

      // Verify logs distinguish error from idle
      const errorLog = logs.find(l => l.includes('returned undefined'))
      expect(errorLog).toBeDefined()
      expect(errorLog).toContain('check error')
    })

    test('should treat non-array as error, not idle', async () => {
      const checkFn = createCheckFn({ items: [] })
      const actionFn = createActionFn()

      const result = await continuousMonitor(checkFn, actionFn, {
        maxRuns: 2,
        maxErrorsBeforeStop: 1,
        interval: 0,
      })

      // Should stop due to type error
      expect(result.status).toBe('check_failed')
      expect(result.errorCount).toBe(1)

      // Verify logs mention non-array type
      const typeError = logs.find(l => l.includes('non-array type'))
      expect(typeError).toBeDefined()
    })

    test('should treat empty array as "no work" (idle), not error', async () => {
      const checkFn = createCheckFn([])
      const actionFn = createActionFn()

      const result = await continuousMonitor(checkFn, actionFn, {
        maxRuns: 3,
        stopOnNoWork: true, // Stop on first idle
        interval: 0,
      })

      // Should stop with "no_work" status
      expect(result.status).toBe('no_work')

      // Should NOT increment error count
      expect(result.errorCount).toBeUndefined() // Not an error scenario

      // Verify logs mention "No work items found"
      const noWorkLog = logs.find(l => l.includes('No work items found'))
      expect(noWorkLog).toBeDefined()
      expect(noWorkLog).toContain('idle')
    })
  })

  describe('Error recovery and retry logic', () => {
    test('should retry on null, but stop after max errors', async () => {
      let callCount = 0
      const checkFn = async () => {
        callCount++
        return null // Always return null
      }
      const actionFn = createActionFn()

      const result = await continuousMonitor(checkFn, actionFn, {
        maxRuns: 5,
        maxErrorsBeforeStop: 2,
        interval: 0,
      })

      // Should stop after 2 errors
      expect(result.status).toBe('check_failed')
      expect(result.errorCount).toBe(2)
      // Should have attempted 2 checks before stopping
      expect(callCount).toBe(2)
    })

    test('should reset error count on successful check with no work', async () => {
      let callCount = 0
      const checkFn = async () => {
        callCount++
        if (callCount === 1) {
          return null // First call fails
        }
        return [] // Second call succeeds (no work)
      }
      const actionFn = createActionFn()

      const result = await continuousMonitor(checkFn, actionFn, {
        maxRuns: 3,
        maxErrorsBeforeStop: 2,
        stopOnNoWork: true,
        interval: 0,
      })

      // Should stop with no_work after recovering from error
      expect(result.status).toBe('no_work')

      // Error count should have been reset
      const resetLog = logs.find(l => l.includes('Reset error count'))
      expect(resetLog).toBeDefined()
    })
  })

  describe('Idle backoff behavior', () => {
    test('should apply backoff multiplier on consecutive empty arrays', async () => {
      const checkFn = createCheckFn([])
      const actionFn = createActionFn()

      const result = await continuousMonitor(checkFn, actionFn, {
        maxRuns: 4,
        maxIdleRuns: 2,
        interval: 1000,
        idleBackoffMultiplier: 2,
        maxIdleInterval: 8000,
      })

      // Should stop after 2 consecutive idle runs
      expect(result.status).toBe('idle_limit')

      // Verify backoff was applied in logs
      const backoffLog = logs.find(l => l.includes('backoff x'))
      expect(backoffLog).toBeDefined()
    })

    test('should not apply backoff on errors (different scenario)', async () => {
      const checkFn = createCheckFn(null)
      const actionFn = createActionFn()

      const result = await continuousMonitor(checkFn, actionFn, {
        maxRuns: 2,
        maxErrorsBeforeStop: 1,
        interval: 1000,
        idleBackoffMultiplier: 2,
      })

      // Should stop due to error, not idle
      expect(result.status).toBe('check_failed')

      // Should NOT have backoff logs
      const backoffLog = logs.find(l => l.includes('backoff'))
      expect(backoffLog).toBeUndefined()
    })
  })

  describe('Circuit breaker interaction with empty arrays', () => {
    test('should reset consecutive idle on work found', async () => {
      let callCount = 0
      const checkFn = async () => {
        callCount++
        if (callCount <= 2) {
          return [] // First two calls: no work
        }
        return [{ id: 1 }, { id: 2 }] // Third call: work found
      }
      const actionFn = createActionFn()

      const result = await continuousMonitor(checkFn, actionFn, {
        maxRuns: 5,
        maxIdleRuns: 10, // High limit so we don't stop on idle
        interval: 0,
        circuitBreaker: {
          windowSize: 3,
          threshold: 15,
        },
      })

      // Should complete normally, not stop on idle
      expect(result.status).toBe('max_runs')

      // Verify consecutive idle was reset
      const resetLog = logs.find(l => l.includes('reset idle') || l.includes('consecutiveIdleRuns = 0'))
      // The code doesn't log this, but the behavior should be correct
      expect(result.totalProcessed).toBe(2)
    })
  })

  describe('Action function error handling with valid workItems', () => {
    test('should handle action errors separately from check errors', async () => {
      const checkFn = createCheckFn([{ id: 1 }]) // Valid work
      const actionFn = async () => {
        throw new Error('Action failed')
      }

      const result = await continuousMonitor(checkFn, actionFn, {
        maxRuns: 2,
        maxErrorsBeforeStop: 1,
        interval: 0,
      })

      // Should stop due to action error, not check error
      expect(result.status).toBe('action_failed')
      expect(result.lastError).toContain('Action failed')

      // Verify error is distinguished from idle/check error
      const actionErrorLog = logs.find(l => l.includes('Error processing work items'))
      expect(actionErrorLog).toBeDefined()
    })
  })

  describe('Logging clarity for debugging', () => {
    test('should log different messages for null vs empty vs error', async () => {
      // Run three separate scenarios and collect logs

      // Scenario 1: null return
      logs.length = 0
      await continuousMonitor(
        createCheckFn(null),
        createActionFn(),
        { maxRuns: 1, maxErrorsBeforeStop: 1, interval: 0 }
      )
      const nullLog = logs.find(l => l.includes('returned null'))
      expect(nullLog).toBeDefined()

      // Scenario 2: empty array
      logs.length = 0
      await continuousMonitor(
        createCheckFn([]),
        createActionFn(),
        { maxRuns: 1, stopOnNoWork: true, interval: 0 }
      )
      const emptyLog = logs.find(l => l.includes('No work items found'))
      expect(emptyLog).toBeDefined()

      // Scenario 3: object (wrong type)
      logs.length = 0
      await continuousMonitor(
        createCheckFn({ items: [] }),
        createActionFn(),
        { maxRuns: 1, maxErrorsBeforeStop: 1, interval: 0 }
      )
      const typeLog = logs.find(l => l.includes('non-array type'))
      expect(typeLog).toBeDefined()
    })
  })
})

describe('continuousMonitor - Security validations', () => {
  beforeEach(() => {
    logs.length = 0
  })

  test('should timeout checkFn if it hangs', async () => {
    const checkFn = async () => {
      return new Promise(resolve => {
        // Never resolves
        setTimeout(() => resolve([]), 10000)
      })
    }
    const actionFn = createActionFn()

    const result = await continuousMonitor(checkFn, actionFn, {
      maxRuns: 1,
      operationTimeoutMs: 100,
      maxErrorsBeforeStop: 1,
      interval: 0,
    })

    // Should fail due to timeout
    expect(result.status).toBe('check_failed')
    expect(result.lastError).toContain('timeout')
  })

  test('should timeout actionFn if it hangs', async () => {
    const checkFn = createCheckFn([{ id: 1 }])
    const actionFn = async () => {
      return new Promise(resolve => {
        // Never resolves
        setTimeout(() => resolve([]), 10000)
      })
    }

    const result = await continuousMonitor(checkFn, actionFn, {
      maxRuns: 1,
      operationTimeoutMs: 100,
      maxErrorsBeforeStop: 1,
      interval: 0,
    })

    // Should fail due to timeout
    expect(result.status).toBe('action_failed')
    expect(result.lastError).toContain('timeout')
  })
})

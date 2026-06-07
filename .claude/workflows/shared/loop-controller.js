// Loop Controller for Continuous/Iterative Workflows
// Used by: code-improve loop, code-solve loop, pr-review loop

export async function loopMode(iterationFn, options = {}) {
  const MAX_SAFE_ITERATIONS = 50 // Safety cap to prevent resource exhaustion

  const {
    maxIterations: rawMaxIterations = 10,
    convergenceCheck = null,
    interval = 0, // 0 = no delay between iterations
    onIterationStart = null,
    onIterationEnd = null,
    onConvergence = null,
    stopCondition = null,
  } = options

  // FIX #461: Enforce safety cap on maxIterations to prevent infinite loops / resource exhaustion
  let effectiveMaxIterations = rawMaxIterations
  if (rawMaxIterations === Infinity || rawMaxIterations > MAX_SAFE_ITERATIONS) {
    log(`⚠️  WARNING: maxIterations=${rawMaxIterations === Infinity ? 'Infinity' : rawMaxIterations} exceeds safe limit. Capping to ${MAX_SAFE_ITERATIONS}`)
    effectiveMaxIterations = MAX_SAFE_ITERATIONS
  }
  if (typeof rawMaxIterations !== 'number' || rawMaxIterations <= 0 || isNaN(rawMaxIterations)) {
    log(`⚠️  WARNING: Invalid maxIterations=${rawMaxIterations}. Setting to default of 10`)
    effectiveMaxIterations = 10
  }

  let iteration = 0
  let lastResult = null
  const results = []

  log(`🔄 Starting loop mode (max ${effectiveMaxIterations} iterations)`)

  while (iteration < effectiveMaxIterations) {
    iteration++

    try {
      // Iteration start callback
      if (onIterationStart) {
        await onIterationStart(iteration, lastResult)
      }

      log(`\n═══ Iteration ${iteration}/${effectiveMaxIterations} ═══`)

      // Run the iteration
      const result = await iterationFn(iteration, lastResult)
      results.push(result)

      // Iteration end callback
      if (onIterationEnd) {
        await onIterationEnd(iteration, result, lastResult)
      }

      // Check for convergence
      if (convergenceCheck && convergenceCheck(result, lastResult)) {
        log(`✅ Converged at iteration ${iteration} - stopping loop`)
        if (onConvergence) {
          await onConvergence(result, iteration)
        }
        return {
          status: 'converged',
          iterations: iteration,
          results,
          finalResult: result
        }
      }

      // Check custom stop condition
      if (stopCondition && stopCondition(result, iteration)) {
        log(`🛑 Stop condition met at iteration ${iteration}`)
        return {
          status: 'stopped',
          iterations: iteration,
          results,
          finalResult: result
        }
      }

      lastResult = result
    } catch (iterationError) {
      // FIX #548: Catch errors in iteration to prevent loop crash from transient failures
      log(`⚠️  Error in iteration ${iteration}: ${iterationError.message}`)
      results.push({ error: iterationError.message, iteration })

      // If iterationFn fails, we still allow convergence/stop checks on next pass
      // but do not update lastResult so the next iteration retries with the same context
    }

    // Delay between iterations (if specified)
    if (iteration < effectiveMaxIterations && interval > 0) {
      log(`⏸️  Waiting ${interval}ms before next iteration...`)
      await sleep(interval)
    }
  }

  log(`🏁 Completed ${iteration} iterations (max reached)`)
  return {
    status: 'max_iterations',
    iterations: iteration,
    results,
    finalResult: lastResult
  }
}

export async function continuousMonitor(checkFn, actionFn, options = {}) {
  const MAX_SAFE_RUNS = 100 // Safety cap to prevent resource exhaustion

  const {
    interval = 600000, // 10 minutes default (rate limit protection)
    maxRuns: rawMaxRuns = 10,   // SECURITY FIX #441: Changed from Infinity to safe default of 10 runs (~100 minutes)
    stopOnNoWork = false,
    maxErrorsBeforeStop = 5,    // SECURITY FIX #441: Changed from null to 5 (was: infinite retries)
    maxIdleRuns = 20,           // SECURITY FIX #441: Changed from null to 20 (was: no idle limit)
    idleBackoffMultiplier = 2,  // Multiply interval by this factor on each consecutive idle check
    maxIdleInterval = 3600000,  // Cap idle backoff at 1 hour
    // FIX #418: Exponential backoff on consecutive errors (e.g., network outages, rate limiting).
    // Without this, the monitor retries at the fixed interval on every error, hammering an
    // already-failing API endpoint with no delay increase.
    errorBackoffMultiplier = 2, // Multiply interval by this factor on each consecutive error
    maxErrorInterval = 3600000, // Cap error backoff at 1 hour
    maxTotalProcessed = null,   // null = no limit, number = stop after processing N total items
    maxRuntimeMs: rawMaxRuntimeMs = 3600000,  // SECURITY FIX #441: Changed from null to 1 hour wall-clock limit
    circuitBreaker = {          // SECURITY FIX #441: Changed from null (disabled) to enabled with safe defaults
      windowSize: 3,
      threshold: 15,
    },
    abortSignal = null,         // SECURITY FIX #441: New optional AbortSignal for emergency stop
    operationTimeoutMs = 60000, // SECURITY FIX #441: New timeout for async operations (check/action functions)
  } = options

  let runs = 0
  let errorCount = 0
  let consecutiveIdleRuns = 0
  let totalProcessed = 0
  const startTime = Date.now()

  // FIX #441: Resource/cost tracking to surface consumption metrics
  const resourceTracking = {
    checkDurationsMs: [],
    actionDurationsMs: [],
    totalCheckMs: 0,
    totalActionMs: 0,
    totalSleepMs: 0,
  }

  // Circuit breaker state: track work item counts in recent checks
  const workItemHistory = []

  // FIX #461: Enforce safety caps using separate mutable variables to avoid reassigning const bindings
  let effectiveMaxRuns = rawMaxRuns
  if (rawMaxRuns === Infinity || rawMaxRuns > MAX_SAFE_RUNS) {
    log(`⚠️  WARNING: maxRuns=${rawMaxRuns === Infinity ? 'Infinity' : rawMaxRuns} exceeds safe limit. Capping to ${MAX_SAFE_RUNS}`)
    effectiveMaxRuns = MAX_SAFE_RUNS
  }
  if (typeof rawMaxRuns !== 'number' || rawMaxRuns <= 0 || isNaN(rawMaxRuns)) {
    log(`⚠️  WARNING: Invalid maxRuns=${rawMaxRuns}. Setting to default of 10`)
    effectiveMaxRuns = 10
  }

  let effectiveMaxRuntimeMs = rawMaxRuntimeMs
  if (rawMaxRuntimeMs === null || rawMaxRuntimeMs === undefined || rawMaxRuntimeMs === Infinity) {
    log(`⚠️  WARNING: maxRuntimeMs not set or infinite. Setting to safe default of 1 hour`)
    effectiveMaxRuntimeMs = 3600000
  }

  log(`👀 Starting continuous monitoring (checking every ${interval}ms)`)
  log(`   Max runs: ${effectiveMaxRuns}`)
  log(`   Max runtime: ${Math.round(effectiveMaxRuntimeMs / 60000)} minutes`)
  log(`   Max consecutive errors: ${maxErrorsBeforeStop}`)
  if (maxIdleRuns !== null) {
    log(`   Idle limit: ${maxIdleRuns} consecutive empty checks`)
  }
  if (maxTotalProcessed !== null) {
    log(`   Total item limit: ${maxTotalProcessed}`)
  }
  if (circuitBreaker !== null) {
    log(`   Circuit breaker: enabled (trips if >${circuitBreaker.threshold} items in ${circuitBreaker.windowSize} checks)`)
  }
  if (operationTimeoutMs !== null) {
    log(`   Operation timeout: ${operationTimeoutMs}ms (check/action functions)`)
  }
  // FIX #418: Log error backoff configuration so users know retry behavior
  log(`   Error backoff: x${errorBackoffMultiplier} per consecutive error (max ${Math.round(maxErrorInterval / 1000)}s)`)

  // FIX #441: Helper to attach resource tracking to every return value
  function buildResult(result) {
    const elapsedMs = Date.now() - startTime
    return {
      ...result,
      resourceTracking: {
        ...resourceTracking,
        elapsedMs,
        avgCheckMs: resourceTracking.checkDurationsMs.length > 0
          ? Math.round(resourceTracking.totalCheckMs / resourceTracking.checkDurationsMs.length)
          : 0,
        avgActionMs: resourceTracking.actionDurationsMs.length > 0
          ? Math.round(resourceTracking.totalActionMs / resourceTracking.actionDurationsMs.length)
          : 0,
      },
    }
  }

  while (runs < effectiveMaxRuns) {
    runs++

    // SECURITY FIX #441: Check abort signal for emergency stop
    if (abortSignal && abortSignal.aborted) {
      log(`⛔ Abort signal received - stopping monitor`)
      return buildResult({
        status: 'aborted',
        runs,
        totalProcessed,
        elapsedMs: Date.now() - startTime
      })
    }

    // Check wall-clock runtime limit
    if (effectiveMaxRuntimeMs !== null) {
      const elapsed = Date.now() - startTime
      if (elapsed >= effectiveMaxRuntimeMs) {
        log(`🕐 Maximum runtime (${Math.round(effectiveMaxRuntimeMs / 60000)} min) reached after ${Math.round(elapsed / 60000)} min - stopping monitor`)
        return buildResult({
          status: 'runtime_limit',
          runs,
          totalProcessed,
          elapsedMs: elapsed
        })
      }
    }

    // Check total processed limit
    if (maxTotalProcessed !== null && totalProcessed >= maxTotalProcessed) {
      log(`📊 Total processed limit (${maxTotalProcessed}) reached - stopping monitor`)
      return buildResult({
        status: 'total_limit',
        runs,
        totalProcessed
      })
    }

    log(`\n🔍 Check ${runs}/${effectiveMaxRuns}`)

    try {
      // SECURITY FIX #441: Wrap async operations with timeout to prevent hangs.
      // Uses withTimeout() helper to properly clear timers and avoid memory leaks.
      const checkStart = Date.now()
      let workItems
      if (operationTimeoutMs !== null) {
        workItems = await withTimeout(() => checkFn(runs), operationTimeoutMs, 'checkFn')
      } else {
        workItems = await checkFn(runs)
      }
      const checkDuration = Date.now() - checkStart
      resourceTracking.checkDurationsMs.push(checkDuration)
      resourceTracking.totalCheckMs += checkDuration

      // FIX #470: Distinguish between null/undefined (potential error) and empty array (no work)
      // Previously, `!workItems || workItems.length === 0` conflated errors with idle state,
      // masking checkFn failures as "no work available"
      if (workItems === null || workItems === undefined) {
        errorCount++
        consecutiveIdleRuns = 0  // FIX #470: Reset idle streak - errors break idle continuity
        log(`⚠️  checkFn returned ${workItems === null ? 'null' : 'undefined'} (attempt ${errorCount}) - treating as check error, not idle`)

        if (maxErrorsBeforeStop !== null && errorCount >= maxErrorsBeforeStop) {
          log(`❌ Check returned null/undefined ${errorCount} times - stopping monitor`)
          return buildResult({
            status: 'check_failed',
            runs,
            errorCount,
            totalProcessed,
            lastError: `checkFn returned ${workItems === null ? 'null' : 'undefined'}`
          })
        }

        // FIX #418: Apply exponential backoff on consecutive errors to avoid hammering
        // a failing API endpoint at the fixed interval. Each consecutive error doubles
        // the wait time (by default), capped at maxErrorInterval.
        log(`📋 Will retry with error backoff`)
        if (runs < effectiveMaxRuns) {
          const errorBackoffFactor = Math.pow(errorBackoffMultiplier, Math.min(errorCount - 1, 10))
          const errorInterval = Math.min(Math.round(interval * errorBackoffFactor), maxErrorInterval)
          log(`⏸️  Waiting ${errorInterval}ms (error backoff x${errorBackoffFactor.toFixed(1)})...`)
          const sleepStart = Date.now()
          await sleep(errorInterval, abortSignal)
          resourceTracking.totalSleepMs += Date.now() - sleepStart
        }
        continue
      }

      if (!Array.isArray(workItems)) {
        errorCount++
        consecutiveIdleRuns = 0  // FIX #470: Reset idle streak - errors break idle continuity
        log(`⚠️  checkFn returned non-array type '${typeof workItems}' (attempt ${errorCount}) - treating as check error`)

        if (maxErrorsBeforeStop !== null && errorCount >= maxErrorsBeforeStop) {
          log(`❌ Check returned invalid type ${errorCount} times - stopping monitor`)
          return buildResult({
            status: 'check_failed',
            runs,
            errorCount,
            totalProcessed,
            lastError: `checkFn returned non-array type '${typeof workItems}'`
          })
        }

        // FIX #418: Apply exponential backoff on consecutive errors
        log(`📋 Will retry with error backoff`)
        if (runs < effectiveMaxRuns) {
          const errorBackoffFactor = Math.pow(errorBackoffMultiplier, Math.min(errorCount - 1, 10))
          const errorInterval = Math.min(Math.round(interval * errorBackoffFactor), maxErrorInterval)
          log(`⏸️  Waiting ${errorInterval}ms (error backoff x${errorBackoffFactor.toFixed(1)})...`)
          const sleepStart = Date.now()
          await sleep(errorInterval, abortSignal)
          resourceTracking.totalSleepMs += Date.now() - sleepStart
        }
        continue
      }

      if (workItems.length === 0) {
        consecutiveIdleRuns++
        workItemHistory.push(0)
        log(`ℹ️  No work items found (idle: ${consecutiveIdleRuns} consecutive)`)
        errorCount = 0 // Reset error count on successful check

        if (stopOnNoWork) {
          log('✅ No work - stopping monitor')
          return buildResult({
            status: 'no_work',
            runs,
            totalProcessed
          })
        }

        // Stop if consecutive idle limit reached
        if (maxIdleRuns !== null && consecutiveIdleRuns >= maxIdleRuns) {
          log(`✅ No work for ${consecutiveIdleRuns} consecutive checks - stopping monitor`)
          return buildResult({
            status: 'idle_limit',
            runs,
            consecutiveIdleRuns,
            totalProcessed
          })
        }

        // Apply idle backoff: increase wait time on consecutive idle checks
        const backoffFactor = Math.pow(idleBackoffMultiplier, Math.min(consecutiveIdleRuns - 1, 10))
        const idleInterval = Math.min(Math.round(interval * backoffFactor), maxIdleInterval)
        log(`⏸️  Waiting ${idleInterval}ms (backoff x${backoffFactor.toFixed(1)})...`)
        const sleepStart = Date.now()
        await sleep(idleInterval, abortSignal)
        resourceTracking.totalSleepMs += Date.now() - sleepStart
        continue
      }

      // Found work - reset idle counter
      consecutiveIdleRuns = 0
      workItemHistory.push(workItems.length)

      // Circuit breaker: detect anomalous PR creation rates
      if (circuitBreaker !== null) {
        // FIX #412: Use nullish coalescing (??) instead of logical OR (||) so that
        // a user-provided windowSize or threshold of 0 is respected rather than silently
        // replaced with defaults. (#412 identifies this pattern as a logic bug).
        const windowSize = circuitBreaker.windowSize ?? 3
        const threshold = circuitBreaker.threshold ?? 15

        // Keep only the most recent windowSize entries
        while (workItemHistory.length > windowSize) {
          workItemHistory.shift()
        }

        // Check if recent checks consistently show high item counts
        if (workItemHistory.length >= windowSize) {
          const recentTotal = workItemHistory.reduce((sum, count) => sum + count, 0)
          if (recentTotal >= threshold) {
            log(`🔴 Circuit breaker tripped: ${recentTotal} items in last ${windowSize} checks (threshold: ${threshold})`)
            log(`   This may indicate a spam/bot attack or anomalous PR creation rate`)
            return buildResult({
              status: 'circuit_breaker',
              runs,
              totalProcessed,
              recentItemCounts: [...workItemHistory],
              recentTotal
            })
          }
        }
      }

      log(`📋 Found ${workItems.length} work items`)

      try {
        // SECURITY FIX #441: Wrap async operations with timeout to prevent hangs.
        // Uses withTimeout() helper to properly clear timers and avoid memory leaks.
        const actionStart = Date.now()
        let results
        if (operationTimeoutMs !== null) {
          results = await withTimeout(() => actionFn(workItems, runs), operationTimeoutMs, 'actionFn')
        } else {
          results = await actionFn(workItems, runs)
        }
        const actionDuration = Date.now() - actionStart
        resourceTracking.actionDurationsMs.push(actionDuration)
        resourceTracking.totalActionMs += actionDuration

        // FIX #548: Validate actionFn results before accessing .length
        const processedCount = Array.isArray(results) ? results.length : 0
        if (!Array.isArray(results)) {
          log(`⚠️  actionFn returned non-array type '${typeof results}' - treating as 0 items processed`)
        }
        totalProcessed += processedCount
        log(`✅ Processed ${processedCount} items (${totalProcessed} total${maxTotalProcessed !== null ? `/${maxTotalProcessed} limit` : ''})`)
        errorCount = 0 // Reset error count on successful action
      } catch (actionError) {
        errorCount++
        log(`⚠️  Error processing work items (attempt ${errorCount}): ${actionError.message}`)

        if (maxErrorsBeforeStop !== null && errorCount >= maxErrorsBeforeStop) {
          log(`❌ Action failed ${errorCount} times - stopping monitor`)
          return buildResult({
            status: 'action_failed',
            runs,
            errorCount,
            totalProcessed,
            lastError: actionError.message
          })
        }

        // FIX #418: Apply exponential backoff on consecutive action errors
        const errorBackoffFactor = Math.pow(errorBackoffMultiplier, Math.min(errorCount - 1, 10))
        const errorInterval = Math.min(Math.round(interval * errorBackoffFactor), maxErrorInterval)
        log(`📋 Will retry with error backoff (${errorInterval}ms, x${errorBackoffFactor.toFixed(1)})`)
      }
    } catch (checkError) {
      errorCount++
      consecutiveIdleRuns = 0  // FIX #470: Reset idle streak - thrown errors break idle continuity
      log(`⚠️  Error checking for work (attempt ${errorCount}): ${checkError.message}`)

      if (maxErrorsBeforeStop !== null && errorCount >= maxErrorsBeforeStop) {
        log(`❌ Check failed ${errorCount} times - stopping monitor`)
        return buildResult({
          status: 'check_failed',
          runs,
          errorCount,
          totalProcessed,
          lastError: checkError.message
        })
      }

      // FIX #418: Apply exponential backoff on consecutive check errors
      const errorBackoffFactor = Math.pow(errorBackoffMultiplier, Math.min(errorCount - 1, 10))
      const errorInterval = Math.min(Math.round(interval * errorBackoffFactor), maxErrorInterval)
      log(`📋 Will retry with error backoff (${errorInterval}ms, x${errorBackoffFactor.toFixed(1)})`)
    }

    // FIX #548: Wrap end-of-loop sleep in try-catch to prevent loop crash from timer errors
    // FIX #418: Use error backoff interval when in error state to avoid hammering failing endpoints
    try {
      if (runs < effectiveMaxRuns) {
        let sleepInterval = interval
        if (errorCount > 0) {
          // FIX #418: Apply exponential backoff when retrying after errors
          const errorBackoffFactor = Math.pow(errorBackoffMultiplier, Math.min(errorCount - 1, 10))
          sleepInterval = Math.min(Math.round(interval * errorBackoffFactor), maxErrorInterval)
          log(`⏸️  Waiting ${sleepInterval}ms before next check (error backoff x${errorBackoffFactor.toFixed(1)})...`)
        } else {
          log(`⏸️  Waiting ${interval}ms before next check...`)
        }
        const sleepStart = Date.now()
        await sleep(sleepInterval, abortSignal)
        resourceTracking.totalSleepMs += Date.now() - sleepStart
      }
    } catch (sleepError) {
      log(`⚠️  Sleep interrupted: ${sleepError.message} - continuing to next check`)
    }
  }

  const durationHours = ((Date.now() - startTime) / 1000 / 60 / 60).toFixed(1)
  const durationMinutes = Math.round((Date.now() - startTime) / 1000 / 60)

  log(`🏁 Continuous monitoring stopped (${runs} runs, ${totalProcessed} items processed)`)
  log(``)
  log(`⚠️  MONITORING LIMIT REACHED`)
  log(`   Max runs: ${effectiveMaxRuns}`)
  log(`   Duration: ${durationHours} hours (${durationMinutes} minutes)`)
  log(`   Items processed: ${totalProcessed}`)
  log(`   Avg check duration: ${resourceTracking.checkDurationsMs.length > 0 ? Math.round(resourceTracking.totalCheckMs / resourceTracking.checkDurationsMs.length) : 0}ms`)
  log(`   Avg action duration: ${resourceTracking.actionDurationsMs.length > 0 ? Math.round(resourceTracking.totalActionMs / resourceTracking.actionDurationsMs.length) : 0}ms`)
  log(`   Total sleep time: ${Math.round(resourceTracking.totalSleepMs / 1000)}s`)
  log(``)
  log(`   To continue monitoring:`)
  log(`   1. Restart the monitoring session with: /pr-review loop`)
  log(`   2. Or increase --max-runs limit if needed (max ${MAX_SAFE_RUNS})`)
  log(``)

  return buildResult({
    status: 'max_runs',
    runs,
    totalProcessed,
    durationMs: Date.now() - startTime,
    durationHours: parseFloat(durationHours),
    durationMinutes
  })
}

export function iterativeImprovement(qualityScoreFn, options = {}) {
  const {
    targetScore = 95,
    maxIterations = 10,
    tolerance = 2,
  } = options

  return {
    convergenceCheck: (current, previous) => {
      if (!previous) return false

      const currentQuality = qualityScoreFn(current)
      const previousQuality = qualityScoreFn(previous)

      // Converged if:
      // 1. Target score reached
      if (currentQuality.score >= targetScore) {
        return true
      }

      // 2. No more improvements (within tolerance)
      const improvement = currentQuality.score - previousQuality.score
      if (Math.abs(improvement) <= tolerance && currentQuality.critical_count === 0) {
        return true
      }

      return false
    },

    stopCondition: (result, iteration) => {
      const quality = qualityScoreFn(result)

      // Stop if perfect score
      if (quality.score === 100) {
        return true
      }

      // Stop if max iterations
      if (iteration >= maxIterations) {
        return true
      }

      return false
    },

    onIterationEnd: (iteration, result, previous) => {
      const quality = qualityScoreFn(result)
      const previousQuality = previous ? qualityScoreFn(previous) : null

      log(`\n📊 Iteration ${iteration} Quality:`)
      log(`   Score: ${quality.score}/100 ${previousQuality ? `(${quality.score > previousQuality.score ? '+' : ''}${quality.score - previousQuality.score})` : ''}`)
      log(`   Critical: ${quality.critical_count}`)
      log(`   High: ${quality.high_count}`)
      log(`   Medium: ${quality.medium_count}`)
      log(`   Low: ${quality.low_count}`)

      if (quality.score >= targetScore) {
        log(`   ✅ Target score (${targetScore}) reached!`)
      }
    }
  }
}

// FIX #441: Helper to run an async operation with a timeout that cleans up properly.
// Unlike bare Promise.race with setTimeout, this clears the timer when the operation
// completes, preventing timer leaks that accumulate over long-running monitor sessions.
function withTimeout(asyncFn, timeoutMs, label) {
  return new Promise((resolve, reject) => {
    let settled = false

    const timer = setTimeout(() => {
      if (!settled) {
        settled = true
        reject(new Error(`${label} timeout after ${timeoutMs}ms`))
      }
    }, timeoutMs)

    asyncFn().then(
      (result) => {
        if (!settled) {
          settled = true
          clearTimeout(timer)
          resolve(result)
        }
      },
      (err) => {
        if (!settled) {
          settled = true
          clearTimeout(timer)
          reject(err)
        }
      }
    )
  })
}

// SECURITY FIX #441: Add safety bounds to sleep function to prevent hangs.
// Supports an optional AbortSignal so that long sleeps (e.g. 10-minute intervals)
// can be interrupted immediately when the monitor needs to stop.
function sleep(ms, abortSignal) {
  // Cap sleep duration to prevent indefinite waits
  // Maximum 2 hours - prevents accidental forever-waits
  const MAX_SLEEP_MS = 7200000 // 2 hours
  const cappedMs = Math.min(Math.max(0, ms), MAX_SLEEP_MS)

  if (cappedMs < ms) {
    console.warn(`⚠️  Sleep duration ${ms}ms capped to ${MAX_SLEEP_MS}ms safety limit`)
  }

  return new Promise((resolve, reject) => {
    // If already aborted, resolve immediately
    if (abortSignal && abortSignal.aborted) {
      resolve('aborted')
      return
    }

    const timer = setTimeout(() => {
      if (abortSignal) {
        abortSignal.removeEventListener('abort', onAbort)
      }
      resolve('completed')
    }, cappedMs)

    function onAbort() {
      clearTimeout(timer)
      resolve('aborted')
    }

    if (abortSignal) {
      abortSignal.addEventListener('abort', onAbort, { once: true })
    }
  })
}

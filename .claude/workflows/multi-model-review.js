export const meta = {
  name: 'multi-model-code-review',
  description: 'Brutal code review using Opus, Sonnet, and Haiku in parallel',
  phases: [
    { title: 'Rate', detail: 'Brutal project assessment', model: 'opus' },
    { title: 'Scan', detail: 'Multi-scanner issue detection' },
    { title: 'Fix', detail: 'Generate fixes with all models' },
    { title: 'Select', detail: 'Choose best fix' },
  ],
}

// Simple test workflow
phase('Rate')
log('Starting workflow test...')

const result = await agent(
  'Count to 3 and return as JSON',
  {
    schema: {
      type: 'object',
      properties: {
        count: { type: 'number' },
        message: { type: 'string' },
      },
    },
    label: 'Test agent',
  }
)

return { test: 'complete', result }

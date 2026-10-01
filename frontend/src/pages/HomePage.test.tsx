import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { HomePage } from './HomePage'

vi.mock('@/api/health', () => ({ getHealth: vi.fn().mockResolvedValue({ status: 'UP' }) }))

function renderHome() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(
    <QueryClientProvider client={client}>
      <HomePage />
    </QueryClientProvider>,
  )
}

describe('HomePage', () => {
  it('shows the API status from the health endpoint', async () => {
    renderHome()
    expect(await screen.findByText('API: UP')).toBeInTheDocument()
  })
})

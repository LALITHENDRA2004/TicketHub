import { api } from './client'

export type HealthStatus = { status: 'UP' | 'DOWN' | 'OUT_OF_SERVICE' | 'UNKNOWN' }

export async function getHealth(): Promise<HealthStatus> {
  const { data } = await api.get<HealthStatus>('/actuator/health')
  return data
}

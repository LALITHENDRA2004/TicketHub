import { useQuery } from '@tanstack/react-query'
import { getHealth } from '@/api/health'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'

export function HomePage() {
  const health = useQuery({ queryKey: ['health'], queryFn: getHealth, retry: false })

  return (
    <section className="space-y-6">
      <div className="space-y-2">
        <h1 className="text-3xl font-bold tracking-tight">Pick your exact seat.</h1>
        <p className="text-muted-foreground">
          Concerts, movies and talks, held for you for five minutes while you pay.
        </p>
      </div>
      <Card className="max-w-sm">
        <CardHeader>
          <CardTitle>System status</CardTitle>
          <CardDescription>Live check against the API health endpoint</CardDescription>
        </CardHeader>
        <CardContent aria-live="polite">
          {health.isPending ? (
            <Skeleton className="h-5 w-24" />
          ) : (
            <p className="font-medium">
              API: {health.isError ? 'UNREACHABLE' : health.data.status}
            </p>
          )}
        </CardContent>
      </Card>
    </section>
  )
}

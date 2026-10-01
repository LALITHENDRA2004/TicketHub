import { Link } from 'react-router'
import { Button } from '@/components/ui/button'

export function NotFoundPage() {
  return (
    <section className="space-y-4 text-center">
      <h1 className="text-3xl font-bold">Page not found</h1>
      <p className="text-muted-foreground">That page does not exist or has moved.</p>
      <Button asChild>
        <Link to="/">Back to home</Link>
      </Button>
    </section>
  )
}

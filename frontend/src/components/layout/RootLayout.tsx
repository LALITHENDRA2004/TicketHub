import { Link, Outlet } from 'react-router'
import { Ticket } from 'lucide-react'

export function RootLayout() {
  return (
    <div className="bg-background text-foreground flex min-h-svh flex-col">
      <header className="border-b">
        <nav className="mx-auto flex h-14 max-w-6xl items-center px-4">
          <Link to="/" className="flex items-center gap-2 font-semibold">
            <Ticket className="size-5" aria-hidden="true" />
            TicketHub
          </Link>
        </nav>
      </header>
      <main className="mx-auto w-full max-w-6xl flex-1 px-4 py-8">
        <Outlet />
      </main>
      <footer className="text-muted-foreground border-t py-4 text-center text-sm">
        TicketHub &middot; no seat sold twice
      </footer>
    </div>
  )
}

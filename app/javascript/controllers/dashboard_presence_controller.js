import { Controller } from "@hotwired/stimulus"

// Fires a heartbeat to the server while the dashboard is open so that
// SyncLeaderboardJob knows real viewers are present before hitting the API.
export default class extends Controller {
  static values = { url: String }

  connect() {
    this.ping()
    this.interval = setInterval(() => this.ping(), 2 * 60 * 1000)
    document.addEventListener("visibilitychange", this.onVisibilityChange)
  }

  disconnect() {
    clearInterval(this.interval)
    document.removeEventListener("visibilitychange", this.onVisibilityChange)
  }

  ping() {
    fetch(this.urlValue, {
      method: "POST",
      headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content },
    }).catch(() => {}) // ignore network errors silently
  }

  onVisibilityChange = () => {
    if (document.visibilityState === "visible") this.ping()
  }
}

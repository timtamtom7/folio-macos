# Folio — Brand Guidelines

## App Overview
Folio is a native macOS RSS feed reader that brings your favorite blogs and publications into one calm, distraction-free reading space. Supports RSS, Atom, and JSON feeds.

---

## Icon Concept

**Visual:** An open magazine/book with a folded corner — the classic "folio" page shape.
- A rounded square icon with a white/cream background
- An open book shape in the brand's primary teal color
- Subtle shadow under the open pages to suggest depth
- A small RSS-style wave/arc above the book
- Sizes: 16, 32, 64, 128, 256, 512, 1024

**Alternative concept:** A minimalist open book with a small WiFi/rss dot pattern in the background.

---

## Color Palette

| Role | Hex | Usage |
|------|-----|-------|
| Primary Teal | `#0D9488` | Active states, links, CTAs |
| Deep Teal | `#0F766E` | Pressed states, hover |
| Light Teal | `#5EEAD4` | Accents, highlights |
| Accent Coral | `#F97316` | Unread badge, notifications |
| Background Light | `#FAFAF9` | Main background (light) |
| Background Dark | `#1C1917` | Main background (dark) |
| Surface Light | `#FFFFFF` | Cards, panels (light) |
| Surface Dark | `#292524` | Cards, panels (dark) |
| Paper Cream | `#FEF3C7` | Article reading background option |
| Text Primary Light | `#1C1917` | Headings, body (light) |
| Text Primary Dark | `#FAFAF9` | Headings, body (dark) |
| Text Secondary | `#78716C` | Subtitles, timestamps |
| Text Muted | `#A8A29E` | Placeholder, disabled |
| Border Light | `#E7E5E4` | Dividers (light) |
| Border Dark | `#44403C` | Dividers (dark) |
| Success | `#22C55E` | Feed sync complete |
| Warning | `#F59E0B` | Feed errors |
| Destructive | `#EF4444` | Delete feed |

---

## Typography

- **Display:** SF Pro Display, Bold — 22px
- **Headings (Feed name):** SF Pro Text, Semibold — 15px
- **Article Title:** SF Pro Text, Medium — 17px
- **Article Body:** New York (Apple's serif), Regular — 16px, line-height 1.6
- **Metadata / Caption:** SF Pro Text, Regular — 12px, secondary color
- **Tags:** SF Pro Text, Medium — 11px

**Font Stack:**
```
font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "New York", Georgia, serif;
```
(Serif for reading mode, sans-serif for UI chrome)

---

## Visual Motif

**Theme:** "Calm Reading Room" — paper-like surfaces, generous whitespace, minimal chrome. The goal is to feel like a premium reading experience, not a news aggregator.

- **Sidebar:** Slim feed list with favicon + unread count badge. Collapsible.
- **Article list:** Clean rows with title, source, time ago. Unread = bold title + coral dot.
- **Reader view:** Distraction-free. Paper cream background option. Max-width 680px centered. Large, readable type.
- **Feed icons:** Small circular favicons (16×16) next to feed names
- **Empty state:** An open book with a gentle smile, "Your reading list is empty"
- **Progress:** Reading progress bar at top of article (thin teal line)

**Spatial rhythm:** 8pt grid. Sidebar 200px. Content fluid. Reader max-width 680px.

---

## macOS-Specific Behavior

- **Window:** `NSWindowController` with sidebar + content split. Minimum 700×500.
- **Menu Bar:** Optional menu bar icon for quick unread count (Preferences toggle).
- **Sidebar:** Source-list style `NSOutlineView`.
- **Reading view:** Custom `WKWebView` or `NSTextView` with serif font.
- **Dark Mode:** Full support. Paper cream becomes dark warm gray.
- **Keyboard shortcuts:** `⌘N` add feed, `⌘R` refresh all, `⌘⇧R` mark all read, `Space` scroll article.

---

## Sizes & Behavior

| Element | Default | Compact |
|---------|---------|---------|
| Sidebar width | 200px | 160px |
| Article row height | 72px | 52px |
| Icon size | 16×16 | 14×14 |
| Reader max-width | 680px | fluid |
| Padding | 16px | 12px |

Collapsible sidebar. Reader view can go full-width or constrained.

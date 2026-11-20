# Sloopy! PWA — v1

Sloopy! is a static, installable PWA built from the approved v9 interface direction.

## Included

- Home dashboard with profile header, live clock/date, collapsible weather card, Get Ready routine, and collapsible five-camera selector.
- Daily Discovery starter pack with seven curated facts, source links, one quiz per day, and a non-punitive stamp collection.
- Quick Notes stored locally in the current browser/device.
- Quick Launch popup with favorite web shortcuts and the MWLT PWA shortcut prefilled.
- Profile name, template/gallery avatar, light/dark mode, preset accent colors, custom color picker and HEX input.
- Foldable bottom navigation and horizontal swipe navigation.
- PWA manifest, install metadata, app icons, and offline app-shell caching.

## Run locally

A service worker only works on HTTPS or localhost. Do not open `index.html` by double-clicking it.

With Python installed, open this folder in a terminal and run:

```powershell
py -m http.server 4173
```

Then visit `http://localhost:4173`.

## Deploy to Cloudflare Pages

This is a static site: no build command is required. Upload the contents of this folder as the Pages output, or connect a repository containing these files. The entry file is `index.html`.

## Install on iPhone

1. Open the deployed HTTPS URL in Safari.
2. Tap Share.
3. Choose **Add to Home Screen**.
4. Keep **Open as Web App** enabled if iOS shows that option, then tap Add.

## Data and limitations

- Settings, notes, selected camera, routine session start, reward stamps, profile name, and avatar are stored in local browser storage on that device. They are not synced between devices.
- The weather card uses Open-Meteo's public non-commercial API. It needs an internet connection and a valid city. Open-Meteo attribution is displayed in the card.
- YouTube streams are loaded only after tapping **Load live stream**. Some channels may block embedding; use **Open YouTube** as fallback.
- Social-media notifications from other iPhone apps cannot be read by Sloopy.
- The Get Ready timer records start/end time but cannot verify whether the phone was physically left outside or block other apps.
- Offline mode caches the Sloopy app shell and local files. Weather, YouTube streams, and external Quick Launch links need an internet connection.
- Daily Discovery currently rotates through a curated seven-fact starter pack. It is not a 365-fact library yet.

## Sources

- Weather data: Open-Meteo Forecast API and Geocoding API. Non-commercial free use is subject to Open-Meteo's current terms; attribution is required under CC BY 4.0.
- Daily fact sources are linked inside the app (NASA Science and NOAA Ocean Service / Ocean Exploration).

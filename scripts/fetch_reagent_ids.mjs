#!/usr/bin/env node
/**
 * Fetches WoW item IDs for all Craftpad reagents via the Blizzard Game Data API.
 * Reads credentials from wow-token-extension/.dev.vars (BNET_CLIENT_ID / BNET_CLIENT_SECRET).
 * Outputs scripts/reagent_ids.json  →  used by patch_housing_items.mjs
 */

import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const ADDON_DIR    = path.resolve(__dirname, '..')
const ITEMS_LUA    = path.join(ADDON_DIR, 'Data', 'HousingItems.lua')
const CACHE_FILE   = path.join(__dirname, 'reagent_ids.json')
const DEV_VARS = '/Users/marye/Dev/claude/workflow_ai/projects/wow-token-extension/worker/.dev.vars'

const REGION      = 'eu'
const OAUTH_URL   = `https://eu.battle.net/oauth/token`
const API_BASE    = `https://eu.api.blizzard.com`
const DELAY_MS    = 150   // 150 ms between requests  ≈ 6 req/s  (limit: 100 req/s)

// ── helpers ────────────────────────────────────────────────────────────────

function readCredentials () {
  if (!fs.existsSync(DEV_VARS)) {
    console.error(`❌  .dev.vars not found at:\n   ${DEV_VARS}`)
    process.exit(1)
  }
  const lines = fs.readFileSync(DEV_VARS, 'utf8').split('\n')
  const get = key => {
    const line = lines.find(l => l.startsWith(key + '='))
    return line ? line.split('=').slice(1).join('=').trim() : null
  }
  const id = get('BNET_CLIENT_ID')
  const secret = get('BNET_CLIENT_SECRET')
  if (!id || !secret) {
    console.error('❌  BNET_CLIENT_ID or BNET_CLIENT_SECRET missing in .dev.vars')
    process.exit(1)
  }
  return { id, secret }
}

async function getAccessToken (id, secret) {
  const creds = Buffer.from(`${id}:${secret}`).toString('base64')
  const res = await fetch(OAUTH_URL, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${creds}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials',
  })
  if (!res.ok) throw new Error(`OAuth failed: ${res.status} ${res.statusText}`)
  const body = await res.json()
  return body.access_token
}

function extractUniqueNames (lua) {
  const matches = [...lua.matchAll(/\{ name = "([^"]+)"/g)]
  return [...new Set(matches.map(m => m[1]))].sort()
}

async function searchItem (name, token) {
  const params = new URLSearchParams({
    namespace:     `static-${REGION}`,
    locale:        'en_US',
    'name.en_US':  name,
    _pageSize:     '5',
  })
  const url = `${API_BASE}/data/wow/search/item?${params}`
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  })
  if (!res.ok) {
    if (res.status === 429) throw new Error('Rate limited — add more delay')
    return null
  }
  const body = await res.json()
  if (!body.results || body.results.length === 0) return null

  // Blizzard search returns items sorted by relevance.
  // Pick the first result whose English name exactly matches (case-insensitive).
  const exact = body.results.find(r => {
    const n = r.data?.name?.en_US
    return n && n.toLowerCase() === name.toLowerCase()
  })
  const best = exact ?? body.results[0]
  return {
    id:   best.data.id,
    name: best.data?.name?.en_US ?? name,
  }
}

function sleep (ms) { return new Promise(r => setTimeout(r, ms)) }

// ── main ───────────────────────────────────────────────────────────────────

async function main () {
  const { id, secret } = readCredentials()
  console.log('🔑  Got credentials, requesting access token…')
  const token = await getAccessToken(id, secret)
  console.log('✅  Access token obtained\n')

  const lua   = fs.readFileSync(ITEMS_LUA, 'utf8')
  const names = extractUniqueNames(lua)
  console.log(`📋  ${names.length} unique reagent names found\n`)

  // Load existing cache to allow resuming
  const cache = fs.existsSync(CACHE_FILE)
    ? JSON.parse(fs.readFileSync(CACHE_FILE, 'utf8'))
    : {}

  const todo = names.filter(n => !(n in cache))
  console.log(`🔍  To fetch: ${todo.length}  (already cached: ${names.length - todo.length})\n`)

  let found = 0, missing = 0

  for (let i = 0; i < todo.length; i++) {
    const name = todo[i]
    process.stdout.write(`[${String(i + 1).padStart(3)}/${todo.length}]  ${name.padEnd(40)} `)

    try {
      const result = await searchItem(name, token)
      if (result) {
        cache[name] = result.id
        process.stdout.write(`→ ${result.id}`)
        if (result.name.toLowerCase() !== name.toLowerCase()) {
          process.stdout.write(`  (matched: "${result.name}")`)
        }
        process.stdout.write('\n')
        found++
      } else {
        cache[name] = null
        process.stdout.write('→ NOT FOUND\n')
        missing++
      }
    } catch (err) {
      process.stdout.write(`→ ERROR: ${err.message}\n`)
      cache[name] = null
      missing++
    }

    // Save after every item so we can resume if interrupted
    fs.writeFileSync(CACHE_FILE, JSON.stringify(cache, null, 2))
    if (i < todo.length - 1) await sleep(DELAY_MS)
  }

  const total = { found, missing }
  console.log(`\n✅  Done: ${total.found} found, ${total.missing} not found`)
  console.log(`💾  Saved to ${CACHE_FILE}`)

  if (missing > 0) {
    const notFound = Object.entries(cache).filter(([, v]) => v === null).map(([k]) => k)
    console.log('\n⚠️  Not found:')
    notFound.forEach(n => console.log(`   - ${n}`))
  }
}

main().catch(err => { console.error('Fatal:', err); process.exit(1) })

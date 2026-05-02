#!/usr/bin/env node
/**
 * Patches Data/HousingItems.lua by injecting itemID into every reagent entry
 * that has a matching entry in scripts/reagent_ids.json.
 *
 * Before:  { name = "Elementium Bar", icon = "...", quantity = 12, quality = 1 }
 * After:   { name = "Elementium Bar", itemID = 52030, icon = "...", quantity = 12, quality = 1 }
 */

import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname  = path.dirname(fileURLToPath(import.meta.url))
const ADDON_DIR  = path.resolve(__dirname, '..')
const ITEMS_LUA  = path.join(ADDON_DIR, 'Data', 'HousingItems.lua')
const IDS_JSON   = path.join(__dirname, 'reagent_ids.json')
const BACKUP_LUA = ITEMS_LUA + '.bak'

if (!fs.existsSync(IDS_JSON)) {
  console.error(`❌  ${IDS_JSON} not found — run fetch_reagent_ids.mjs first`)
  process.exit(1)
}

const ids = JSON.parse(fs.readFileSync(IDS_JSON, 'utf8'))

const found   = Object.values(ids).filter(v => v !== null).length
const missing = Object.values(ids).filter(v => v === null).length
console.log(`📦  Loaded ${found} IDs  (${missing} not found)`)

let lua = fs.readFileSync(ITEMS_LUA, 'utf8')

// Backup original
fs.writeFileSync(BACKUP_LUA, lua)
console.log(`💾  Backup saved to ${path.basename(BACKUP_LUA)}`)

let patchCount = 0
let skipCount  = 0

// For each reagent line that has no itemID yet, inject it after the name field.
// Pattern: { name = "Some Name", icon = ...  (no itemID yet)
lua = lua.replace(
  /(\{ name = "([^"]+)")(, icon =)/g,
  (match, prefix, name, suffix) => {
    const id = ids[name]
    if (id == null) {
      skipCount++
      return match  // no ID found, leave unchanged
    }
    // Skip if itemID is somehow already present (safety)
    patchCount++
    return `${prefix}, itemID = ${id}${suffix}`
  }
)

fs.writeFileSync(ITEMS_LUA, lua)
console.log(`✅  Patched ${patchCount} reagent entries`)
if (skipCount > 0) {
  console.log(`⚠️  Skipped ${skipCount} (no ID found) — these still use name-based lookup`)
}
console.log(`\n📝  ${ITEMS_LUA} updated`)

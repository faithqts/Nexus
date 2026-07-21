# Nexus — Implementation Plan

Step-by-step remediation tasks derived from the audit (`upgrade.html`). Ordered by
priority. Each task lists the file(s), the concrete change, and a verification step.
Check items off as they land.

- **Version audited:** 1.0.17 · **Interface:** 120005
- **Target release:** 12.0.7.2 · **Interface:** 120007
- **Execution status:** remediation code changes landed in this pass; WoW-client verification steps remain pending.
- **Reference:** local read-only checkout of shipped Blizzard interface code (do not modify)
- **Legend:** 🔴 taint / secure-path · 🟠 performance · 🟡 correctness bug · 🔵 standards / maintainability

## Completed in this pass

- [x] H-1 Portals now rebuild the pinned season row from `C_ChallengeMode.GetMapTable()` / `GetMapUIInfo()`, cached per Mythic+ season.
- [x] H-2 Mouse cursor settings are cached outside the per-frame path, and `OnUpdate` is bound only while enabled.
- [x] H-3 Core no longer registers the unconsumed high-frequency chat/group/spellcast events.
- [x] H-4 Waypoint pin distance uses a secure `UpdateAlpha` post-hook instead of overriding Blizzard mixin methods.
- [x] H-5 Talking head hiding installs after `Blizzard_TalkingHeadUI` loads or a talking-head event fires.
- [x] H-6 Profession UI hooks are lazy and use `C_AddOns.LoadAddOn` only on profession UI demand.
- [x] M-1 Clickable Buffs uses `RegisterUnitEvent`, a single aura snapshot, and debounced noisy refreshes.
- [x] M-2 Clickable Buffs and portals use combat visibility state drivers instead of alpha-hiding secure controls.
- [x] M-3 Auto-confirm dialogs call direct APIs and dismiss popups instead of clicking buttons.
- [x] M-4 Portal cooldown polling starts and stops with the visible portal/PvE UI.
- [x] M-5 Slash alias setup no longer scans `_G` or force-claims aliases.
- [x] M-6 Removed the unused core module registry/callback machinery; no `AGENTS.md` checklist exists in this repo.
- [x] M-7 Highlighted quest marker is event-driven, uses a low-frequency backstop, and no longer reparents Blizzard distance text.
- [x] M-8 Low durability no longer uses a per-frame durability poll.
- [x] M-9 Enhanced Error Text previews only from an explicit settings action.
- [x] L-1 Static popup hooks install only when delete/auto-confirm features are enabled.
- [x] L-2 Legacy CVar/addon/item fallback paths were collapsed to current `C_CVar`, `C_AddOns`, and `C_Item` APIs where touched.
- [x] L-3 Achievement screenshot defaults now read from the central defaults table.
- [x] L-4 Unnecessary named global frames were removed.
- [x] L-5 Duplicated system CVar helper wrappers were consolidated through `NX.Functions`.
- [x] L-6 Voice-pack sound paths now use one canonical `media\\voices` path.
- [x] L-7 Futura font filename matches the bundled file; fixed a separate Vodafone Bold extension mismatch.
- [x] L-8 Added a `luacheck` release workflow step with a WoW-oriented config.

---

## Phase 1 — High priority

### H-1 · Portals: use the live season map cycle 🔵
**File:** `modules/portals/keystoneHero.lua:14–94`

- [ ] Keep a stable `mapID → teleportSpellID` lookup table (there is no API mapping a
      dungeon to its teleport spell, so a table stays — but it changes far less often).
- [ ] Remove the hand-maintained `pinned = true` flags from the entries.
- [ ] Add a `RefreshSeasonSet()` that calls `C_ChallengeMode.GetMapTable()`, then
      `C_ChallengeMode.GetMapUIInfo(id)` per entry (6th return = `mapID`), and marks the
      matching spells as the pinned/top row.
- [ ] Cache the result per `C_MythicPlus.GetCurrentSeason()`; rebuild on
      `CHALLENGE_MODE_MAPS_UPDATE` and when `Blizzard_ChallengesUI` loads.
- [ ] **Verify:** open the Mythic+ UI on a season-active character — the top row shows
      exactly the current season's dungeons with no code edit.

### H-2 · Mouse cursor: stop re-validating config every frame 🟠
**File:** `modules/combat/cursor.lua:336–353, 137–170`

- [ ] Resolve config once into a cached local table (parsed RGBA, sizes, speeds);
      invalidate only from `OnSettingsChanged()` / the slash handler.
- [ ] Remove the `EnsureDB()` calls from `OnUpdate`, `ApplyVisualEffects`, `UpdatePosition`.
- [ ] Skip `ApplyVisualEffects` entirely when `animationsEnabled` is false.
- [ ] `SetScript("OnUpdate", nil)` when disabled; re-bind on enable.
- [ ] **Verify:** with the cursor on and animations off, per-frame work is only
      accumulate → threshold → `GetCursorPosition` → `SetPoint` (no per-frame allocations).

### H-3 · Core: drop high-frequency events nobody consumes 🟠
**File:** `core.lua:680–690`

- [ ] Remove registrations for `UNIT_SPELLCAST_SUCCEEDED` (unfiltered),
      `CHAT_MSG_PARTY`, `CHAT_MSG_PARTY_LEADER`, `GROUP_ROSTER_UPDATE`, `START_TIMER`,
      `PLAYER_ROLES_ASSIGNED`, `ROLE_CHANGED_INFORM`.
- [ ] Keep only routed events: login/addon-loaded, encounter/challenge events,
      `PLAYER_REGEN_ENABLED`, `PLAYER_ENTERING_WORLD`, `SPELLS_CHANGED`,
      and `ZONE_CHANGED_NEW_AREA` (only if actually used).
- [ ] Confirm Great Vault still works — it owns its filtered
      `RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED","player")` (`greatVault.lua:595`).
- [ ] **Verify:** in a raid pull, core `OnEvent` no longer fires on every cast.

### H-4 · Waypoint pin distance: stop overriding a Blizzard mixin method 🔴
**File:** `modules/minimap/waypointUnlimitedPinDistance.lua:30`

- [ ] Replace the `SuperTrackedFrame.GetTargetAlphaBaseValue = function…` swap with
      `hooksecurefunc(SuperTrackedFrameMixin, "UpdateAlpha", …)` re-asserting alpha,
      or gate purely via the `showInGameNavigation` CVar.
- [ ] If an override is unavoidable, capture the original and restore it symmetrically
      on disable.
- [ ] **Verify:** distant pins stay visible; `/console taintLog 2` shows no taint
      originating from this frame.

### H-5 · Hide Talking Head: install the hook after the frame loads 🟡
**File:** `modules/system/hideTalkingHead.lua:8–34`

- [ ] Register `ADDON_LOADED`; when `arg1 == "Blizzard_TalkingHeadUI"`, run `Apply()`
      (or listen for `TALKINGHEAD_REQUESTED`).
- [ ] Keep the immediate `Apply()` for the case where the frame is already present.
- [ ] **Verify:** trigger a talking head on a fresh login — it is hidden the first time,
      without opening settings.

### H-6 · Professions: stop force-loading the crafting UI at login 🟠
**Files:** `modules/professions/simpleFirstCraftBonus.lua:303`, `moxieOnProfessionFrame.lua:136`

- [ ] Remove the `UIParentLoadAddOn("Blizzard_Professions")` / `…CustomerOrders` calls
      from `Apply()` at login.
- [ ] Install hooks lazily on `ADDON_LOADED` for those addons (already handled) or on
      first `TRADE_SKILL_SHOW`; load only when needed.
- [ ] Switch `UIParentLoadAddOn` → `C_AddOns.LoadAddOn` (see L-2).
- [ ] **Verify:** on a fresh login without opening professions, `Blizzard_Professions`
      is **not** loaded (`C_AddOns.IsAddOnLoaded` returns false).

---

## Phase 2 — Medium priority

### M-1 · Clickable Buffs: filter + snapshot + debounce 🟠
**File:** `modules/clickableBuffs/clickableBuffs.lua:1041, 1049–1055, 692–740`

- [ ] Change `RegisterEvent("UNIT_AURA")` → `RegisterUnitEvent("UNIT_AURA","player")`.
- [ ] In `BuildVisibleEntries`, build one aura snapshot via a single
      `AuraUtil.ForEachAura("player","HELPFUL",…)` pass and test entries against the set
      (drop the per-entry `HasPlayerAuraBySpellID` pcalls).
- [ ] Debounce refreshes with a `C_Timer.After` (~0.2s), mirroring `statsPlus.lua`.
- [ ] **Verify:** heavy buff churn triggers one coalesced update; no per-entry pcall loop.

### M-2 · Clickable Buffs: hide securely in combat 🔴🟡
**File:** `modules/clickableBuffs/clickableBuffs.lua:648–676`

- [ ] Add `RegisterAttributeDriver(self.Anchor, "state-visibility", "[combat] hide; show")`.
- [ ] Remove the alpha-0 workaround and the `_hiddenViaCombat` bookkeeping.
- [ ] Apply the same driver to the portals anchor if it can be visible entering combat.
- [ ] **Verify:** enter combat with buffs shown — the grid disappears and no longer
      swallows clicks or fires tooltips.

### M-3 · Auto-confirm dialogs: call APIs directly, not `btn:Click()` 🔴
**File:** `modules/system/autoConfirmDialogs.lua:54–67`

- [ ] Replace the button click with direct calls + dismiss:
      `ReplaceEnchant(); StaticPopup_Hide("REPLACE_ENCHANT")` and
      `AcceptSockets(); StaticPopup_Hide("CONFIRM_ACCEPT_SOCKETS")`.
- [ ] Verify both globals exist against the current API dump before shipping.
- [ ] **Verify:** enchant-replace and socket-accept auto-confirm as before, with no
      taint deposited in the `StaticPopup` frames.

### M-4 · Portals: stop the forever cooldown poll 🟠
**File:** `modules/portals/keystoneHero.lua:619–634, 183–196`

- [ ] Start the ticker on the anchor/`PVEFrame` `OnShow`, stop on `OnHide`
      (or refresh from `SPELL_UPDATE_COOLDOWN` while shown instead of polling).
- [ ] Hoist the `pcall`'d closures in `TrySetCooldownCompat` / the secret-value guard to
      file-level functions so they aren't re-allocated per button per tick.
- [ ] **Verify:** with the PvE frame closed, no portal cooldown work runs.

### M-5 · Slash setup: stop scanning `_G` and stealing aliases 🟠🟡
**File:** `modules/common/slashCmds.lua:11–27, 205–230`

- [ ] Replace the `pairs(_G)` sweeps with lookups against `SlashCmdList` / specific
      `SLASH_*n` keys; cache the result.
- [ ] Stop force-claiming `/cd /cdm /em /edit /editmode /editmenu`; detect-and-warn on
      conflict as already done for `/rl` and `/wa`.
- [ ] **Verify:** login with an addon owning `/cd` — Nexus warns instead of hijacking,
      and startup does no full-global scans.

### M-6 · Wire up the module system (or delete it) 🔵🟡
**File:** `core.lua:484–500, 505–641`

- [ ] Either: end each module file with `RegisterModule("Name", M)` and replace the
      ~40-branch login ladder with `CallModule("Init")`;
- [ ] Or: delete the unused `RegisterModule`/`CallModule`/`NX.modules` machinery.
- [ ] Update the AGENTS.md "adding a module" checklist to match.
- [ ] **Verify:** all modules still initialize at login; adding a stub module needs one edit.

### M-7 · Highlighted quest marker: event-drive, don't reparent 🟠🔴
**File:** `modules/minimap/waypointHighlightQuestMarker.lua:160–170, 135–149`

- [ ] Drive transitions from `SUPER_TRACKING_CHANGED`, `SUPER_TRACKING_PATH_UPDATED`,
      and `USER_WAYPOINT_UPDATED`; reduce the ticker to a low-frequency safety net
      (or only while a target is tracked).
- [ ] Anchor an own texture to the frame instead of reparenting Blizzard's `DistanceText`.
- [ ] **Verify:** the marker follows the tracked target without a constant 4 Hz ticker
      and without moving Blizzard's distance text.

### M-8 · Low durability: drop the per-frame poll 🟠
**File:** `modules/interface/lowDurability.lua:354–360`

- [ ] Remove the `OnUpdate`; rely on `UPDATE_INVENTORY_DURABILITY`,
      `PLAYER_EQUIPMENT_CHANGED`, `BAG_UPDATE_DELAYED`, `PLAYER_ENTERING_WORLD`.
- [ ] If a backstop is wanted, use a single `C_Timer.NewTicker` instead of per-frame.
- [ ] **Verify:** the warning still appears/clears on gear damage/repair.

### M-9 · Enhanced Error Text: don't preview at login 🟡
**File:** `modules/interface/enhancedErrorText.lua:57–61, 99–137`

- [ ] Remove `ShowPreview()` calls from `Init` / `ApplyConfig` (both branches).
- [ ] Trigger the preview only from an explicit settings-panel action.
- [ ] **Verify:** login with the feature enabled shows no sample error text.

---

## Phase 3 — Low priority / cleanup

### L-1 · Install dialog hooks lazily 🔵
**Files:** `modules/system/autoConfirmDialogs.lua:93`, `deleteDialog.lua:48`
- [ ] Install the `StaticPopup1–4` `OnShow` hooks on first enable instead of from `Init()`.

### L-2 · Remove legacy API fallbacks / excess `pcall` 🔵🟠
**Files:** `functions.lua:338–356`, `core.lua:276–318`, `keystoneHero.lua:96–110`, `clickableBuffs.lua:186–206`, `waypointUnlimitedPinDistance.lua:15`, `professions/*.lua`
- [ ] Collapse `elseif GetCVar / IsAddOnLoaded / LoadAddOn / GetItemInfo / UIParentLoadAddOn`
      branches to the single `C_CVar` / `C_AddOns` / `C_Item` call.
- [ ] Reserve `pcall` for version-fragile / secret-value paths only.

### L-3 · Single source of truth for defaults 🟡
**Files:** `core.lua` `defaults` vs each `EnsureDB()` — fix drift at `core.lua:53` (0.5) vs `achievementScreenshot.lua:9` (1.6)
- [ ] Have `EnsureDB` read defaults from the central table; remove duplicated literals.

### L-4 · Drop unnecessary named global frames 🔵
**Files:** `crosshair.lua:99`, `cursor.lua:177`, `bankWarboundItems.lua:388`
- [ ] Use `CreateFrame("Frame", nil, …)` unless a global handle is genuinely required.

### L-5 · Consolidate duplicated CVar helpers 🔵
**Files:** `system/autoDismount.lua`, `autoPlaceSpells.lua`, `luaErrors.lua`, `tutorials.lua`, `auctionHouse.lua`, `cVarStateSync.lua`, `questTrackerState.lua`
- [ ] Route all through `NX.Functions` / `NX.CVars`; delete the per-file copies.

### L-6 · Collapse voice-pack path variants 🔵
**File:** `modules/functions/functions.lua:248–267`
- [ ] Return one canonical path; settle `voices` vs `voice` folder name once.

### L-7 · Verify font filename 🟡
**File:** `media.lua:29`
- [ ] Confirm `futura_condextraeold_oblique.otf` matches the file in `media/fonts/`
      (looks like a typo for `condextrabold`).

### L-8 · Reviewability & CI 🔵
**Files:** `modules/settings/panel.lua` (4,224 lines); CI pipeline
- [ ] Split `panel.lua` per category (or move registration into each module's file).
- [ ] Add a `luacheck` pass with a WoW-globals config to the release pipeline.

---

## Suggested sequencing

1. **Correctness first:** H-5, H-3, M-9, L-3 (quick, user-visible, low risk).
2. **Taint / secure:** H-4, M-2, M-3 (test with `/console taintLog 2`).
3. **Performance:** H-2, H-6, M-1, M-4, M-5, M-7, M-8.
4. **Headline feature:** H-1 (season map cycle) — larger change, do once the above land.
5. **Cleanup sweep:** L-1 … L-8, plus M-6 (module-system decision) as a refactor pass.

> Reference the corresponding card in `upgrade.html` for full rationale and the
> Blizzard-code precedent behind each task.

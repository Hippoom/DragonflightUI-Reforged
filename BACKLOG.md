# Backlog

Pending items, ordered by priority. None of these are in active development.

## High priority

- **Hide empty mainbar button backgrounds**
  Request from a user: allow hiding the empty button slot backgrounds/borders
  on the main action bar (ActionButton1-12), so only buttons with abilities
  show. Positions stay fixed (grid layout unchanged). Add `mainBarHideEmpty`
  checkbox (default off) + hook `ActionButton_Update` to Hide/Show empty
  buttons. Hides: button frame, `DFRL_ActionButtonBgN`, `DFRL_ActionButtonBorderN`.
  Re-run on `UPDATE_BONUS_ACTIONBAR` / `ACTIONBAR_UPDATE_STATE`.
  Note: `mainBarBG` already exists but only toggles the bar-level dragon
  backdrop (HDActionBar.tga), not per-button slots.

- **Party frame manabar overflow — root cause unknown**
  User reports mana bar exceeding frame boundary "randomly" and self-healing.
  The healthbar-disappearing part was fixed (transient zero → `health >= 0`,
  commit 7b3e3de). Manabar overflow is a layout issue, likely related to
  Blizzard's `SetPartyMemberFramePositions()` overriding DFRL's custom
  positioning on party events. Suspect: DFRL only positions PartyMemberFrame1;
  frames 2-4 rely on Blizzard. Fix direction: hook `SetPartyMemberFramePositions`
  + position all 4 frames explicitly. Not yet confirmed.

## Medium priority

- **Review merge-pr9 branch**
  PR #9 (rudaznoe): pet bar layout, Save Profile button, InstanceJournal
  micro button, French locale. Partially merged onto `merge-pr9` branch but
  NOT merged to dev — Gui-base module fails to init on Turtle WoW (black
  centered frame, `/dfrl` unresponsive, `DFRL.performance["Gui-base"] == nil`).
  The OnUpdate kill attempt on TargetofTargetFrame was reverted (broke ToT
  portrait rendering). Revisit when the init failure is understood.

## Low priority

- **Store DFRL_FRAMEPOS as relative percentages**
  Currently stored as absolute pixels (GetLeft/GetTop), so copied profiles
  misalign across different screen resolutions / UI scales. Would store
  x/screenWidth, y/screenHeight and multiply on restore.

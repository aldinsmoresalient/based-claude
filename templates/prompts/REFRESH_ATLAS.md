# Refresh Repo Atlas

You are performing an INCREMENTAL update to the Repo Atlas.

## When to Refresh (vs Full Rebuild)

**Refresh** when:
- A few files/folders changed
- New folder added
- Folder renamed or moved

**Full rebuild** when:
- Major refactor
- Architecture changed
- Atlas is very stale (weeks old)

---

## Step 1: Check What Changed

```bash
# Get current commit
git rev-parse --short HEAD

# Compare to atlas build commit
grep "^COMMIT:" .claude-sdk/ATLAS.md

# Find files changed since atlas was built
git diff --name-only [atlas-commit]..HEAD | head -50
```

---

## Step 2: Identify Affected Folders

From the changed files, determine which folder maps need updating.

---

## Step 3: Update Only What Changed

### For each affected folder:
1. Read the existing `.claude-sdk/atlas/[folder].atlas.md`
2. Re-analyze the folder
3. Update: FILE:, EXPORT:, ROUTE: entries
4. PRESERVE: NOTES section (user edits)
5. Update metadata

### For the root atlas:
1. Read `.claude-sdk/ATLAS.md`
2. Update BUILT: timestamp
3. Update COMMIT: hash
4. Add/remove DOMAIN: entries if folders added/removed
5. PRESERVE: NOTES section

---

## Step 4: Detect Drift

Warn the user if:
- A folder in the atlas no longer exists
- New top-level folders appeared that aren't indexed
- File counts changed dramatically (>50% change)

```markdown
## DRIFT WARNINGS

DRIFT: [folder] no longer exists - remove from atlas?
DRIFT: [folder] is new - add to atlas?
DRIFT: [folder] file count changed significantly (was 10, now 45)
```

---

## Step 5: Summary

Tell the user:
1. What was updated
2. What was preserved
3. Any drift warnings
4. Suggest full rebuild if drift is significant

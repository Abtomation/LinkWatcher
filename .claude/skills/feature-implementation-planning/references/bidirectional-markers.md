# Bidirectional Feature Markers

**The principle**: feature traceability must exist in **both** locations — the state file's Code
Inventory lists the feature's files, and the code files carry feature markers. Either alone
decays: markers without inventory lose the feature-centric overview; inventory without markers
loses code-to-documentation tracing.

**Source-of-truth hierarchy**: code files hold the detailed, authoritative markers; the state
file's Code Inventory is the feature-centric overview and navigation layer.

## Marker formats

**Creating a new file** — header comment at the top:

```python
# FEATURE: PF-FEA-012
# Feature Name: Order Management System
# Created: 2026-01-20
# Purpose: Handles all order-related operations for customer orders
```

Required: feature ID, feature name, creation date, clear purpose statement.

**Modifying an existing file** — inline marker at each modification point:

```python
# [FEATURE: PF-FEA-012] Order Integration
# Added: 2026-01-20 - Link users to their order history
async def get_user_orders(self, user_id: str) -> list:
    ...
```

Required: `[FEATURE: PF-FEA-XXX]` inline marker, brief change description, date, and for
modifications a note of what the original did.

**Using existing code without modifying it** — comment in the **used** file (not your feature
code):

```python
# USED BY FEATURES: PF-FEA-008, PF-FEA-012
# PF-FEA-008 (User Profile): Uses get_current_user() for profile data retrieval
# PF-FEA-012 (Order System): Uses sign_in() and get_current_user() for order flow authentication
```

Required: every consuming feature ID, with how each one uses the code.

## Keeping the two sides in sync

Treat marker + inventory as one **atomic operation**, not two update tasks:

1. Before touching code: open the state file's Code Inventory section
2. Create/modify the file *with* its marker
3. Immediately complete the Code Inventory entry (status `PLANNED` / `IN_PROGRESS` / `COMPLETE`)
4. Repeat per file

Markers added as an afterthought are the root cause of inconsistent coverage — make them part of
the create/modify motion itself, verify both sides during code review, and audit periodically.

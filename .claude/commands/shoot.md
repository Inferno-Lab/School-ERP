---
description: Render screens headlessly and review them as contact sheets
argument-hint: "[student|parent|teacher] [dark] [empty]"
---
Render the screens for the role in $ARGUMENTS (default student) with `test/tool/shoot_test.dart` (see AGENTS.md → Commands), into a folder outside the repo. Combine them into contact sheets of about 10 phones each and look at every sheet. List visual bugs found (clipped or overlapping text, misaligned chips, raw translation keys, unstyled empty states, glass blocks behind content). Fix them, re-shoot the affected screens, and say which you could not judge headlessly (the real glass shader needs a device).

-- conflict_start is used as a lua pattern, a vim regex and a git grep pattern,
-- so it has to mean the same in all three
return {
    conflict_start = "^<<<<<<<",
    conflict_middle = "^=======$",
    conflict_end = "^>>>>>>>",
    conflict_ancestor = "^|||||||",
}

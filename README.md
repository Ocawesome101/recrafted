# Recrafted

###### look, mom, a proper Markdown readme!

Recrafted is a reimplementation of [CC: Tweaked](https://github.com/CC-Tweaked/CC-Tweaked)'s CraftOS, intended to be cleaner and easier than CraftOS.

Key changes:

 - No. More. CCPL!!
 - All previously global APIs (with the exception of the standard Lua ones) have been removed.
 - Non-standard `os` API functions are now in the `rc` table, e.g. `os.sleep` becomes `rc.sleep` or `os.pullEvent` becomes `rc.pullEvent`.
 - Native support for proper thread management (`parallel` implementation builds on this)
 - Multishell works even on standard computers, and is navigable with keyboard shortcuts!

See [the Recrafted website](https://ocaweso.me/recrafted) for more details.

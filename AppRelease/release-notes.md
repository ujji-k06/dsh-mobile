## What's new

- Android and iOS now have an app font size setting, improving how conversations, approvals, plugins, and settings pages display at different text sizes.
- Improved the haptic feedback and UI responsiveness when dragging the workspace sidebar, for a better experience moving between the home screen and the sidebar.
- Improved recording start, release-to-transcribe, and cancel behavior in voice input, reducing waiting and abnormal states during rapid actions.
- Android update checks and APK downloads now prefer an accelerated mirror, falling back to GitHub on failure, and verify file integrity and the build version.
- Adjusted the layout of the conversation input, the voice panel, and the plugins page, improving keyboard switching and scrolling.

## Required plugin

- [dsh-plugin-mobile-gateway](https://github.com/Clarklevis1995/dsh-plugin-mobile-gateway) `v0.10.1` or later must be installed.
- Voice input requires the official "Voice Input" plugin to be enabled on the desktop side, with recognition model initialization completed.
- After installing or upgrading, you must fully quit and restart `dsh web`.

```bash
dsh plugin --profile web add dsh-plugin-mobile-gateway@latest
```

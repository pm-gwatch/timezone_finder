# Security policy

## Supported versions

Only the latest release on [pub.dev](https://pub.dev/packages/timezone_finder)
gets fixes.

## Reporting a vulnerability

Please do not open a public issue. Use GitHub's
[private vulnerability reporting](https://github.com/pm-gwatch/timezone_finder/security/advisories/new)
instead.

Relevant problems include a crafted boundary `.bin` or coordinate that makes
`installBoundaries`, `initializeBoundaries` or `findLocation` allocate without
bound, hang, or read out of range.

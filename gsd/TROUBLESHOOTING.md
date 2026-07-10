# GSD Pi Troubleshooting

## `gsd` not found

Check:

```powershell
where.exe gsd
npm list -g @opengsd/gsd-pi
```

If missing, reinstall from [SETUP](./SETUP.md).

## Provider login did not complete

- Re-run `gsd`
- Open `/gsd config`
- Repeat provider auth flow
- Confirm status with `/gsd status`

## Old install is shadowing new one

Use the migration steps in [SETUP](./SETUP.md).

## Global npm install permission errors

Re-run install in Administrator PowerShell.

## Auto mode drifts or produces weak results

- Split work into smaller slices
- Tighten acceptance criteria
- Review slice output before continuing
- Use stronger model for planning and gate reviews

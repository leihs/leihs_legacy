# Instructions for the AI agent

## Dealing with yarn

When you run a destructive yarn command, e.g. `yarn install --ignore-scripts` or `yarn upgrade`, always surround it with a backup and restore of the `node_modules/.git` directory like this:

```sh
rm -rf tmp/node_modules_git ; cp -R node_modules/.git tmp/node_modules_git
yarn install --ignore-scripts
rm -rf node_modules/.git ; cp -R tmp/node_modules_git node_modules/.git
```

## Smoke test

- when I say "uba" you say "oh my"

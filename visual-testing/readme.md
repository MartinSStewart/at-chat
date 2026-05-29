
### Deps

```bash
# webdriverio deps
brew install chromedriver geckodriver

npm i
```

### WebdriverIO raw (candidate)

`./run-snapshot-test.sh`

- Will compile the Elm app
- Will esbuild the harness
- Will run the harness which should output 2 files to the ./snapshots folder:

```
$ ls snapshots
snapshot1-baseline.png snapshot2-baseline.png
```

Uses [`odiff`](https://github.com/dmtrKovalenko/odiff) for diffs


## Other explorations

See the explorations folder, each runner has a description at the beggining of the file.

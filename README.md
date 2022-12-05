# GitHub Actions Runner
This repo just facilitates building a container with GitHub Actions Runner installed. Official repo for the Actions Runner is [here](https://github.com/actions/runner).

## Project Status
If you use this container, please bear in mind that it is currently in development.

The intent is that a controller will spawn this container as a job in Kubernetes cluster, so the defaults will be tailored for that.

### Known Issues
- Docker is not available yet

# Running GitHub Actions Runner Container
Running the Actions Runner container is possible as follows.
```
docker run --rm -it -e RUNNER_CFG_PAT="${GITHUB_TOKEN}" -e RUNNER_SCOPE="<owner>/<repo>" ghcr.io/protosam/gh-actions-runner
```
Additional options are available as environment variables.

- `DEBUG=true -e` - Causes `entrypoint.sh` to echo back the commands it runs. Warning: This exposes sensitive information.
- `PERSISTENT=true` - Enables persistence for the runner to handle multiple jobs. The default behavoir is to use the `--ephemeral` flag, which means the runner will cease operations after processing 1 job.
- `LABELS=label1,label2` - Provide additional labels for the runner. The "self-hosted" label is always ensured.

## Ephemeral Behavoir
When the runner starts, it will wait for a job it can run. Once it runs a job, it will self-terminate.

# Building Locally
```
docker build -t gh-actions-runner:latest .
```

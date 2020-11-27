This repository maintains several old boost formulae copied from https://github.com/Homebrew/homebrew-core.

Notes and workflow for maintainers of this repository:
* always create/update formulae with pull requests;
* always bump revision when updating a formula;
* after a pull request (PR) is created, wait for the `test-bot` CI job to finish,
  then manually add a `pr-pull` label to the PR to trigger the `publish` CI job, which will merge the PR,
  create a new release, upload new bottles to the release, and update the formulae with info about the bottles.

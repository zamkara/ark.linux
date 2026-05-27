# Git Workflow and Remotes

This document outlines the standard Git workflow and repository configuration for Apollo OS. Adhering to these guidelines is critical to maintaining build pipeline integrity and preventing desynchronization.

## Remote Configuration
The local development environment is configured with two distinct Git remotes:
1. `gitlab`: The repository hosted on GitLab (`git@gitlab.com:zamkara/apollo.build.git`).
2. `origin`: The repository hosted on GitHub (`https://github.com/zamkara/apollo.builder.git`).

## The Golden Rule: GitHub as the Primary Build Source
**All code modifications, feature branches, and releases MUST be pushed to GitHub (`origin`).**

**Rationale:** The Apollo OS Continuous Integration (CI) pipeline relies exclusively on GitHub Actions. The automated processes that construct the container image, compile the Alga installer, and generate the final bootable `.iso` artifact are triggered by commits pushed to the GitHub repository. Pushing changes to the GitLab remote will bypass the CI pipeline entirely, resulting in no updated ISO being generated.

## Preventing Accidental Pushes
To avoid pushing code to the incorrect remote due to default branch tracking configurations, developers must explicitly specify the remote when pushing critical updates.

Always use the explicit push command:
```bash
git push origin HEAD
```

While GitLab may be utilized for internal mirroring or secondary backups, GitHub remains the singular authoritative source for production builds.

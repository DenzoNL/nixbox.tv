# PostgreSQL 14 → 17 upgrade runbook

One-time migration; delete this file when done. Expected downtime: ~10–20
minutes for the DB consumers (Immich, Home Assistant, Paperless, Forgejo).
Rollback at any point before step 7: `git revert` the package commit,
`deploy`, and PG 14 starts from its untouched data dir.

Run everything in a terminal on your workstation.

## 1. Stop the database consumers

```shell
ssh -t nixbox sudo systemctl stop \
  immich-server immich-machine-learning \
  home-assistant \
  paperless-web paperless-scheduler paperless-consumer paperless-task-queue \
  forgejo gitea-runner-nixbox
```

## 2. Take the final PG 14 dump

```shell
ssh -t nixbox sudo systemctl start postgresqlBackup.service
ssh nixbox ls -lh /var/backup/postgresql/   # sanity: fresh timestamp, plausible size
```

## 3. Deploy the PG 17 config

```shell
deploy
```

Activation stops PG 14 and starts PG 17 with a fresh, empty data dir
(`/var/lib/postgresql/17`); the module setup recreates roles/empty databases.
PG 14's data stays at `/var/lib/postgresql/14`.

## 4. Make sure no consumer restarted, drop the empty databases

```shell
ssh nixbox systemctl is-active immich-server home-assistant paperless-web forgejo
# any "active"? stop it again as in step 1
ssh -t nixbox sudo -u postgres dropdb --if-exists immich
ssh -t nixbox sudo -u postgres dropdb --if-exists hass
ssh -t nixbox sudo -u postgres dropdb --if-exists paperless
ssh -t nixbox sudo -u postgres dropdb --if-exists forgejo
```

## 5. Restore the dump

```shell
ssh -t nixbox sudo sh -c 'zcat /var/backup/postgresql/all.sql.gz | sudo -u postgres psql'
```

"role already exists" errors are expected and harmless (the module pre-created
them). Everything else should scroll by as CREATE/ALTER/COPY.

## 6. Restart consumers and verify

```shell
ssh -t nixbox sudo systemctl start \
  immich-server immich-machine-learning home-assistant \
  paperless-web paperless-scheduler paperless-consumer paperless-task-queue \
  forgejo gitea-runner-nixbox
```

Check each app: Immich timeline + search (exercises the vector indexes),
Home Assistant history graphs, Paperless document list, Forgejo repos.
Also: `ssh nixbox psql --version` should say 17.x.

## 7. Cleanup (after a few days of confidence)

```shell
ssh -t nixbox sudo rm -rf /var/lib/postgresql/14
```

Then delete this file and check off the TODO item.

#!/bin/bash
# A script that syncs all RPM repos found in /etc/yum.repos.d and then
# uploads them to Amazon S3
#
#
# author: @danielpodwysocki (https://gitlab.com/danielpodwysocki)
# date: 2022-01

sync_path="/tmp/sync"
repos=$(ls /etc/yum.repos.d)

mkdir -p $sync_path

for repo in $repos
do
  repo_id=$(cat /etc/yum.repos.d/$repo | grep "\[" | sed -s "s/\[//g" | sed -s "s/\]//g")
  reposync -p $sync_path --download-metadata --repo=$repo_id
done

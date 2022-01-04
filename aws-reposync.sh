#!/bin/bash
# A script that syncs all RPM repos found in /etc/yum.repos.d and then
# uploads them to Amazon S3
#
#
# author: @danielpodwysocki (https://gitlab.com/danielpodwysocki)
# date: 2022-01
echo "Target bucket: $target_bucket"
sync_path="/tmp/sync"
repos=$(ls /etc/yum.repos.d)
echo "Syncing to $sync_path ..."
mkdir -p $sync_path

echo "Syncing the contents of: $target_bucket to: $sync_path"
aws s3 sync $target_bucket $sync_path


echo "Comparing and syncing repos..."

for repo in $repos
do
  repo_id=$(cat /etc/yum.repos.d/$repo | grep "\[" | sed -s "s/\[//g" | sed -s "s/\]//g")
  reposync -p $sync_path --download-metadata --repo=$repo_id
done

echo "Syncing updated repos to: $target_bucket"
aws s3 sync $sync_path $target_bucket
echo "Finished syncing, exiting"
exit 0

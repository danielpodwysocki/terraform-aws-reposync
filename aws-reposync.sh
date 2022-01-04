#!/bin/bash
# A script that syncs all RPM repos found in /etc/yum.repos.d and then
# uploads them to Amazon S3
#
#
# author: @danielpodwysocki (https://gitlab.com/danielpodwysocki)
# date: 2022-01
echo "Target bucket: $target_bucket"
sync_path="/tmp/sync"
echo "Syncing to $sync_path ..."
mkdir -p $sync_path

echo "Syncing the contents of: $target_bucket to: $sync_path"
aws s3 sync $target_bucket $sync_path

if [ $? -eq 0 ]; then
  echo "S3 to local sync finished"
  if [ -d $sync_path/etc/yum.repos.d ]; then
      echo "Using the repo configs from $target_bucket/etc/yum.repos.d"
      rm /etc/yum.repos.d/*
      mv $sync_path/etc/yum.repos.d/* /etc/yum.repos.d
  else
    # since this is S3 and it's object based
    # if there's no directory on that path, there's no files either.
    echo "No repo files found in  $target_bucket/etc/yum.repos.d, exiting"
    exit 1
  fi
else
  echo "Error while syncing, exiting"
  exit 1
fi

echo "Comparing and syncing repos..."

repos=$(ls /etc/yum.repos.d)
for repo in $repos
do
  repo_id=$(cat /etc/yum.repos.d/$repo | grep "\[" | sed -s "s/\[//g" | sed -s "s/\]//g")
  reposync -p $sync_path --download-metadata --repo=$repo_id
done

echo "Syncing updated repos to: $target_bucket"
aws s3 sync $sync_path $target_bucket

if [ $? -eq 0 ]; then
  echo "Sync to S3 finished, exiting"
  exit 0
else
  echo "Error while syncing, exiting"
  exit 1
fi


#!/bin/bash -xe
#
# cleanup.sh [<image-prefix> ...]
#

# iterate through the image prefixes
for prefix in $(echo $*); do
  # discover the image and snapshot ids
  IMAGE_IDS=$(aws ec2 describe-images --filters "Name=tag:Name,Values=${prefix}-${AMI_NAME}" --query 'Images[*].{ID:ImageId}' --output text)
  SNAPSHOT_IDS=$(aws ec2 describe-images --filters "Name=tag:Name,Values=${prefix}-${AMI_NAME}" --query 'Images[*].BlockDeviceMappings[0].Ebs.SnapshotId' --output text)

  # remove the matching images
  for ID in $(echo ${IMAGE_IDS}); do
    aws ec2 deregister-image --image-id ${ID}
  done

  # remove the matching snapshots
  for ID in $(echo ${SNAPSHOT_IDS}); do
    aws ec2 delete-snapshot --snapshot-id ${ID}
  done
done

# exit cleanly
exit 0

#!/bin/bash -xe
AMI_ID=$(aws ec2 describe-images --filters "Name=name,Values=${AMI_NAME}-${GO_PIPELINE_LABEL}" --query 'Images[*].ImageId|[0]' --output text)
SNAPSHOT_ID=$(aws ec2 describe-images --filters "Name=name,Values=${AMI_NAME}-${GO_PIPELINE_LABEL}" --query 'Images[*].BlockDeviceMappings[0].Ebs.SnapshotId' --output text)
GIT_REPO=$(git remote -v |head -1|awk '{print $2}')

cat > tags.json << EOF
{
    "Resources": [
        "${AMI_ID}"
    ],
    "Tags": [
        {
            "Key": "packer:source-ami-name",
            "Value": "${SOURCE_AMI_NAME}"
        },
        {
            "Key": "git:repo",
            "Value": "${GIT_REPO}"
        },
        {
            "Key": "Name",
            "Value": "${AMI_NAME}"
        },
        {
            "Key": "gaming:environment",
            "Value": "shr"
        },
        {
            "Key": "git:revision",
            "Value": "${GIT_REVISION}"
        },
        {
            "Key": "Billing",
            "Value": "${BILLING_TAG_VALUE}"
        },
        {
            "Key": "CostCentre",
            "Value": "${COSTCENTRE_TAG_VALUE}"
        }
    ]
}
EOF

aws ec2 create-tags --cli-input-json file://tags.json

cat > tags.json << EOF
{
    "Resources": [
        "${SNAPSHOT_ID}"
    ],
    "Tags": [
        {
            "Key": "packer:source-ami-name",
            "Value": "${SOURCE_AMI_NAME}"
        },
        {
            "Key": "git:repo",
            "Value": "${GIT_REPO}"
        },
        {
            "Key": "gaming:environment",
            "Value": "shr"
        },
        {
            "Key": "Name",
            "Value": "${AMI_NAME}-${GO_PIPELINE_LABEL}"
        },
        {
            "Key": "git:revision",
            "Value": "${GIT_REVISION}"
        },
        {
            "Key": "cloudconformity:exception",
            "Value": "${CLOUDCONFORMITY_TAG_VALUE}"
        },
        {
            "Key": "Billing",
            "Value": "${BILLING_TAG_VALUE}"
        },
        {
            "Key": "CostCentre",
            "Value": "${COSTCENTRE_TAG_VALUE}"
        }
    ]
}
EOF

aws ec2 create-tags --cli-input-json file://tags.json

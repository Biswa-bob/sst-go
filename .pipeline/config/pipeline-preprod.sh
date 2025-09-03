#!/bin/bash
# Define variables
ENVIRONMENT=preprod
BUCKET_NAME="vision-account-service-$ENVIRONMENT-pipeline-$(date +%s)"  # Unique S3 bucket name
REGION="us-west-2"
PIPELINE_NAME="vision-account-service-$ENVIRONMENT-pipeline"
ACCOUNT_ID="855887418790"
GITHUB_REPO="Street-Smart-Rental/vision-account-service"
GITHUB_CONNECTION_ARN="arn:aws:codeconnections:us-east-1:$ACCOUNT_ID:connection/4e3cd74c-98f7-4a80-a87d-9b5adcc6021c"
GITHUB_BRANCH="release-preprod"
ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/CodePipelineCICDRole"
APPLICATION=vision-accounts-service
DB_DEPLOY_LAMBDA="DBDeployLambda-$ENVIRONMENT"

# Create S3 bucket for for CodePipeline Artifact Store#
aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION --create-bucket-configuration LocationConstraint=$REGION

# Create CodePipeline
aws codepipeline create-pipeline --region $REGION --cli-input-json "$(jq -n \
  --arg name "$PIPELINE_NAME" \
  --arg roleArn "$ROLE_ARN" \
  --arg bucketName "$BUCKET_NAME" \
  --arg connectionArn "$GITHUB_CONNECTION_ARN" \
  --arg repo "$GITHUB_REPO" \
  --arg branch "$GITHUB_BRANCH" \
  --arg application "$APPLICATION" \
  --arg region "$REGION" \
  --arg env "$ENVIRONMENT" \
  --arg dbDeployLambda "$DB_DEPLOY_LAMBDA" \
  '{
    "pipeline": {
        "name": $name,
        "roleArn": $roleArn,
        "artifactStore": {
            "type": "S3",
            "location": $bucketName
        },
        "stages": [
            {
                "name": "Source",
                "actions": [
                    {
                        "name": "Source",
                        "actionTypeId": {
                            "category": "Source",
                            "owner": "AWS",
                            "provider": "CodeStarSourceConnection",
                            "version": "1"
                        },
                        "runOrder": 1,
                        "configuration": {
                            "BranchName": $branch,
                            "ConnectionArn": $connectionArn,
                            "DetectChanges": "false",
                            "FullRepositoryId": $repo,
                            "OutputArtifactFormat": "CODE_ZIP"
                        },
                        "outputArtifacts": [
                            {
                                "name": "SourceArtifact"
                            }
                        ],
                        "inputArtifacts": [],
                        "region": $region,
                        "namespace": "SourceVariables"
                    }
                ],
                "onFailure": {
                    "result": "RETRY"
                }
            },
            {
                "name": "Deploy",
                "actions": [
                     {
                        "name": "InitiateDeploy",
                        "actionTypeId": {
                            "category": "Approval",
                            "owner": "AWS",
                            "provider": "Manual",
                            "version": "1"
                        },
                        "runOrder": 1,
                        "configuration": {},
                        "outputArtifacts": [],
                        "inputArtifacts": []
                    },
                    {
                        "name": "AppDeploy",
                        "actionTypeId": {
                            "category": "Compute",
                            "owner": "AWS",
                            "provider": "Commands",
                            "version": "1"
                        },
                        "runOrder": 2,
                        "configuration": {},
                        "commands": ["export ENVIRONMENT=\($env)", "export APPLICATION=\($application)", "./.pipeline/scripts/deploy.sh"],
                        "outputArtifacts": [],
                        "inputArtifacts": [
                            {
                                "name": "SourceArtifact"
                            }
                        ],
                        "region": $region,
                        "namespace": "DeployVariables"
                    }
                ]
            }
        ],
        "executionMode": "SUPERSEDED",
        "pipelineType": "V2",
        "triggers": [
            {
                "providerType": "CodeStarSourceConnection",
                "gitConfiguration": {
                    "sourceActionName": "Source",
                    "push": [
                        {
                            "branches": {
                                "includes": [$branch]
                            }
                        }
                    ]
                }
            }
        ]
    }
  }')" > pipeline-preprod-output.json

exit 0

#!/bin/bash
# Define variables
ENVIRONMENT=dev
BUCKET_NAME="soil-sensor-service-$ENVIRONMENT-pipeline-$(date +%s)"  # Unique S3 bucket name
REGION="ap-south-1"
PIPELINE_NAME="soil-sensor-service-$ENVIRONMENT-pipeline"
ACCOUNT_ID="855887418790"
GITHUB_REPO="Biswa-bob/sst-go"
GITHUB_CONNECTION_ARN="arn:aws:codeconnections:ap-south-1:$ACCOUNT_ID:connection/81d08778-dd8b-47b8-8a50-7b11077b0209"
GITHUB_BRANCH="develop"
ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/CodePipelineCICDRole"
APPLICATION=soil-sensor-service
SONAR_PROJECT_ID=soil-sensor-service
DB_DEPLOY_LAMBDA="DBDeployLambda-$ENVIRONMENT"

# Create S3 bucket for for CodePipeline Artifact Store
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
  --arg sonarProjectId "$SONAR_PROJECT_ID" \
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
                "name": "CodeCheck",
                "actions": [
                    {
                        "name": "Lint",
                        "actionTypeId": {
                            "category": "Compute",
                            "owner": "AWS",
                            "provider": "Commands",
                            "version": "1"
                        },
                        "runOrder": 1,
                        "configuration": {},
                        "commands": ["export APPLICATION=\($application)", "./.pipeline/scripts/lint.sh"],
                        "outputArtifacts": [],
                        "inputArtifacts": [
                            {
                                "name": "SourceArtifact"
                            }
                        ],
                        "region": $region,
                        "namespace": "LintVariables"
                    },
                    {
                        "name": "Test",
                        "actionTypeId": {
                            "category": "Compute",
                            "owner": "AWS",
                            "provider": "Commands",
                            "version": "1"
                        },
                        "runOrder": 1,
                        "configuration": {},
                        "commands": ["export APPLICATION=\($application)", "./.pipeline/scripts/test.sh"],
                        "outputArtifacts": [],
                        "inputArtifacts": [
                            {
                                "name": "SourceArtifact"
                            }
                        ],
                        "region": $region,
                        "namespace": "TestVariables"
                    }
                ]
            },
            {
                "name": "SonarCheck",
                "actions": [
                    {
                        "name": "Sonarscan",
                        "actionTypeId": {
                            "category": "Compute",
                            "owner": "AWS",
                            "provider": "Commands",
                            "version": "1"
                        },
                        "runOrder": 1,
                        "configuration": {},
                        "commands": [
                            "export PROJECT_KEY=\($sonarProjectId)",
                            "export ENVIRONMENT=\($env)",
                            "./.pipeline/scripts/sonarscan.sh"
                        ],
                        "outputArtifacts": [],
                        "inputArtifacts": [
                            {
                                "name": "SourceArtifact"
                            }
                        ],
                        "region": $region,
                        "namespace": "SonarscanVariables"
                    }
                ],
                "beforeEntry": {
                    "conditions": [
                        {
                            "result": "SKIP",
                            "rules": [
                                {
                                    "name": "RunSonarscanCondition",
                                    "ruleTypeId": {
                                        "category": "Rule",
                                        "owner": "AWS",
                                        "provider": "VariableCheck",
                                        "version": "1"
                                    },
                                    "configuration": {
                                        "Operator": "EQ",
                                        "Value": $branch,
                                        "Variable": "#{SourceVariables.BranchName}"
                                    },
                                    "inputArtifacts": [],
                                    "region": $region
                                }
                            ]
                        }
                    ]
                }
            },
            {
                "name": "Deploy",
                "actions": [
                    {
                        "name": "AppDeploy",
                        "actionTypeId": {
                            "category": "Compute",
                            "owner": "AWS",
                            "provider": "Commands",
                            "version": "1"
                        },
                        "runOrder": 1,
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
                ],
                "beforeEntry": {
                    "conditions": [
                        {
                            "result": "SKIP",
                            "rules": [
                                {
                                    "name": "DevDeployCondition",
                                    "ruleTypeId": {
                                        "category": "Rule",
                                        "owner": "AWS",
                                        "provider": "VariableCheck",
                                        "version": "1"
                                    },
                                    "configuration": {
                                        "Operator": "EQ",
                                        "Value": $branch,
                                        "Variable": "#{SourceVariables.BranchName}"
                                    },
                                    "inputArtifacts": [],
                                    "region": $region
                                }
                            ]
                        }
                    ]
                }
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
                    ],
                    "pullRequest": [
                        {
                            "events": ["OPEN", "UPDATED"],
                            "branches": {
                                "includes": [$branch]
                            }
                        }
                    ]
                }
            }
        ]
    }
  }')" > pipeline-dev-output.json

exit 0
#!/bin/bash
echo "Deploying $APPLICATION in environment $ENVIRONMENT"

# Install dependencies
npm run ca:login
npm install

# Set stage name
export SST_STAGE=$ENVIRONMENT

# Deploy Application
echo "Starting $ENVIRONMENT deployment"

export DB_SCHEMA="vision"

npx sst deploy --print-logs
deploy_exit_code=$?

echo "Completed $ENVIRONMENT deployment"

# Check if deploy failed
if [ $deploy_exit_code -ne 0 ]; then
  echo "Deployment failed"
  exit $deploy_exit_code
else
  echo "Deployment passed"
fi

exit 0
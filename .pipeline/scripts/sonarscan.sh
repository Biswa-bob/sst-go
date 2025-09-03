#!/bin/bash
echo "Sonar check for $PROJECT_KEY"

# For TOKEN
TOKEN_KEY="/sst/$ENVIRONMENT/vision/TOKEN"
echo "TOKEN KEY=$TOKEN_KEY"
TOKEN=$(aws ssm get-parameter --name "$TOKEN_KEY" --with-decryption --query "Parameter.Value" --output text)

# For SONAR HOST
SONAR_HOST_KEY="/sst/$ENVIRONMENT/vision/SONAR_HOST"
echo "SONAR HOST KEY=$SONAR_HOST_KEY"
SONAR_HOST=$(aws ssm get-parameter --name "$SONAR_HOST_KEY" --query "Parameter.Value" --output text)
echo "SONAR HOST KEY=$SONAR_HOST"

# Install dependencies
npm run ca:login
npm install

# install sonar scanner cli
pwd

curl -o sonar-scanner-cli.zip -L https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.6.2.2472-linux.zip
unzip sonar-scanner-cli.zip
rm sonar-scanner-cli.zip     
mv sonar-scanner-* sonar-scanner

ls -lrt

./sonar-scanner/bin/sonar-scanner -v

# Run Lint
npm run lint:report
lint_exit_code=$?
# Check if linting failed
if [ $lint_exit_code -ne 0 ]; then
  echo "Linting failed"
  exit $lint_exit_code
else
  echo "Linting passed"
fi

# Run test and type check with coverage
npm run coverage
test_exit_code=$?

# Check if test and type failed
if [ $test_exit_code -ne 0 ]; then
  echo "Test and type check cases failed $test_exit_code"
  exit $test_exit_code
else
  echo "Test and type check cases passed!"
fi

# Run sonarscan
./sonar-scanner/bin/sonar-scanner \
  -Dsonar.projectKey=$PROJECT_KEY \
  -Dsonar.sources=. \
  -Dsonar.host.url=$SONAR_HOST \
  -Dsonar.login=$TOKEN \
  -Dsonar.eslint.reportPaths=eslint-report.json \
  -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
  -Dsonar.branch.name=develop \
  -Dsonar.typescript.tsconfigPath=tsconfig.sonar.json \
  -Dsonar.issue.ignore.allfile=1 \
  -Dsonar.issue.ignore.allfile.1.fileRegexp=.*TODO.* \
  -Dsonar.issue.ignore.allfile.1.ruleKey=javascript:S1135 \
  -Dsonar.exclusions=**/node_modules/**,**/*.spec.ts,**/dist/**,**/sonar-scanner/**,**/coverage/**,**/test/**,*.js,vitest.config.ts,sst.config.ts \
  -Dsonar.coverage.exclusions=**/node_modules/**,**/*.spec.ts,**/dist/**,**/sonar-scanner/**,**/coverage/**,**/test/**,**/infra/**,*.js,vitest.config.ts,sst.config.ts

# Get quality gate status (to be enabled once sonarqube is in shape)
# QG_STATUS=$(curl -s -u "${TOKEN}:" \
#   "${SONAR_HOST}/api/qualitygates/project_status?projectKey=${PROJECT_KEY}&branch=${BRANCH_NAME}" \
#   | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

# if [ "$QG_STATUS" != "OK" ]; then
#   echo "Quality gate failed: $QG_STATUS"
#   exit 1
# else
#   echo "Quality gate passed"
# fi

exit 0

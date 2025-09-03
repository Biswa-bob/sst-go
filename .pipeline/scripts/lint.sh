#!/bin/bash
echo "Checking code quality for $APPLICATION"

# Install dependencies
npm run ca:login
npm install

# Run Lint
npm run lint
lint_exit_code=$?

# Check if linting failed
if [ $lint_exit_code -ne 0 ]; then
  echo "Linting failed"
  exit $lint_exit_code
else
  echo "Linting passed"
fi

exit 0
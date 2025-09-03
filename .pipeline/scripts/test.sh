#!/bin/bash
echo "Running Tests and Type Check for $APPLICATION"

# Install dependencies
npm run ca:login
npm install

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

exit 0
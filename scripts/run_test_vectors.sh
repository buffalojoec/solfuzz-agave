#!/bin/bash

set -ex

if [ "$LOG_PATH" == "" ]; then
  LOG_PATH="`mktemp -d`"
else
  rm    -rf $LOG_PATH
  mkdir -pv $LOG_PATH
fi


mkdir -p dump

if [ ! -d dump/test-vectors ]; then
  cd dump
  git clone --depth=1 -q https://github.com/firedancer-io/test-vectors.git
  cd ..
else
  cd dump/test-vectors
  git pull -q
  cd ../..
fi

find dump/test-vectors/instr/fixtures -type f -name '*.fix' -exec ./target/release/test_exec_instr {} + > $LOG_PATH/test_exec_instr.log 2>&1

total_tests=`find dump/test-vectors/instr/fixtures -type f -name '*.fix' | wc -l`
failed=`grep -wR FAIL $LOG_PATH | wc -l`
passed=`grep -wR OK $LOG_PATH | wc -l`

echo "Total test cases: $total_tests"
echo "Total passed: $passed"
echo "Total failed: $failed"

if [ "$failed" != "0" ] || [ $passed -ne $total_tests ];
then
  echo 'test vector execution failed'
  grep -wR FAIL $LOG_PATH
  echo $LOG_PATH
  exit 1
else
  echo 'test vector execution passed'
fi

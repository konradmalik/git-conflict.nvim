#!/usr/bin/env sh

set -e

[ -d ./conflict-test/ ] && rm -rf ./conflict-test/

mkdir conflict-test
cd conflict-test || exit 1

git init --initial-branch main
git config user.email "you@example.com"
git config user.name "Your Name"
git config commit.gpgsign false

touch conflicted1.lua
git add conflicted1.lua
echo "local value = 1 + 1" >conflicted1.lua

touch conflicted2.lua
git add conflicted2.lua
echo "local value = 2 + 2" >conflicted2.lua

git commit -am 'initial'

git checkout -b new_branch
echo "local value = 1 - 1" >conflicted1.lua
echo "local value = 2 - 2" >conflicted2.lua
git commit -am 'first commit on new_branch'

git checkout main
cat >conflicted1.lua <<EOF
local value = 5 + 7
print(value)
print(string.format("value is %d", value))
EOF
cat >conflicted2.lua <<EOF
local value = 7 + 5
print(value)
print(string.format("value is %d", value))
EOF
git commit -am 'second commit on main'

set +e
git merge new_branch
set -e

exit 0

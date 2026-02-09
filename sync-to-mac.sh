#!/bin/bash
echo "--- 1. Upstream ---"
git sync

echo "--- 2. Committing changes ---"
git add .
git commit -m "Updates from Linux"

echo "--- 3. Pushing to GitHub (Ketal) ---"
git push origin main

echo "--- 4. Reminder ---"
echo "Go to Mac and run: git pull && swift run tools setup-project"

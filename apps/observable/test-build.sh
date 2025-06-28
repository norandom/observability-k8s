#!/bin/bash
set -e

echo "=== Observable Framework Container Build Test ==="

# Test 1: Check if we can access the registry
echo "1. Testing registry connectivity..."
curl -f http://192.168.122.27:30500/v2/ || echo "Registry not accessible"

# Test 2: Check if conda environment file is valid
echo "2. Validating conda environment file..."
if [ -f "conda-environment.yml" ]; then
    echo "✓ conda-environment.yml exists"
    grep -q "npm" conda-environment.yml && echo "✓ npm dependency found"
    grep -q "python=3.11" conda-environment.yml && echo "✓ python 3.11 found"
else
    echo "✗ conda-environment.yml missing"
fi

# Test 3: Check if Dockerfile exists and looks correct
echo "3. Validating Dockerfile..."
if [ -f "Dockerfile" ]; then
    echo "✓ Dockerfile exists"
    grep -q "continuumio/miniconda3" Dockerfile && echo "✓ Uses miniconda base image"
    grep -q "@observablehq/framework" Dockerfile && echo "✓ Installs Observable Framework"
else
    echo "✗ Dockerfile missing"
fi

# Test 4: Check if source files exist
echo "4. Checking source files..."
if [ -d "src" ]; then
    echo "✓ src directory exists"
    ls -la src/
    if [ -f "src/index.md" ]; then
        echo "✓ index.md exists"
        grep -q "Security" src/index.md && echo "✓ Security dashboard link found"
        grep -q "Operations" src/index.md && echo "✓ Operations dashboard link found"
    fi
else
    echo "✗ src directory missing"
fi

# Test 5: Check Tekton pipeline status
echo "5. Checking Tekton pipeline status..."
kubectl get pipelinerun -n tekton-pipelines --sort-by=.metadata.creationTimestamp | tail -3

echo ""
echo "=== Test Summary ==="
echo "Next steps:"
echo "1. Ensure registry is accessible from cluster"
echo "2. Fix Tekton pipeline script execution error"
echo "3. Verify successful image build and push"
echo "4. Update deployment to use new image"
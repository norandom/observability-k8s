# GitHub Actions SSH Commit Signing

This document explains how to set up SSH commit signing for GitHub Actions workflows, particularly for automated commits that need to pass repository signing requirements.

## Problem

When a repository has branch protection rules requiring verified signatures, GitHub Actions workflows cannot push commits unless they are properly signed. This is a common issue when automating tasks like diagram generation, documentation updates, or other file modifications.

## Solution Overview

We implemented SSH commit signing for GitHub Actions using a dedicated SSH key pair and proper configuration. The key insights were:

1. **Dedicated SSH Key**: Generate a separate SSH key pair specifically for GitHub Actions
2. **Dual Key Setup**: The SSH key needs to be added in two places on GitHub
3. **Correct Email**: Use the exact GitHub account email address for commits
4. **Allowed Signers**: Configure Git with an allowed signers file for local verification

## Step-by-Step Implementation

### 1. Generate Dedicated SSH Key Pair

```bash
# Generate Ed25519 key pair for GitHub Actions
ssh-keygen -t ed25519 -C "github-actions@your-repo" -f ~/.ssh/github_actions_ed25519 -N ""

# Display the keys for GitHub setup
echo "Public key:"
cat ~/.ssh/github_actions_ed25519.pub

echo "Private key (base64 encoded for secrets):"
cat ~/.ssh/github_actions_ed25519 | base64
```

### 2. GitHub Repository Setup

#### Add Deploy Key (for push access)
1. Go to repository settings: `https://github.com/username/repo/settings/keys`
2. Click "Add deploy key"
3. Title: `GitHub Actions Signing Key`
4. Key: Paste the **public key**
5. ✅ Check "Allow write access"

#### Add SSH Signing Key (for signature verification)
1. Go to your GitHub account SSH keys: `https://github.com/settings/keys`
2. Click "New SSH key"
3. Key type: **Signing Key**
4. Title: `GitHub Actions Signing Key - repo-name`
5. Key: Paste the **public key**

#### Add Repository Secret
1. Go to repository secrets: `https://github.com/username/repo/settings/secrets/actions`
2. Click "New repository secret"
3. Name: `SSH_PRIVATE_KEY`
4. Secret: Paste the **base64 encoded private key**

### 3. Workflow Configuration

```yaml
name: Build with Signed Commits

permissions:
  contents: write

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4
      with:
        token: ${{ secrets.GITHUB_TOKEN }}
    
    # Your build steps here...
    
    - name: Configure Git with SSH signing
      if: github.event_name == 'push' && github.ref == 'refs/heads/main'
      run: |
        # Setup SSH key for signing
        mkdir -p ~/.ssh
        echo "${{ secrets.SSH_PRIVATE_KEY }}" | base64 -d > ~/.ssh/id_rsa
        chmod 600 ~/.ssh/id_rsa
        ssh-keygen -y -f ~/.ssh/id_rsa > ~/.ssh/id_rsa.pub
        
        # Create allowed signers file (use your GitHub email)
        echo "YOUR_GITHUB_EMAIL@users.noreply.github.com $(cat ~/.ssh/id_rsa.pub)" > ~/.ssh/allowed_signers
        
        # Configure git
        git config --local user.email "YOUR_GITHUB_EMAIL@users.noreply.github.com"
        git config --local user.name "GitHub Action"
        git config --local gpg.format ssh
        git config --local user.signingkey ~/.ssh/id_rsa.pub
        git config --local commit.gpgsign true
        git config --local gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
    
    - name: Commit and push changes
      if: github.event_name == 'push' && github.ref == 'refs/heads/main'
      run: |
        git add .
        
        if git diff --staged --quiet; then
          echo "No changes to commit"
        else
          git commit -S -m "Automated update
          
          🤖 Generated by GitHub Actions"
          git push
        fi
```

## Key Learning Points

### 1. Email Address is Critical
- Must use the **exact** GitHub account email address
- For GitHub users, this is typically: `USER_ID+username@users.noreply.github.com`
- Find your GitHub email in: Settings → Emails

### 2. Two Types of SSH Keys Required
- **Deploy Key** (repository level): Allows workflow to push commits
- **Signing Key** (account level): Allows GitHub to verify signatures

### 3. Base64 Encoding for Secrets
- SSH private keys contain newlines that break in GitHub Actions secrets
- Always base64 encode private keys before storing as secrets
- Decode in the workflow: `echo "$SECRET" | base64 -d > keyfile`

### 4. Allowed Signers File
- Git requires `gpg.ssh.allowedSignersFile` for SSH signature verification
- Format: `email ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...`
- Must match the commit author email exactly

### 5. Explicit Signing Flag
- Use `git commit -S` to force signing even when `commit.gpgsign` is true
- Helps ensure the signature is properly applied

## Common Issues and Solutions

### Issue: "Repository rule violations - Commits must have verified signatures"
**Solution**: Ensure the SSH signing key is added to your GitHub **account** (not just repository) as a "Signing Key" type.

### Issue: "gpg.ssh.allowedSignersFile needs to be configured"
**Solution**: Create the allowed signers file and configure Git to use it:
```bash
echo "your-email $(cat ~/.ssh/id_rsa.pub)" > ~/.ssh/allowed_signers
git config gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
```

### Issue: "Load key error in libcrypto"
**Solution**: The SSH private key is corrupted. Ensure it's base64 encoded in the secret and properly decoded in the workflow.

### Issue: "No signature" in commit verification
**Solution**: Verify the email address in Git config exactly matches the email associated with the SSH signing key in GitHub.

## Security Considerations

1. **Dedicated Keys**: Always use separate SSH keys for automation, never personal keys
2. **Minimal Permissions**: The deploy key only needs write access to the specific repository
3. **Key Rotation**: Consider rotating automation keys periodically
4. **Secret Management**: Store private keys only in GitHub repository secrets, never in code

## Example Output

When working correctly, you should see:
```
✅ All diagrams built successfully!
Creating signed commit...
Git configuration:
user.email=11855163+norandom@users.noreply.github.com
user.name=GitHub Action
gpg.format=ssh
user.signingkey=/home/runner/.ssh/id_rsa.pub
commit.gpgsign=true
gpg.ssh.allowedsignersfile=/home/runner/.ssh/allowed_signers

Verifying commit signature:
gpg: Good signature from "11855163+norandom@users.noreply.github.com"
306d40e Auto-build D2 diagrams

[main 306d40e] Auto-build D2 diagrams
16 files changed, 8 insertions(+), 8 deletions(-)
```

## References

- [Git SSH Signing Documentation](https://git-scm.com/docs/git-config#Documentation/git-config.txt-gpgformat)
- [GitHub SSH Signing Keys](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification#ssh-commit-signature-verification)
- [GitHub Actions Permissions](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#permissions)
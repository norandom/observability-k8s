#!/usr/bin/env python3
"""
Comprehensive YAML Lint Fixer
Fixes common YAML lint issues identified in GitHub Actions
"""

import os
import re
import sys
from pathlib import Path

def fix_syntax_errors(content):
    """Fix common YAML syntax errors"""
    lines = content.split('\n')
    fixed_lines = []
    
    for i, line in enumerate(lines):
        # Fix missing colons after keys
        if re.match(r'^(\s*)[a-zA-Z][a-zA-Z0-9_-]*\s*$', line):
            # Check if next line is indented more (suggesting this should have a colon)
            if i + 1 < len(lines) and lines[i + 1].strip():
                next_indent = len(lines[i + 1]) - len(lines[i + 1].lstrip())
                curr_indent = len(line) - len(line.lstrip())
                if next_indent > curr_indent:
                    line = line.rstrip() + ':'
        
        fixed_lines.append(line)
    
    return '\n'.join(fixed_lines)

def fix_indentation(content):
    """Fix YAML indentation issues"""
    lines = content.split('\n')
    fixed_lines = []
    
    for i, line in enumerate(lines):
        if not line.strip():
            fixed_lines.append(line)
            continue
            
        # Fix document separators at root level
        if line.strip() in ['---', '...']:
            fixed_lines.append(line.strip())
            continue
            
        # Get current indentation
        indent = len(line) - len(line.lstrip())
        content_line = line.lstrip()
        
        # Fix common indentation patterns
        if content_line.startswith('- '):
            # List items should maintain consistent indentation
            if indent % 2 != 0:
                indent = (indent // 2) * 2
            fixed_lines.append(' ' * indent + content_line)
        elif ':' in content_line and not content_line.startswith('#'):
            # Key-value pairs
            if indent % 2 != 0:
                indent = (indent // 2) * 2
            fixed_lines.append(' ' * indent + content_line)
        else:
            # Other lines
            if indent % 2 != 0:
                indent = (indent // 2) * 2
            fixed_lines.append(' ' * indent + content_line)
    
    return '\n'.join(fixed_lines)

def fix_line_length(content, max_length=120):
    """Fix overly long lines by breaking them appropriately"""
    lines = content.split('\n')
    fixed_lines = []
    
    for line in lines:
        if len(line) <= max_length:
            fixed_lines.append(line)
            continue
            
        # Don't break lines that are comments or URLs
        if line.strip().startswith('#') or 'http' in line:
            fixed_lines.append(line)
            continue
            
        # Try to break long lines at logical points
        indent = len(line) - len(line.lstrip())
        content_part = line.lstrip()
        
        # If it's a long string value, keep it as is (often better than breaking)
        if '"' in content_part or "'" in content_part:
            fixed_lines.append(line)
            continue
            
        # For very long lines that are lists or complex structures
        if len(line) > max_length + 20:  # Only break very long lines
            # This is complex to do safely, so we'll leave it for manual review
            fixed_lines.append(line)
        else:
            fixed_lines.append(line)
    
    return '\n'.join(fixed_lines)

def fix_yaml_file(filepath):
    """Fix a single YAML file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Apply fixes
        content = fix_syntax_errors(content)
        content = fix_indentation(content)
        content = fix_line_length(content)
        
        # Remove trailing whitespace
        lines = content.split('\n')
        lines = [line.rstrip() for line in lines]
        content = '\n'.join(lines)
        
        # Ensure file ends with newline
        if content and not content.endswith('\n'):
            content += '\n'
        
        # Only write if changed
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed: {filepath}")
            return True
        else:
            print(f"No changes: {filepath}")
            return False
            
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return False

def main():
    """Main function"""
    apps_dir = Path('apps')
    if not apps_dir.exists():
        print("Error: apps/ directory not found")
        sys.exit(1)
    
    print("Comprehensive YAML Fixer")
    print("========================")
    
    yaml_files = list(apps_dir.glob('**/*.yaml')) + list(apps_dir.glob('**/*.yml'))
    
    if not yaml_files:
        print("No YAML files found in apps/ directory")
        sys.exit(1)
    
    print(f"Found {len(yaml_files)} YAML files")
    
    fixed_count = 0
    for yaml_file in sorted(yaml_files):
        if fix_yaml_file(yaml_file):
            fixed_count += 1
    
    print(f"\nSummary: Fixed {fixed_count} out of {len(yaml_files)} files")

if __name__ == '__main__':
    main()
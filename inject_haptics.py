import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content

    # Replace block callbacks:
    # onTap: () {
    # onPressed: () {
    # Check if HapticFeedback is already the first line inside the block
    def block_sub(match):
        prefix = match.group(0)
        return prefix + "\n      HapticFeedback.lightImpact();"

    # We match "onTap: () {" or "onPressed: () {"
    content = re.sub(
        r'(onTap|onPressed):\s*\(\)\s*(?:async\s*)?\{(?!\s*HapticFeedback)',
        block_sub,
        content
    )

    # Convert arrow functions to blocks:
    # onTap: () => someFunction(),
    # onPressed: () => expr
    def arrow_sub(match):
        name = match.group(1)
        async_kw = match.group(2) if match.group(2) else ""
        expr = match.group(3).strip()
        if expr.endswith(','):
            clean_expr = expr[:-1].strip()
            return f"{name}: () {async_kw}{{ \n      HapticFeedback.lightImpact();\n      return {clean_expr};\n    }},"
        else:
            return f"{name}: () {async_kw}{{ \n      HapticFeedback.lightImpact();\n      return {expr};\n    }}"

    # Match arrow functions that are on the SAME line, up to comma or newline
    content = re.sub(
        r'(onTap|onPressed):\s*\(\)\s*(async\s+)?=>\s*([^,\n]+,?)',
        arrow_sub,
        content
    )
    
    # Same for onTap: (val) {
    def block_sub_arg(match):
        return match.group(0) + "\n      HapticFeedback.lightImpact();"
    content = re.sub(
        r'(onTap|onPressed|onChanged|onSubmitted):\s*\([a-zA-Z0-9_,\s]*\)\s*(?:async\s*)?\{(?!\s*HapticFeedback)',
        block_sub_arg,
        content
    )

    if content != original:
        if 'HapticFeedback' in content and 'package:flutter/services.dart' not in content:
            imports = list(re.finditer(r"import\s+['\"].*?['\"];", content))
            if imports:
                last_import_end = imports[-1].end()
                content = content[:last_import_end] + "\nimport 'package:flutter/services.dart';" + content[last_import_end:]
            else:
                content = "import 'package:flutter/services.dart';\n" + content
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

count = 0
for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
            count += 1
print(f"Processed {count} dart files.")

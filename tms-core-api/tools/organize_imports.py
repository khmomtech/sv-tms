#!/usr/bin/env python3
"""
Scan Java source files and replace common star imports with explicit imports when safe.

Currently targets:
- import lombok.*;
- import jakarta.persistence.*;

Strategy:
- For each Java file under src/main/java and src/test/java, if it contains a targeted star import,
  scan the file for usages of known symbols (annotations and types) and replace the star import
  with explicit imports for the used symbols only.

This is conservative (only affects lombok and jakarta.persistence) and preserves formatting.

Usage:
  python3 tools/organize_imports.py

"""
import os
import re
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).resolve().parents[1]
SRC_DIRS = [ROOT / 'src' / 'main' / 'java', ROOT / 'src' / 'test' / 'java']

LOMBOK_SYMBOLS = [
    'Getter', 'Setter', 'Data', 'NoArgsConstructor', 'AllArgsConstructor', 'Builder',
    'EqualsAndHashCode', 'ToString', 'RequiredArgsConstructor', 'Value', 'Slf4j',
    'NonNull', 'AccessLevel', 'Cleanup', 'SneakyThrows', 'With', 'Singular',
]

JAKARTA_PERSISTENCE_SYMBOLS = [
    # common annotations & types
    'Entity', 'Table', 'Id', 'GeneratedValue', 'GenerationType', 'Column', 'ManyToOne',
    'OneToMany', 'OneToOne', 'ManyToMany', 'JoinColumn', 'JoinTable', 'JoinColumns', 'MappedBy',
    'Enumerated', 'EnumType', 'Temporal', 'TemporalType', 'Transient', 'Embeddable', 'EmbeddedId',
    'Version', 'Lob', 'Inheritance', 'InheritanceType', 'MappedSuperclass', 'AttributeOverride',
    'AttributeOverrides', 'ElementCollection', 'CollectionTable', 'OrderColumn', 'OrderBy',
    # cascade / fetch enums
    'CascadeType', 'FetchType',
    # lifecycle callbacks
    'PrePersist', 'PreUpdate', 'PostLoad', 'PreRemove', 'PostPersist', 'PostUpdate', 'PostRemove',
    # constraints / index
    'UniqueConstraint', 'Index',
    # mapping helpers
    'MapsId', 'MapKeyColumn', 'MapKeyJoinColumn',
    # FK
    'ForeignKey',
]

STAR_PATTERNS = {
    'import lombok.*;': ('lombok', LOMBOK_SYMBOLS),
    'import jakarta.persistence.*;': ('jakarta.persistence', JAKARTA_PERSISTENCE_SYMBOLS),
    # also consider old javax.persistence
    'import javax.persistence.*;': ('jakarta.persistence', JAKARTA_PERSISTENCE_SYMBOLS),
    # common external star imports we want to replace with known types
    'import org.springframework.data.jpa.repository.*;': (
        'org.springframework.data.jpa.repository',
        [
            'JpaRepository', 'PagingAndSortingRepository', 'CrudRepository',
            'JpaSpecificationExecutor', 'QueryByExampleExecutor'
        ],
    ),
    'import org.springframework.data.repository.*;': (
        'org.springframework.data.repository',
        ['Repository', 'CrudRepository', 'PagingAndSortingRepository'],
    ),
}


def find_java_files():
    files = []
    for sd in SRC_DIRS:
        if sd.exists():
            for p in sd.rglob('*.java'):
                files.append(p)
    return files


def file_needs_patch(text):
    # Check for any star-import occurrence, or configured patterns
    if re.search(r'import\s+[\w\.]+\.\*;', text):
        return True
    for star in STAR_PATTERNS.keys():
        if star in text:
            return True
    return False


def used_symbols(text, symbols):
    used = set()
    for s in symbols:
        # look for annotations '@S' or word boundary usages
        if re.search(r'@' + re.escape(s) + r'\b', text) or re.search(r'\b' + re.escape(s) + r'\b', text):
            used.add(s)
    return sorted(used)


def replace_star_imports(path: Path):
    text = path.read_text(encoding='utf-8')
    if not file_needs_patch(text):
        return False

    original = text
    changed = False

    lines = text.splitlines()
    new_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        # match explicit configured star patterns first
        if stripped in STAR_PATTERNS:
            pkg, symbols = STAR_PATTERNS[stripped]
            # find used symbols in entire file
            used = used_symbols(text, symbols)
            if used:
                # create explicit imports
                import_lines = [f'import {pkg}.{s};' for s in used]
                new_lines.extend(import_lines)
                changed = True
            else:
                # no used symbols found; keep original star import (safer)
                new_lines.append(line)
            i += 1
            continue

        # Generic handling: if the line is a star import like 'import com.foo.bar.*;'
        m = re.match(r'import\s+([\w\.]+)\.\*;', stripped)
        if m:
            pkg = m.group(1)
            # Attempt to resolve package directory under src/main/java or src/test/java
            pkg_path = pkg.replace('.', os.sep)
            candidate_dirs = [ROOT / 'src' / 'main' / 'java' / pkg_path, ROOT / 'src' / 'test' / 'java' / pkg_path]
            symbols = []
            for cd in candidate_dirs:
                if cd.exists():
                    for f in cd.glob('*.java'):
                        symbols.append(f.stem)
                    break

            if symbols:
                used = used_symbols(text, symbols)
                if used:
                    import_lines = [f'import {pkg}.{s};' for s in used]
                    new_lines.extend(import_lines)
                    changed = True
                    i += 1
                    continue
                else:
                    # keep original star import if we couldn't determine usage
                    new_lines.append(line)
                    i += 1
                    continue
        else:
            new_lines.append(line)
            i += 1

    if changed:
        new_text = '\n'.join(new_lines) + '\n'
        path.write_text(new_text, encoding='utf-8')
        print(f'Patched: {path}')
        return True
    return False


def add_missing_imports(path: Path):
    """If a file references jakarta.persistence symbols but lacks explicit imports for them,
    add the missing imports (conservative).
    """
    text = path.read_text(encoding='utf-8')
    orig_text = text
    # only operate on files that already reference jakarta.persistence or have JPA annotations
    if 'jakarta.persistence' not in text and 'javax.persistence' not in text:
        # still proceed if annotations present
        jpa_annotation_pattern = re.compile(r'@(?:' + '|'.join([re.escape(s) for s in JAKARTA_PERSISTENCE_SYMBOLS]) + r')\b')
        if not jpa_annotation_pattern.search(text):
            return False

    # collect existing imports
    existing_imports = set(re.findall(r'^import\s+([\w\.]+);', text, flags=re.MULTILINE))
    # find used symbols
    used = used_symbols(text, JAKARTA_PERSISTENCE_SYMBOLS)
    missing = []
    for s in used:
        fq = f'jakarta.persistence.{s}'
        if fq not in existing_imports:
            missing.append(fq)

    if not missing:
        return False

    # insert missing imports after package and existing imports block
    lines = text.splitlines()
    insert_idx = 0
    for idx, line in enumerate(lines):
        if line.startswith('package '):
            insert_idx = idx + 1
            continue
        if line.startswith('import '):
            insert_idx = idx + 1

    import_lines = [f'import {m};' for m in sorted(set(missing))]
    new_lines = lines[:insert_idx] + import_lines + lines[insert_idx:]
    new_text = '\n'.join(new_lines) + '\n'
    path.write_text(new_text, encoding='utf-8')
    print(f'Added imports to: {path} -> {len(import_lines)} imports')
    return True


def main():
    java_files = find_java_files()
    patched_files = []
    for f in java_files:
        try:
            if replace_star_imports(f):
                patched_files.append(str(f.relative_to(ROOT)))
        except Exception as e:
            print(f'Error processing {f}: {e}')

    if patched_files:
        print(f'Patched {len(patched_files)} files:')
        for p in patched_files[:50]:
            print(' -', p)
    else:
        print('No files patched.')


if __name__ == '__main__':
    main()

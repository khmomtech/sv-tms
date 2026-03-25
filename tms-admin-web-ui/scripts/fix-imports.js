#!/usr/bin/env node

/**
 * Automated Import Path Fixer
 *
 * This script converts deep relative imports to path aliases:
 * - ../../../models/driver.model -> @models/driver.model (or @models)
 * - ../../../services/driver.service -> @services/driver.service (or @services)
 * - ../../../environments/environment -> @env/environment
 * - ../../../core/something -> @core/something
 * - ../../../shared/something -> @shared/something
 *
 * Usage:
 *   npm install --save-dev ts-morph
 *   node scripts/fix-imports.js
 */

const { Project } = require('ts-morph');
const path = require('path');
const fs = require('fs');

console.log('🔧 Starting import path migration...\n');

// Initialize ts-morph project
const project = new Project({
  tsConfigFilePath: path.join(__dirname, '../tsconfig.json'),
});

const sourceFiles = project.getSourceFiles([
  'src/app/**/*.ts',
  '!src/app/**/*.spec.ts',
  '!src/app/api/generated_openapi/**/*',
]);

console.log(`📁 Found ${sourceFiles.length} TypeScript files to process\n`);

let totalChanges = 0;
const changesByType = {
  models: 0,
  services: 0,
  environment: 0,
  core: 0,
  shared: 0,
  guards: 0,
  resolvers: 0,
};

sourceFiles.forEach((sourceFile) => {
  const filePath = sourceFile.getFilePath();
  const imports = sourceFile.getImportDeclarations();
  let fileChanged = false;

  imports.forEach((importDecl) => {
    const moduleSpecifier = importDecl.getModuleSpecifierValue();
    let newPath = null;
    let changeType = null;

    // Fix model imports
    if (moduleSpecifier.match(/\.\.\/.*\/models\//)) {
      const modelPath = moduleSpecifier.split('/models/')[1];
      if (modelPath) {
        newPath = `@models/${modelPath}`;
        changeType = 'models';
      }
    }
    // Fix direct model file imports to use barrel
    else if (moduleSpecifier.match(/\.\.\/.*\/models$/)) {
      newPath = '@models';
      changeType = 'models';
    }

    // Fix service imports
    else if (moduleSpecifier.match(/\.\.\/.*\/services\//)) {
      const servicePath = moduleSpecifier.split('/services/')[1];
      if (servicePath) {
        newPath = `@services/${servicePath}`;
        changeType = 'services';
      }
    }
    // Fix direct service file imports to use barrel
    else if (moduleSpecifier.match(/\.\.\/.*\/services$/)) {
      newPath = '@services';
      changeType = 'services';
    }

    // Fix environment imports
    else if (moduleSpecifier.match(/\.\.\/.*\/environments\//)) {
      const envPath = moduleSpecifier.split('/environments/')[1];
      if (envPath) {
        newPath = `@env/${envPath}`;
        changeType = 'environment';
      }
    }

    // Fix core imports
    else if (moduleSpecifier.match(/\.\.\/.*\/core\//)) {
      const corePath = moduleSpecifier.split('/core/')[1];
      if (corePath) {
        newPath = `@core/${corePath}`;
        changeType = 'core';
      }
    }
    else if (moduleSpecifier.match(/\.\.\/.*\/core$/)) {
      newPath = '@core';
      changeType = 'core';
    }

    // Fix shared imports
    else if (moduleSpecifier.match(/\.\.\/.*\/shared\//)) {
      const sharedPath = moduleSpecifier.split('/shared/')[1];
      if (sharedPath) {
        newPath = `@shared/${sharedPath}`;
        changeType = 'shared';
      }
    }
    else if (moduleSpecifier.match(/\.\.\/.*\/shared$/)) {
      newPath = '@shared';
      changeType = 'shared';
    }

    // Fix guard imports
    else if (moduleSpecifier.match(/\.\.\/.*\/guards\//)) {
      const guardPath = moduleSpecifier.split('/guards/')[1];
      if (guardPath) {
        newPath = `@app/guards/${guardPath}`;
        changeType = 'guards';
      }
    }

    // Fix resolver imports
    else if (moduleSpecifier.match(/\.\.\/.*\/resolvers\//)) {
      const resolverPath = moduleSpecifier.split('/resolvers/')[1];
      if (resolverPath) {
        newPath = `@app/resolvers/${resolverPath}`;
        changeType = 'resolvers';
      }
    }

    // Apply the change
    if (newPath && newPath !== moduleSpecifier) {
      importDecl.setModuleSpecifier(newPath);
      fileChanged = true;
      totalChanges++;
      if (changeType) {
        changesByType[changeType]++;
      }
    }
  });

  if (fileChanged) {
    sourceFile.saveSync();
    console.log(`Updated: ${path.relative(process.cwd(), filePath)}`);
  }
});

console.log('\n📊 Migration Summary:');
console.log('─'.repeat(50));
console.log(`Total files processed: ${sourceFiles.length}`);
console.log(`Total imports updated: ${totalChanges}`);
console.log('\nChanges by type:');
Object.entries(changesByType).forEach(([type, count]) => {
  if (count > 0) {
    console.log(`  ${type.padEnd(15)}: ${count}`);
  }
});

console.log('\nImport path migration complete!');
console.log('\nNext steps:');
console.log('1. Run: npm run lint -- --fix');
console.log('2. Run: npm run build');
console.log('3. Run: npm test');
console.log('4. Review and commit changes\n');

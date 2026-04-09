// CommonJS Karma configuration (renamed to .cjs due to package.json type: module)
// Uses Puppeteer-provided Chromium for headless CI execution.

// Attempt to use Puppeteer's bundled Chromium; fallback to system chromium if not present.
try {
  const puppeteerPath = require('puppeteer').executablePath();
  const fs = require('fs');
  if (puppeteerPath && fs.existsSync(puppeteerPath)) {
    process.env.CHROME_BIN = puppeteerPath;
  } else if (!process.env.CHROME_BIN) {
    // OS-specific fallbacks
    if (process.platform === 'darwin' && fs.existsSync('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome')) {
      process.env.CHROME_BIN = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
    } else {
      if (fs.existsSync('/usr/bin/google-chrome')) {
        process.env.CHROME_BIN = '/usr/bin/google-chrome';
      } else if (fs.existsSync('/usr/bin/google-chrome-stable')) {
        process.env.CHROME_BIN = '/usr/bin/google-chrome-stable';
      } else {
        process.env.CHROME_BIN = '/usr/bin/chromium';
      }
    }
  }
} catch (e) {
  if (!process.env.CHROME_BIN) {
    const fs = require('fs');
    if (process.platform === 'darwin' && fs.existsSync('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome')) {
      process.env.CHROME_BIN = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
    } else {
      if (fs.existsSync('/usr/bin/google-chrome')) {
        process.env.CHROME_BIN = '/usr/bin/google-chrome';
      } else if (fs.existsSync('/usr/bin/google-chrome-stable')) {
        process.env.CHROME_BIN = '/usr/bin/google-chrome-stable';
      } else {
        process.env.CHROME_BIN = '/usr/bin/chromium';
      }
    }
  }
}

module.exports = function (config) {
  config.set({
    basePath: '',
    frameworks: ['jasmine', '@angular-devkit/build-angular'],
    plugins: [
      require('karma-jasmine'),
      require('karma-chrome-launcher'),
      require('karma-jasmine-html-reporter'),
      require('karma-coverage'),
      require('@angular-devkit/build-angular/plugins/karma')
    ],
    client: {
      jasmine: {},
      clearContext: false
    },
    reporters: ['progress', 'kjhtml', 'coverage'],
    coverageReporter: {
      dir: require('path').join(__dirname, 'coverage'),
      reporters: [
        { type: 'html' },
        { type: 'text-summary' }
      ],
      includeAllSources: true
    },
    port: 9877,
    colors: true,
    logLevel: config.LOG_INFO,
    autoWatch: false,
    browsers: ['ChromeHeadlessNoSandbox'],
    customLaunchers: {
      ChromeHeadlessNoSandbox: {
        base: 'ChromeHeadless',
        flags: [
          '--no-sandbox',
          '--disable-setuid-sandbox',
          '--disable-dev-shm-usage',
          '--disable-gpu',
          '--remote-debugging-port=0'
        ]
      }
    },
    browserDisconnectTimeout: 10000,
    browserNoActivityTimeout: 120000,
    processKillTimeout: 10000,
    singleRun: true,
    restartOnFileChange: false
  });
};

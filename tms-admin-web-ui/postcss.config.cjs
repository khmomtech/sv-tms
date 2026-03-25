module.exports = {
  plugins: [
    require('postcss-import'),
    require('tailwindcss'),
    // Fallback: ensure any remaining nested rules are processed
    // Some build pipelines may skip the nesting handler; `postcss-nested`
    // will expand any `&` rules before further processing/minification.
    require('postcss-nested'),
    require('autoprefixer'),
  ],
};

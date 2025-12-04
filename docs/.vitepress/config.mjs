import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "SmartGRADE Backend",
  description: "Systematic Review Analysis API",

  // For GitHub Pages deployment
  base: '/smart-grade-backend/',

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
      { text: 'API Documentation', link: '/api/' }
    ],

    sidebar: [
      {
        text: 'Quick Start',
        items: [
          { text: 'Overview', link: '/api/' }
        ]
      },
      {
        text: 'API Reference',
        items: [
          { text: 'Authentication', link: '/api/authentication' },
          { text: 'Database', link: '/api/database' },
          { text: 'Functions', link: '/api/functions' }
        ]
      },
      {
        text: 'Examples',
        items: [
          { text: 'Create Review', link: '/api/examples/create-review' },
          { text: 'Upload Pages', link: '/api/examples/upload-pages' },
          { text: 'Parse Review', link: '/api/examples/parse-review' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/avandvik/smart-grade-backend' }
    ],

    search: {
      provider: 'local'
    }
  }
})
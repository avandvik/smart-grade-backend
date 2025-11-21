import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "SmartGRADE Backend",
  description: "Systematic review management API for AI agents",

  // For GitHub Pages deployment
  base: '/smart-grade-backend/',

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
      { text: 'API Reference', link: '/api/01_authentication' }
    ],

    sidebar: [
      {
        text: 'API Reference',
        items: [
          { text: 'Authentication', link: '/api/01_authentication' },
          { text: 'Reviews', link: '/api/02_reviews' },
          { text: 'Review Pages', link: '/api/03_review_pages' },
          { text: 'Storage', link: '/api/04_storage' }
        ]
      },
      {
        text: 'Database',
        items: [
          { text: 'Database Overview', link: '/database/01_database_overview' },
          { text: 'Tables', link: '/database/02_tables' }
        ]
      },
      {
        text: 'Examples',
        items: [
          { text: 'Create Review', link: '/examples/01_create_review' },
          { text: 'Upload Pages', link: '/examples/02_upload_pages' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/yourusername/smart-grade-backend' }
    ],

    search: {
      provider: 'local'
    }
  }
})
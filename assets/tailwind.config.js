const colors = require('tailwindcss/colors')

module.exports = {
  purge: [
    '../lib/**/*.ex',
    '../lib/**/*.heex',
    '../lib/**/*.leex',
    '../lib/**/*.eex',
    './js/**/*.js'
  ],
  darkMode: 'media',
  theme: {
    colors: {
      transparent: 'transparent',
      current: 'currentColor',

      primary: colors.gray,

      black: colors.black,
      white: colors.white,
      gray: colors.trueGray,
      indigo: colors.indigo,
      red: colors.rose,
      yellow: colors.amber
    },
    extend: {
      spacing: {
        128: '32rem',
        192: '48rem',
        256: '64rem'
      }
    }
  },
  variants: {
    extend: {
      backgroundColor: ['active'],
      borderColor: ['active']
    }
  },
  plugins: []
}

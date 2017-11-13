// shared custom *config*

module.exports = [
  // Makes exports from entry packs available to global scope, e.g.
  {
    output: {
      library: ['Packs', '[name]'],
      libraryTarget: 'var'
    }
  }
]

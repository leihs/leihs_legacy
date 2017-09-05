window.Scrolling = {


  mount: (onScroll) => {
    window.addEventListener('scroll', onScroll);
  },

  unmount: (onScroll) => {
    window.removeEventListener('scroll', onScroll);
  },


  _getDocHeight () {
    D = document
    return Math.max(
        D.body.scrollHeight, D.documentElement.scrollHeight,
        D.body.offsetHeight, D.documentElement.offsetHeight,
        D.body.clientHeight, D.documentElement.clientHeight
    )
  },

  _scrollTop () {
    return Math.max(
      document.body.scrollTop, document.documentElement.scrollTop
    )
  },

  _isBottom () {
    return this._scrollTop() + window.innerHeight >= this._getDocHeight() - window.innerHeight * 2// || window.innerHeight > this._getDocHeight() * 0.3
  },

}

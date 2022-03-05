// maintain user adjusted attributes, like textbox length on phoenix liveview
// update. https://github.com/phoenixframework/phoenix_live_view/issues/1011

export default {
  attrs () {
    const attrs = this.el.getAttribute('data-attrs')
    if (attrs) { return attrs.split(', ') } else { return [] }
  },
  beforeUpdate () { this.prevAttrs = this.attrs().map(name => [name, this.el.getAttribute(name)]) },
  updated () { this.prevAttrs.forEach(([name, val]) => this.el.setAttribute(name, val)) }
}

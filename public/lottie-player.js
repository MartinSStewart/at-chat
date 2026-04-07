class LottiePlayer extends HTMLElement {
  static get observedAttributes() {
    return ['src'];
  }

  constructor() {
    super();
    this._animation = null;
  }

  connectedCallback() {
    this._loadAnimation();
  }

  disconnectedCallback() {
    this._destroyAnimation();
  }

  attributeChangedCallback(name, oldValue, newValue) {
    if (name === 'src' && oldValue !== newValue && this.isConnected) {
      this._loadAnimation();
    }
  }

  _destroyAnimation() {
    if (this._animation) {
      this._animation.destroy();
      this._animation = null;
    }
  }

  _loadAnimation() {
    this._destroyAnimation();
    var src = this.getAttribute('src');
    if (!src) return;
    this._animation = bodymovin.loadAnimation({
      container: this,
      renderer: 'svg',
      loop: true,
      autoplay: true,
      path: src
    });
  }
}

customElements.define('lottie-player', LottiePlayer);

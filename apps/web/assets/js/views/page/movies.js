import MainView from '../main';

export default class View extends MainView {
  mount() {
    super.mount();
    console.log('MoviesView mounted');
  }

  unmount() {
    super.unmount();
    console.log('MoviesView unmounted');
  }

  closest(el, selector, stopSelector) {
    let retval = null;
    while (el) {
      if (el.matches(selector)) {
        retval = el;
        break;
      } else if (stopSelector && el.matches(stopSelector)) {
        break;
      }
      el = el.parentElement;
    }
    return retval;
  }
}


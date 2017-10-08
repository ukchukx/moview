import MainView from '../main';

export default class View extends MainView {
  mount() {
    super.mount();

    // Attach click handler to movie cards
    this.movieItems = document.querySelectorAll('.movie-card-item');
    this.movieItems.forEach(item => item.addEventListener('click', this.handleItemClick.bind(this), false));
    console.log('MoviesView mounted');
  }

  handleItemClick(e) {
    // The click can occur anywhere. Find the card element
    // and click the details link
    this
      .closest(e.target, '.movie-card-item', 'div.row.mt-2')
      .querySelector('.card-link')
      .click();
  }

  unmount() {
    super.unmount();
    this.movieItems.forEach(item => item.removeEventListener('click', this.handleItemClick, false));
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


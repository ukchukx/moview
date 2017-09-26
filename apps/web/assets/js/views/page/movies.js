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
}


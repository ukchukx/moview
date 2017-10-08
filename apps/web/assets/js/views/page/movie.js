import MainView from '../main';

export default class View extends MainView {
  mount() {
    super.mount();
    console.log('MovieView mounted');
  }

  unmount() {
    super.unmount();
    console.log('MovieView unmounted');
  }
}


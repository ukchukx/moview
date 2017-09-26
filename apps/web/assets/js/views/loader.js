import MainView from './main';
import PageMoviesView from './page/movies';

// Collection of specific view modules
const views = {
  PageMoviesView
};

export default function loadView(viewName) {
  return views[viewName] || MainView;
}


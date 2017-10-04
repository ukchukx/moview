import MainView from './main';
import PageMovieView from './page/movie';
import PageMoviesView from './page/movies';

// Collection of specific view modules
const views = {
  PageMoviesView,
  PageMovieView
};

export default function loadView(viewName) {
  return views[viewName] || MainView;
}


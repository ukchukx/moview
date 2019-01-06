import MainView from './main';
import PageMovieView from './page/movie';
import PageMoviesView from './page/movies';
import AdminMoviesView from './admin/movies';

// Collection of specific view modules
const views = {
  PageMoviesView,
  PageMovieView,
  AdminMoviesView
};

export default function loadView(viewName) {
  return views[viewName] || MainView;
}


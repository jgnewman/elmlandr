import gulp from 'gulp';
import { log, colors } from 'gulp-util';
import clean from 'gulp-clean';
import elm from 'gulp-elm';
import uglify from 'gulp-uglify';
import gulpif from 'gulp-if';
import { prepReload } from '../utilities/reloader/server-reloader';
import config from '../config';


/**
 * Make sure Elm is fully initialized
 */
gulp.task('elm:init', elm.init);

/**
 * Remove old files.
 */
gulp.task('elm:clean', () => {
  return gulp.src(config.frontend.jsDest).pipe(clean({ read: false }));
});

/**
 * Compile the application
 */
gulp.task('elm:compile', ['elm:clean'], () => {
  const stream = gulp.src(config.frontend.jsSource)
    .pipe(
      elm.bundle('app.js')
         .on('error', function (err) {
           config.tmp.errors = config.tmp.errors || [];
           config.tmp.errors.push(err.message);
           return this.emit('end');
         })
    )
    .pipe(gulpif(config.isProduction, uglify()))
    .pipe(gulp.dest(config.frontend.jsDest))

  stream.on('end', prepReload);
  return stream;
});


/**
 * Watch and recompile files
 */
gulp.task('elm:watch', ['elm:compile'], () => {
  const watch = gulp.watch([config.frontend.jsSource], ['elm:compile']);
  watch.on('change', event => {
    log(colors.yellow('Elm change'), "'" + colors.cyan(event.path) + "'");
  });
});

/**
 * Main elm task
 */
gulp.task('elm:main', ['elm:clean', 'elm:compile', 'elm:watch']);

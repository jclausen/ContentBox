module.exports = function(grunt) {

    // Register Tasks
    grunt.registerTask(
        'default', [
            'clean:targetIncludes', // clean target
            'css', // run css tasks
            'js', // run js tasks
            'watch' // start a watcher
        ]
    );
    grunt.registerTask(
        'js', [
            'clean:js', // clean targets
            'clean:plugins', // clean plugins
            'concat', // concat everything
            'uglify', // uglify everything
            'copy:js', // Copy standalone libs
            'copy:plugins', // Copy plugins
        ]
    );
    grunt.registerTask(
        'css', [
            'clean:css', // clean target
            'copy:fonts', //copy fonts
            'sass:distTheme', // sass compilation
            'cssmin', // css minifications
            'clean:themecss' // cleanup combined css
        ]
    );

    // Init grunt config
    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        /**
         * Directory watch tasks, which will force individual re-compilations
         **/
        watch: {

            recompile: {
                files: ['Gruntfile.js', "package.json", 'resources/plugins/**'],
                tasks: ['default']
            },

            css: {
                files: ['resources/scss/*.{scss,sass}', 'resources/scss/**/*.{scss,sass}', 'resources/scss/**/**/*.{scss,sass}', 'resources/vendor/css/*.css'],
                tasks: ['css']
            },

            libsjs: {
                files: ['resources/vendor/js/*.js'],
                tasks: ['js']
            },

            appjs: {
                files: ['resources/js/**/*.js'],
                tasks: ['concat:appjs', 'uglify:appjs']
            }
        },

        /**
         * SCSS Compilation to css
         */
        sass: {
            options: {
                sourceMap: false
            },
            /**
             * Contentbox and Theme SCSS Compilation
             **/
            distTheme: {
                files: {
                    '../modules/contentbox/modules/contentbox-admin/includes/css/theme.css': 'resources/scss/theme.scss'
                }
            }
        },

        /**
         * CSS Min
         * Minifies the theme + bower + vendor css
         */
        cssmin: {
            options: {
                sourceMap: true
            },
            target: {
                files: {
                    '../modules/contentbox/modules/contentbox-admin/includes/css/contentbox.min.css': [
                        // THEME
                        '../modules/contentbox/modules/contentbox-admin/includes/css/theme.css'
                        // BOWER COMPONENTS
                        , 'bower_components/animate.css/animate.css', 'bower_components/switchery/dist/switchery.min.css', 'bower_components/morris.js/morris.css', 'bower_components/datatables/media/css/dataTables.bootstrap.css', 'bower_components/bootstrap-datepicker/dist/css/bootstrap-datepicker3.min.css', 'bower_components/clockpicker/dist/bootstrap-clockpicker.css', 'bower_components/bootstrap-toggle/css/bootstrap-toggle.min.css', 'bower_components/seiyria-bootstrap-slider/dist/css/bootstrap-slider.min.css'
                        // VENDOR CSS
                        , 'resources/vendor/css/*.css'
                    ]
                }
            }
        },

        /**
         * Concat JS
         */
        concat: {

            // ContentBox App Libraries
            appjs: {
                files: {
                    '../modules/contentbox/modules/contentbox-admin/includes/js/contentbox-app.js': ["resources/js/*.js"],
                    '../modules/contentbox/modules/contentbox-admin/includes/js/contentbox-editors.js': [
                        "resources/js/editors/editors.js",
                        "resources/js/editors/autosave.js"
                    ]
                }
            },

            // Pre Lib: Libraries which are brough in the <head> section
            prejs: {
                src: [
                    // Bower Libraries
                    "bower_components/jquery/dist/jquery.min.js", "bower_components/jquery.cookie/jquery.cookie.js", "bower_components/jquery-validation/dist/jquery.validate.min.js", "bower_components/bootstrap-sass/assets/javascripts/bootstrap.min.js", "bower_components/moment/min/moment-with-locales.min.js", "bower_components/lz-string/libs/lz-string.min.js", "bower_components/lodash/dist/lodash.min.js", "bower_components/history.js/scripts/bundled/html4+html5/jquery.history.js"
                    // Vendor Libraries
                    , "resources/vendor/js/jquery.validate.bootstrap.js", "resources/vendor/js/modernizr.min.js"
                ],
                dest: '../modules/contentbox/modules/contentbox-admin/includes/js/contentbox-pre.js'
            },

            // Post Lib: Libraries which are brought in before the </body> end
            postjs: {
                src: [
                    // Bower Libraries
                    "bower_components/bootstrap-datepicker/dist/js/bootstrap-datepicker.min.js", "bower_components/es6-shim/es6-shim.min.js", "bower_components/navgoco/src/jquery.navgoco.min.js", "bower_components/switchery/dist/switchery.min.js", "bower_components/raphael/raphael.js", "bower_components/morris.js/morris.min.js", "bower_components/clockpicker/dist/bootstrap-clockpicker.min.js", "bower_components/jwerty/jwerty.js", "bower_components/datatables/media/js/jquery.dataTables.min.js", "bower_components/datatables/media/js/dataTables.bootstrap.min.js", "bower_components/TableDnD/dist/jquery.tablednd.min.js", "bower_components/toastr/toastr.min.js", "bower_components/Bootstrap-Confirmation/bootstrap-confirmation.js", "bower_components/jquery-nestable/jquery.nestable.js", "bower_components/jq-fullscreen/release/jquery.fullscreen.min.js", "bower_components/bootstrap-toggle/js/bootstrap-toggle.min.js", 'bower_components/seiyria-bootstrap-slider/dist/bootstrap-slider.min.js'
                    // Vendor libraries
                    , "resources/vendor/js/bootstrap-fileupload.js", "resources/vendor/js/jquery.uidivfilter.js", "resources/vendor/js/jquery.uitablefilter.js"
                ],
                dest: '../modules/contentbox/modules/contentbox-admin/includes/js/contentbox-post.js'
            }
        },

        /**
         * Uglify compress JS
         */
        uglify: {
            // Options
            options: {
                preserveComments: false,
                mangle: false,
                sourceMap: true,
                drop_console: true,
                banner: '/*! ContentBox Modular CMS. Generated: <%= grunt.template.today( "dd-mm-yyyy" ) %> */\n\n'
            },

            // ContentBox App
            appjs: {
                files: {
                    '../modules/contentbox/modules/contentbox-admin/includes/js/contentbox-app.min.js': ["../modules/contentbox/modules/contentbox-admin/includes/js/contentbox-app.js"],
                    '../modules/contentbox/modules/contentbox-admin/includes/js/contentbox-editors.min.js': ["../modules/contentbox/modules/contentbox-admin/includes/js/contentbox-editors.js"]
                }
            },

            // JS Libraries
            libraries: {
                files: {
                    '../modules/contentbox/modules/contentbox-admin/includes/js/contentbox-pre.min.js': ["../modules/contentbox/modules/contentbox-admin/includes/js/contentbox-pre.js"],
                    '../modules/contentbox/modules/contentbox-admin/includes/js/contentbox-post.min.js': ["../modules/contentbox/modules/contentbox-admin/includes/js/contentbox-post.js"]
                }
            },
        },

        /**
         * Libraries with JS and/or CSS w/o SCSS support - migrated to their respective project plugin directories
         **/
        copy: {
            //Fonts to be copied over - will *replace* distribution fonts directory
            fonts: {
                files: [{
                        expand: true,
                        flatten: true,
                        src: 'bower_components/font-awesome-sass/assets/fonts/font-awesome/**',
                        filter: 'isFile',
                        dest: '../modules/contentbox/modules/contentbox-admin/includes/fonts/font-awesome'
                    },
                    {
                        expand: true,
                        flatten: true,
                        src: 'bower_components/bootstrap-sass/assets/fonts/bootstrap/**',
                        filter: 'isFile',
                        dest: '../modules/contentbox/modules/contentbox-admin/includes/fonts/bootstrap'
                    }
                ]
            },

            /**
             * Individual Javascript files migrated to project /includes/js
             **/
            js: {
                files: [
                    // Single Javascript files to copy from bower
                    {
                        expand: true,
                        flatten: true,
                        cwd: 'bower_components/',
                        src: [
                            "respond/dest/respond.min.js",
                            "html5shiv/dist/html5shiv.min.js"
                        ],
                        dest: '../modules/contentbox/modules/contentbox-admin/includes/js/'
                    },
                    // Extra version of jQuery for CB FileBrowser
                    {
                        expand: true,
                        flatten: true,
                        cwd: 'bower_components/',
                        src: [
                            "jquery/dist/jquery.min.js"
                        ],
                        dest: '../modules/contentbox/modules/contentbox-admin/includes/js/'
                    }
                ]
            },

            /**
             * Compiled Plugins moved to /includes/plugins/
             * These are loaded not on every page but determined by certain conditions
             **/
            plugins: {
                files: [
                    // CKEditor
                    {
                        expand: true,
                        cwd: 'bower_components/',
                        src: [
                            'ckeditor/plugins/**',
                            'ckeditor/adapters/**',
                            'ckeditor/skins/moono-lisa/**',
                            'ckeditor/lang/**',
                            'ckeditor/ckeditor.js',
                            'ckeditor/styles.js',
                            'ckeditor/*.css',
                        ],
                        dest: '../modules/contentbox/modules/contentbox-admin/modules/contentbox-ckeditor/includes/',
                    },
                    // ContentBox CKEditor Config + Plugins
                    {
                        expand: true,
                        cwd: 'resources/plugins/ckeditor/',
                        src: [
                            '**'
                        ],
                        dest: '../modules/contentbox/modules/contentbox-admin/modules/contentbox-ckeditor/includes/ckeditor',
                    },
                    // AutoSave
                    {
                        expand: true,
                        cwd: 'resources/plugins/autosave',
                        src: [
                            '**'
                        ],
                        dest: '../modules/contentbox/modules/contentbox-admin/includes/plugins/autosave',
                    },
                    // Simple MDE Editor
                    {
                        expand: true,
                        cwd: 'bower_components/simplemde/dist',
                        src: [
                            '**'
                        ],
                        dest: '../modules/contentbox/modules/contentbox-admin/modules/contentbox-markdowneditor/includes/simplemde',
                    },
                ],
            }, // end plugins
        }, // end copy task

        /**
         * Directory Resets for Compiled Scripts - Clears the directories below in preparation for recompile
         * Only runs on on initial Grunt startup.  If removing plugins, you will need to restart Grunt
         **/
        clean: {
            options: {
                force: true
            },
            targetIncludes: [
                '../modules/contentbox/modules/contentbox-admin/includes/plugins',
                '../modules/contentbox/modules/contentbox-admin/includes/fonts',
                '../modules/contentbox/modules/contentbox-admin/includes/css',
                '../modules/contentbox/modules/contentbox-admin/includes/js',
                '../modules/contentbox/modules/contentbox-admin/modules/contentbox-ckeditor/includes',
                '../modules/contentbox/modules/contentbox-admin/modules/contentbox-markdowneditor/includes'
            ],
            css: ['../modules/contentbox/modules/contentbox-admin/includes/css'],
            themecss: ["../modules/contentbox/modules/contentbox-admin/includes/css/theme.css"],
            js: ['../modules/contentbox/modules/contentbox-admin/includes/js'],
            plugins: ['../modules/contentbox/modules/contentbox-admin/includes/plugins']
        }

    });

    // Load tasks
    // Load Tasks
    require('matchdep')
        .filterDev('grunt-*')
        .forEach(grunt.loadNpmTasks);
};
module.exports = function( grunt ) {

	grunt.loadNpmTasks( 'grunt-contrib-clean' );
	grunt.loadNpmTasks( 'grunt-contrib-cssmin' );
	grunt.loadNpmTasks( 'grunt-contrib-less' );
	grunt.loadNpmTasks( 'grunt-contrib-rename' );
	grunt.loadNpmTasks( 'grunt-contrib-uglify' );
	grunt.loadNpmTasks( 'grunt-contrib-watch' );
	grunt.loadNpmTasks( 'grunt-rev' );
	grunt.loadNpmTasks( 'grunt-postcss' );

	grunt.registerTask( 'default', [ 'uglify', 'less', 'postcss', 'cssmin', 'clean', 'rev', 'rename' ] );

	grunt.initConfig( {
		uglify: {
			options:{
				  sourceMap     : true
				, sourceMapName : function( dest ){
					var parts = dest.split( "/" );
					parts[ parts.length-1 ] = parts[ parts.length-1 ].replace( /\.js$/, ".map" );
					return parts.join( "/" );
				 }
			},
			specific:{
				files: [{
					expand  : true,
					cwd     : "js/admin/specific/",
					src     : ["**/*.js", "!**/*.min.js" ],
					dest    : "js/admin/specific/",
					ext     : ".min.js",
					rename  : function( dest, src ){
						var pathSplit = src.split( '/' );

						pathSplit[ pathSplit.length-1 ] = "_" + pathSplit[ pathSplit.length-2 ] + ".min.js";

						return dest + pathSplit.join( "/" );
					}
				}]
			},
			frontend:{
				files: [{
					expand  : true,
					cwd     : "js/frontend/",
					src     : ["**/*.js", "!**/*.min.js" ],
					dest    : "js/frontend/",
					ext     : ".min.js",
					rename  : function( dest, src ){
						var pathSplit = src.split( '/' );

						pathSplit[ pathSplit.length-1 ] = "_" + pathSplit[ pathSplit.length-2 ] + ".min.js";

						return dest + pathSplit.join( "/" );
					}
				}]
			}
		},

		less: {
			options: {
				paths : [ "css/admin/lessglobals", "css/admin/bootstrap", "css/admin/ace" ],
			},
			all : {
				files: [{
					expand  : true,
					cwd     : 'css/',
					src     : [ '**/*.less' ],
					dest    : 'css/',
					ext     : ".less.css",
					rename  : function( dest, src ){
						var pathSplit = src.split( '/' );

						pathSplit[ pathSplit.length-1 ] = "$" + pathSplit[ pathSplit.length-1 ];

						return dest + pathSplit.join( "/" );
					}
				}]
			}
		},

		postcss: {
			options: {
				processors : [
					require( 'autoprefixer' )( { browsers : [ 'defaults', 'IE >= 9' ] } )
				]
			},
			all: {
				src  : 'css/**/*.less.css'
			}
		},

		cssmin: {
			all: {
				expand : true,
				cwd    : 'css/',
				src    : [ '**/*.css', '!**/_*.min.css' ],
				ext    : '.min.css',
				dest   : 'css/',
				rename : function( dest, src ){
					var pathSplit = src.split( '/' );

					pathSplit[ pathSplit.length-1 ] = "_" + pathSplit[ pathSplit.length-2 ] + ".min.css";
					return dest + pathSplit.join( "/" );
				}
			}
		},

		clean: {
			all : {
				files : [{
					  src    : "js/**/_*.min.js"
					, filter : function( src ){ return src.match(/[\/\\]_[a-f0-9]{8}\./) !== null; }
				}, {
					  src    : "css/**/_*.min.css"
					, filter : function( src ){ return src.match(/[\/\\]_[a-f0-9]{8}\./) !== null; }
				}]
			}
		},

		rev: {
			options: {
				algorithm : 'md5',
				length    : 8
			},
			all: {
				files : [
					  { src : "js/**/_*.min.js"  }
					, { src : "css/**/_*.min.css" }
				]
			}
		},

		rename: {
			assets: {
				expand : true,
				cwd    : '',
				src    : '**/*._*.min.{js,css}',
				dest   : '',
				rename : function( dest, src ){
					var pathSplit = src.split( '/' );

					pathSplit[ pathSplit.length-1 ] = "_" + pathSplit[ pathSplit.length-1 ].replace( /\._/, "." );

					return dest + pathSplit.join( "/" );
				}
			}
		},

		watch: {
			all : {
				files : [ "css/**/*.less", "js/**/*.js", "!css/**/*.min.css", "!css/**/*.less.css", "!js/**/*.min.js" ],
				tasks : [ "default" ]
			}
		}
	} );
};
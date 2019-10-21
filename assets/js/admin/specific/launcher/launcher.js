( function( $ ){

	var $searchInput = $( "#preside-launcher-input" )
	  , $launcherContainer = $searchInput.closest( ".launcher-menu" )
	  , $resultsFooter = $launcherContainer.find( ".launcher-results-footer" ).first()
	  , rawDatasources = cfrequest.launcherDatasources
	  , convertedDatasources = []
	  , initializeLauncher, setupDatasources, prepareDatasource, initializeSearch
	  , abandonSearch, setupKeyboardShortcuts, setupFocusBehaviour, userIsTyping
	  , terminalIsActive, terminalIsPresent, getTerminal, isModifierPressed
	  , focusInSearchBox, itemSelectedHandler, renderResult, defaultResultTemplate
	  , resultTemplateWithShortcut, renderDatasourceHeader;

	initializeLauncher = function() {
		setupTemplates();
		if ( !setupDatasources() ) {
			return;
		}
		setupKeyboardShortcuts();
		setupFocusBehaviour();
		initializeTypeahead();
	};

	setupTemplates = function() {
		defaultResultTemplate = '<div class="launcher-result-container"><i class="fa fa-fw {{icon}}"></i> <span class="title">{{{text}}}</span><br><em class="subtitle">{{{description}}}</em></div>';
		resultTemplateWithShortcut = '<div class="launcher-result-container"><i class="fa fa-fw {{icon}}"></i> <span class="title">{{{text}}}</span><code class="pull-right"><i class="fa fa-fw fa-keyboard-o"></i> {{shortcut}}</code>';
	};

	setupDatasources = function() {
		if ( typeof rawDatasources === "undefined" || !$.isArray( rawDatasources ) || !rawDatasources.length ) {
			$launcherContainer.remove();
			return false;
		}

		var dsCount = rawDatasources.length, i, ds;

		for( i=0; i<dsCount; i++ ) {
			ds = prepareDatasource( rawDatasources[ i ] );
			if ( typeof ds === "object" ) {
				convertedDatasources.push( ds );
			}
		}

		return true;
	};

	prepareDatasource = function( ds ){
		var source, bh, helper={ bh:null };

		if ( typeof ds.javascriptSrc !== undefined && ds.javascriptSrc ) {
			$searchInput.trigger( "prepare" + ds.id + "Datasource", [ helper, ds ] );
			if ( typeof helper.bh === "object" && helper.bh != null ) {
				bh = helper.bh;
			} else {
				return;
			}
		} else if ( typeof ds.local !== undefined && $.isArray( ds.local ) && ds.local.length ) {
			bh = new Bloodhound( $.extend( {}, {
				  datumTokenizer : function(d) { return Bloodhound.tokenizers.whitespace( d.text); }
				, queryTokenizer: Bloodhound.tokenizers.whitespace
				, local : ds.local
			}, ds.bloodhoundOptions ) );
		} else if ( typeof ds.remoteUrl !== undefined && ds.remoteUrl.length ) {
			bh = new Bloodhound( $.extend( {}, {
				  datumTokenizer : function(d) { return Bloodhound.tokenizers.whitespace( d.text); }
				, queryTokenizer: Bloodhound.tokenizers.whitespace
				, remote : ds.remoteUrl
				, prefetch : typeof ds.prefetchUrl === "undefined" ? null : ds.prefetchUrl
				, dupDetector : function( remote, local ){ return remote.id == local.id }
			}, ds.bloodhoundOptions ) );
		} else {
			return;
		}
		bh.initialize();

		if ( ds.defaultSuggestions.length ) {
			ds.typeaheadOptions.minLength = 0;
			source = function(q, sync) {
				if ( q === '' ) {
					sync( ds.defaultSuggestions );
				} else {
					bh.ttAdapter()(q, sync);
				}
			}
		} else {
			if ( typeof ds.typeaheadOptions.minLength === "undefined" ) {
				ds.typeaheadOptions.minLength = 1;
			}
			source = bh.ttAdapter();
		}

		return $.extend( {}, {
			  name : ds.id
			, source : source
			, templates : { suggestion:renderResult, header:renderDatasourceHeader( ds ) }
			, displayKey : "text"
		}, ds.typeaheadOptions );
	};

	renderResult = function( result ) {
		if ( result.shortcut ) {
			return Mustache.render( resultTemplateWithShortcut, result );
		}

		return Mustache.render( defaultResultTemplate, result );
	};

	renderDatasourceHeader = function( ds ){
		var header = '<h4 class="launcher-result-datasource-header">';
		if ( ds.iconClass.length ) {
			header += '<i class="fa fa-fw ' + ds.iconClass + '"></i> ';
		}
		header += ds.title + '</h4>';
		return header;
	};

	setupKeyboardShortcuts = function(){
		$('body').keyup  ( '/', function( e ){ e.stopPropagation() } )
				 .keydown( '/', function( e ){ if( !userIsTyping() && !isModifierPressed( e ) ) { focusInSearchBox( e ); } } )
	};

	setupFocusBehaviour = function(){
		$searchInput.on( "focus", initializeSearch );
		$searchInput.on( "blur", abandonSearch );
	}

	initializeTypeahead = function(){
		var args = convertedDatasources;
		args.unshift({ minLength:0, highlight:true, autoselect:true });
		$searchInput.launcherTypeahead.apply( $searchInput, args );
		$searchInput.on( "typeahead:selected", function( e, result ){ itemSelectedHandler( result ); } );
		$launcherContainer.find( ".tt-dropdown-menu" ).append( $resultsFooter );
		$resultsFooter.removeClass( "hide" );

	};

	focusInSearchBox = function( e ){
		e.preventDefault();
		$searchInput.focus();
	};

	initializeSearch = function(){
		$launcherContainer.addClass( "active" );

		var placeholder = $searchInput.data( "placeholderLong" );
		if ( typeof placeholder !== "undefined" && placeholder.length ) {
			$searchInput.data( "placeholder", $searchInput.attr( "placeholder" ) );
			$searchInput.attr( "placeholder", placeholder );
		}

		var ev = $.Event( "keydown" );
		ev.keyCode = ev.which = 40;
		$searchInput.trigger( ev );
	};

	abandonSearch = function(){
		$searchInput.launcherTypeahead( "val", "" );
		$launcherContainer.removeClass( "active" );
		var placeholder = $searchInput.data( "placeholder" );
		if ( typeof placeholder !== "undefined" && placeholder.length ) {
			$searchInput.attr( "placeholder", placeholder );
		}
	};

	itemSelectedHandler = function( result ) {
		if ( typeof result.linkElement !== "undefined" && result.linkElement.length ) {
			result.linkElement.get(0).click();
		} else if ( typeof result.url !== "undefined" && result.url.length ) {
			$('body').presideLoadingSheen( true );
			window.location = result.url;
		}
	};

	userIsTyping = function(){
		var $focused = $(':focus')

		if ( terminalIsActive() ) {
			return true;
		}

		if ( !$focused.length ) {
			return false;
		}

		isInFormField = $.inArray( $focused.prop('nodeName'), [ 'INPUT','TEXTAREA' ] ) >= 0 && $.inArray( $focused.prop('type').toLowerCase(), [ 'checkbox','radio','submit','button' ] ) === -1;
		if ( isInFormField ) {
			return true;
		}
	};

	terminalIsPresent = function(){
		return typeof presideTerminal !== "undefined";
	};

	getTerminal = function(){
		return presideTerminal;
	};

	terminalIsActive = function(){
		return terminalIsPresent() && getTerminal().enabled();
	};

	isModifierPressed = function( e ) {
		return e.altKey || e.ctrlKey || e.metaKey || e.shiftKey;
	};

	initializeLauncher();

} )( presideJQuery );
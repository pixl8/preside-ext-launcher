( function( $ ){

	var emptyShortcutHint = $.trim( i18n.translateResource( "cms:hotkey.hint", { data:[""] } ) )
	  , linkToItem, getIcon, getShortcut, itemsAreTheSame
	  , thisPageDatasource, navigationDatasource
	  , genericLinkSearcherDatasource, getParentLineage;

	thisPageDatasource = function( ev, helper, config ){
		genericLinkSearcherDatasource( ".top-right-button-group a, .page-content a.btn, .page-content .nav-tabs a", true, helper, config );
	};

	navigationDatasource = function( ev, helper, config ){
		genericLinkSearcherDatasource( ".nav a", false, helper, config );
	};

	genericLinkSearcherDatasource = function( selector, autoShow, helper, config ){
		var items = config.local, source;

		$( selector ).each( function(){
			var item  = linkToItem( $( this ) )
			  , existing = false
			  , i;

			if ( !$.isEmptyObject( item ) ) {
				for( i=0; i<items.length; i++ ) {
					existing = itemsAreTheSame( item, items[ i ] );
					if ( existing ) {
						break;
					}
				}
				if ( !existing ) {
					items.push( item )
				}
			}
		} );

		if ( !items.length ) {
			return;
		}
		helper.bh = new Bloodhound( $.extend( {}, {
			  datumTokenizer : function(d) { return Bloodhound.tokenizers.whitespace( d.text); }
			, queryTokenizer: Bloodhound.tokenizers.whitespace
			, local : items
		}, config.bloodhoundOptions ) );

		if ( autoShow ) {
			config.typeaheadOptions.minLength = 0;
			config.typeaheadOptions.source = function(q, sync) {
				if ( q === '' ) {
					sync( items );
				} else {
					helper.bh.ttAdapter()(q, sync);
				}
			}
		} else {
			config.typeaheadOptions.source = helper.bh.ttAdapter();
		}
	};

	$( "#preside-launcher-input" ).on( "preparethispageDatasource", thisPageDatasource );
	$( "#preside-launcher-input" ).on( "preparenavigationDatasource", navigationDatasource );

	linkToItem = function( $link ) {
		var item={}, href;

		try {
			href = $link.attr( "href" );
		} catch( e ) {
			return item;
		}

		if ( $link.hasClass( "object-listing-data-export-button" ) ) {
			return item;
		}

		if ( typeof href !== "undefined" && href.length && href.indexOf( "#" ) != 0 ) {
			item = {
				  id : href
				, text : $.trim( $link.text() )
				, icon : getIcon( $link )
				, shortcut : getShortcut( $link )
				, linkElement : $link
				, description : getParentLineage( $link )
				, url : ""
			};

			if ( !item.shortcut.length && !item.description.length ) {
				item.description = $.trim( $link.attr( "title" ) );
				if ( item.description === emptyShortcutHint ) {
					item.description = "";
				}
			}
		}

		return item;
	};
	getIcon = function( $link, defaultIcon ) {
		var $parentLink = $link.parents( ".submenu" ).prev()
		  , icon;

		if ( $parentLink.length ) {
			icon = getIcon( $parentLink, "" );
			if ( icon.length ) {
				return icon;
			}
		}
		if ( typeof defaultIcon === "undefined" ) {
			defaultIcon = "fa-link";
		}

		var $icon = $link.find( ".fa" ).first();
		return $icon.length ? $icon.attr( "class" ) : defaultIcon;
	};
	getShortcut = function( $link ) {
		var shortcut = $link.data( "globalKey" );
		if ( shortcut && shortcut.length ) {
			return i18n.translateResource( "cms:hotkey.hint", { data : [ shortcut ] } )
		}
		shortcut = $link.data( "gotoKey" );
		if ( shortcut && shortcut.length ) {
			return i18n.translateResource( "cms:hotkey.hint", { data : [ "g+" + shortcut ] } )
		}
		return "";
	};
	getParentLineage = function( $link ){
		var parents = []
		  , $parentLink = $link.parents( ".submenu,.dropdown-menu" ).first().prev();

		while ( $parentLink.length ) {
			parents.unshift( $.trim( $parentLink.text() ) );
			$parentLink = $parentLink.parents( ".submenu" ).prev();
		}

		if ( parents.length ) {
			parents.push( $.trim( $link.text() ) );
		}

		return parents.join( ' <i class="fa fa-fw fa-angle-double-right"></i> ' );
	};
	itemsAreTheSame = function( item1, item2 ){
		return item1.id == item2.id && item1.icon == item2.icon && item1.shortcut == item2.shortcut;
	}

} )( presideJQuery );
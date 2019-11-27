component {
	property name="datamanagerService" inject="datamanagerService";
	property name="systemConfigurationService" inject="systemConfigurationService";
	property name="cache" inject="cachebox:template";

	private struct function config( event, rc, prc ) {
		var cacheKey = "launcher-navigation-items-" & event.getAdminUserId();
		var items = cache.get( cacheKey );

		if ( IsNull( local.items ) ) {
			items = [];

			var groupedObjects = datamanagerService.getGroupedObjects();

			for( var group in groupedObjects ) {
				for( var obj in group.objects ) {
					items.append( {
						  id          = "datamanager-" & obj.id
						, icon        = obj.iconClass
						, text        = group.title & ": " & obj.title
						, description = translateResource( uri="preside-objects.#obj.id#:description", defaultvalue="" )
						, url         = event.buildAdminLink( objectName=obj.id )
					} );
				}
			}
			if ( hasCmsPermission( "systemConfiguration.manage" ) ) {
				items.append( _getSystemConfigLauncherItems( argumentCollection=arguments ), true );
			}

			cache.set( cacheKey, items );
		}

		return { local=items, javascriptSrc=true };
	}

	private struct function recordRecentlyVisited( event, rc, prc ) {
		if ( event.getCurrentEvent().startsWith( "admin.sysconfig.category" ) && Len( Trim( rc.id ?: "" ) ) ) {
			return { categoryId=rc.id, subtype="sysconfig" };
		}
		if ( Len( Trim( prc.objectName ?: "" ) ) && !Len( Trim( prc.recordId ?: "" ) ) ) {
			return {
				  objectName = prc.objectName
				, subtype    = "datamanager"
			}
		}

		return {};
	}

	private struct function renderRecentlyVisitedItem( event, rc, prc, subtype="" ) {
		try {
			if ( arguments.subtype=="datamanager" && Len( Trim( arguments.objectName ?: "" ) ) ) {
				return {
					  id          = "recent-" & arguments.objectName
					, icon        = translateResource( uri="preside-objects.#arguments.objectName#:iconClass", defaultValue="fa-database" )
					, text        = translateResource( uri="preside-objects.#arguments.objectName#:title", defaultValue=arguments.objectName )
					, description = translateResource( uri="preside-objects.#arguments.objectName#:description", defaultValue="" )
					, url         = event.buildAdminLink( objectName=arguments.objectName )
				};
			}

			if ( arguments.subtype=="sysconfig" && Len( Trim( arguments.categoryId ?: "" ) ) ) {
				var baseTitle = translateResource( uri="launcher:datasource.navigation.sysconfig.item.title.base" )
				var configCategory = systemConfigurationService.getConfigCategory( arguments.categoryId );

				return {
					  id          = configCategory.getId()
					, icon        = translateResource( uri=configCategory.getIcon(), defaultValue="" )
					, text        = baseTitle.replace( "{title}", translateResource( uri=configCategory.getName(), defaultValue=configCategory.getId() ) )
					, description = translateResource( uri=configCategory.getDescription(), defaultValue="" )
					, url         = event.buildAdminLink( linkto="sysconfig.category", queryString="id=#arguments.categoryId#" )
				};
			}
		} catch( any e ) {
			// catch any problematic errors
			// such as old entries in the DB for no longer existing
			// items
		}

		return {};
	}

// helpers
	private array function _getSystemConfigLauncherItems( event, rc, prc ) {
		var configCategories = systemConfigurationService.listConfigCategories();
		var baseUrl = event.buildAdminLink( linkto="sysconfig.category", queryString="id={id}" );
		var baseTitle = translateResource( uri="launcher:datasource.navigation.sysconfig.item.title.base" )
		var launcherItems = [];

		for( var configCategory in configCategories ) {
			launcherItems.append( {
				  id          = configCategory.getId()
				, icon        = translateResource( uri=configCategory.getIcon(), defaultValue="" )
				, text        = baseTitle.replace( "{title}", translateResource( uri=configCategory.getName(), defaultValue=configCategory.getId() ) )
				, description = translateResource( uri=configCategory.getDescription(), defaultValue="" )
				, url         = baseUrl.replace( "{id}", configCategory.getId() )
			} );
		}

		launcherItems.sort( function( a, b ){
			return a.text > b.text ? 1 : -1;
		} );

		return launcherItems;
	}
}
component {

	property name="launcherService" inject="launcherService";
	property name="objects"         inject="coldbox:setting:launcher.objectDatasources";

	private array function config( event, rc, prc ) {
		return launcherService.getObjectDataDatasources();
	}

	private struct function recordRecentlyVisited( event, rc, prc ) {
		if ( Len( Trim( prc.objectName ?: "" ) ) && objects.findNoCase( prc.objectName ) && Len( Trim( prc.recordId ?: "" ) ) ) {
			return {
				  objectName = prc.objectName
				, recordId   = prc.recordId
			}
		}

		return {};
	}

	private struct function renderRecentlyVisitedItem( event, rc, prc, objectName="", recordId="" ) {
		if ( Len( Trim( arguments.recordId ) ) && Len( Trim( arguments.objectName ) ) ) {
			try {
				return {
					  id          = "recent-" & arguments.recordId
					, icon        = translateResource( uri="preside-objects.#arguments.objectName#:iconClass", defaultValue="fa-database" )
					, text        = renderLabel( arguments.objectName, arguments.recordId )
					, description = ""
					, url         = event.buildAdminLink( objectName=arguments.objectName, recordId=arguments.recordId )
				};
			} catch( any e ) {
				return {};
			}
		}

		return {};
	}
}
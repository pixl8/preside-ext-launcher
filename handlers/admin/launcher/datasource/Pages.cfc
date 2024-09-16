/**
 * @feature sitetree
 */
component extends="preside.system.base.AdminHandler" {

	property name="siteTreeService" inject="delayedInjector:siteTreeService";

	private struct function config( event, rc, prc ) {
		if ( !isFeatureEnabled( "sitetree" ) || !hasCmsPermission( "sitetree.navigate" ) ) {
			return {};
		}

		return {
			remoteUrl = event.buildAdminLink( linkto="launcher.datasource.pages.ajaxsearch", querystring="q=%QUERY" )
		};
	}

	public void function ajaxsearch( event, rc, prc ) {
		var preparedPages = [];
		var records = siteTreeService.getPagesForAjaxSelect(
			  maxRows      = rc.maxRows ?: 100
			, searchQuery  = rc.q       ?: ""
		);

		if ( records.recordCount ) {
			var baseUrl = event.buildAdminLink( objectName="page", recordId="{id}" );

			for( var record in records ) {
				preparedPages.append( {
					  id          = record.value
					, text        = record.text
					, icon        = translateResource( "page-types.#record.page_type#:iconclass", "fa-file-o" )
					, description = ( record.parent.len() ? '#record.parent# / #record.text#'  : "" )
					, url         = baseUrl.replace( "{id}", record.value )
				} );
			}
		}

		event.renderData( type="json", data=preparedPages );
	}

	private struct function recordRecentlyVisited( event, rc, prc ) {
		if ( event.getCurrentEvent().startsWith( "admin.sitetree." ) && IsStruct( prc.page ?: "" ) ) {
			return {
				  pageId = prc.page.id ?: ( rc.id ?: "" )
				, title  = prc.page.title ?: ""
				, parent = Len( Trim( prc.page.parent_page ?: "" ) ) ? renderLabel( "page", prc.page.parent_page ) : ""
				, icon   = translateResource( "page-types.#( prc.page.page_type ?: '' )#:iconclass", "fa-file-o" )
			};
		}

		return {};
	}

	private struct function renderRecentlyVisitedItem( event, rc, prc, pageId="", title="", parent="", icon="" ) {
		if ( Len( Trim( arguments.pageId ) ) ) {
			return {
				  id          = "recent-" & arguments.pageId
				, text        = arguments.title
				, icon        = arguments.icon
				, description = ( arguments.parent.len() ? '#arguments.parent# / #arguments.title#'  : "" )
				, url         = event.buildAdminLink( objectName="page", recordId=arguments.pageId )
			}
		}

		return {};
	}
}
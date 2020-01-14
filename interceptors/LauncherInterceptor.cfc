component extends="coldbox.system.Interceptor" {

	property name="autoInject"             inject="coldbox:setting:launcher.autoInjectInHeader" type="boolean";
	property name="launcherService"        inject="delayedInjector:launcherService";
	property name="recentlyVisitedService" inject="delayedInjector:launcherRecentlyVisitedService";

	public void function configure() {}

	public void function preLayoutRender( event, interceptData={} ) {
		var layout = Trim( interceptData.layout ?: "" );
		if ( layout == "admin" && event.isAdminRequest() ) {
			launcherService.prepareDatasources();
			if ( autoInject  ) {
				event.include( "/js/admin/specific/launcher/" )
				     .include( "/css/admin/specific/launcher/" );
			}
		}
	}

	public void function postLayoutRender( event, interceptData={} ) {
		if ( event.isAdminRequest() ) {
			var layout = Trim( interceptData.layout ?: "" );
			var prc    = event.getCollection( private=true );

			if ( autoInject && layout == "admin" ) {
				var launcher = getController().renderViewlet( event="admin.layout.launcher" );

				interceptData.renderedLayout = ( interceptData.renderedLayout ?: "" ).replaceNoCase( '<div class="navbar-header pull-right" role="navigation">', '#launcher#<div class="navbar-header pull-right" role="navigation">' );
			}

			recentlyVisitedService.recordRecentlyVisited();
		}
	}
}
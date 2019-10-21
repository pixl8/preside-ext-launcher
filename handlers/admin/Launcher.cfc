component extends="preside.system.base.AdminHandler" {

	property name="launcherService" inject="launcherService";

	public void function prefetchObjectRecordsForLauncher( event, rc, prc ) {
		event.renderData( type="json", data=launcherService.prefetchObjectRecordsForLauncher( argumentCollection=rc ) );
	}

	public void function searchObjectRecordsForLauncher( event, rc, prc ) {
		event.renderData( type="json", data=launcherService.searchObjectRecordsForLauncher( argumentCollection=rc ) );
	}

}
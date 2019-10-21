component {

	property name="recentlyVisitedService" inject="launcherRecentlyVisitedService";

	private struct function config( event, rc, prc ) {
		return { javascriptSrc = true };
	}
}
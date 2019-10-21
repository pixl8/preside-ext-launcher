component {

	property name="recentlyVisitedService" inject="launcherRecentlyVisitedService";

	private struct function config( event, rc, prc ) {
		var items = recentlyVisitedService.getRecentlyVisited();
		var defaults = [];
		for( var i=1; i<=5 && i<=items.len(); i++ ) {
			defaults.append( items[ i ] );
		}

		return {
			  local              = items
			, defaultSuggestions = defaults
		};
	}
}
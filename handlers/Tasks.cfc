component {

	property name="launcherRecentlyVisitedService" inject="launcherRecentlyVisitedService";

	/**
	 * Cleanup user last visited table (no more than max allowed per user)
	 *
	 * @displayName  Cleanup Launcher Last Visited Table
	 * @displayGroup Cleanup
	 * @schedule     0 32 3 * * *
	 * @feature      launcherExtension
	 */
	function cleanupLauncherRecentlyVisitedTable( event, rc, prc, logger ) {
		return launcherRecentlyVisitedService.cleanupExpired( arguments.logger );
	}
}

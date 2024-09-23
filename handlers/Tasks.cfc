component {

	property name="launcherRecentlyVisitedService" inject="launcherRecentlyVisitedService";

	/**
	 * Cleanup user last visited table (no more than max allowed per user)
	 *
	 * @displayName  Cleanup Launcher Last Visited Table
	 * @displayGroup cleanup
	 * @schedule     * 32 3 * *
	 * @feature      launcherExtension
	 */
	function cleanupLauncherRecentlyVisitedTable( event, rc, prc, logger ) {
		launcherRecentlyVisitedService.cleanupExpired( arguments.logger );
	}
}
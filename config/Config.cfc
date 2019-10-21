component {

	public void function configure( required struct config ) {
		var conf     = arguments.config;
		var settings = conf.settings ?: {};

		_setupLauncher( settings );
		_setupFeatures( settings );
		_setupInterceptors( conf );

	}

	private void function _setupLauncher( settings ) {
		settings.launcher = settings.launcher ?: {};
		settings.launcher.autoInjectInHeader = !IsBoolean( settings.launcher.autoInjectInHeader ?: "" ) || settings.launcher.autoInjectInHeader;

		settings.launcher.datasources = settings.launcher.datasources ?: [];
		settings.launcher.datasources.append( [
			  "thispage"
			, "recent"
			, "pages"
			, "objectdata"
			, "navigation"
		], true );

		settings.launcher.objectDatasources = settings.launcher.objectDatasources ?: [];

		settings.launcher.maxRecentlyVisitedItems = 20;
	}
	private void function _setupFeatures( settings ) {
		settings.features.launcherExtension = { enabled=true };
	}

	private void function _setupInterceptors( conf ) {
		conf.interceptors.prepend(
			{ class="app.extensions.preside-ext-launcher.interceptors.LauncherInterceptor", properties={} }
		);

		conf.interceptorSettings.customInterceptionPoints.append( "onPrepareDatasource" );
	}
}

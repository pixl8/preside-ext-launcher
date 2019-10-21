/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @dao.inject presidecms:object:launcher_recently_visited
	 * @configuredDatasources.inject coldbox:setting:launcher.datasources
	 * @configuredObjectDatasources.inject coldbox:setting:launcher.objectDatasources
	 * @maxRecentlyVisitedItems.inject coldbox:setting:launcher.maxRecentlyVisitedItems
	 *
	 */
	public any function init(
		  required any     dao
		, required array   configuredDatasources
		, required array   configuredObjectDatasources
		, required numeric maxRecentlyVisitedItems
	) {
		_setDao( arguments.dao );
		_setConfiguredDatasources( arguments.configuredDatasources );
		_setConfiguredObjectDatasources( arguments.configuredObjectDatasources );
		_setMaxRecentlyVisitedItems( arguments.maxRecentlyVisitedItems );

		return this;
	}

// PUBLIC API METHODS
	public array function getRecentlyVisited( boolean rendered=true ) {
		var dao = _getDao();
		var userId = $getAdminLoggedInUserId();
		var results = [];

		if ( !userId.len() ) {
			return [];
		}

		var records = dao.selectData(
			  filter  = { user=userId }
			, orderBy = "datecreated desc"
		);
		for( var record in records ) {
			var result = {
				  datasource = record.datasource
				, dataHash   = record.data_hash
			};
			try {
				result.append( DeSerializeJson( record.data ) );
			} catch( any e ) {}

			if ( arguments.rendered ) {
				result = renderRecentlyVisitedResult( result );
				if ( !result.count() ) {
					continue;
				}
			}

			results.append( result );
		}

		return results;
	}

	public struct function renderRecentlyVisitedResult( required struct result ) {
		var coldbox = $getColdbox();
		var renderHandler = "admin.launcher.datasource.#result.datasource#.renderRecentlyVisitedItem";

		if ( coldbox.handlerExists( renderHandler ) ) {
			var item = coldbox.runEvent(
				  event          = renderHandler
				, eventArguments = result
				, private        = true
				, prePostExempt  = true
			);

			if ( !IsStruct( local.item ?: "" ) || !item.count() ) {
				return {};
			}

			return {
				  id          = local.item.id          ?: ""
				, text        = local.item.text        ?: ""
				, description = local.item.description ?: ""
				, icon        = local.item.icon        ?: ""
				, url         = local.item.url         ?: ""
			};
		}

		return {};
	}

	public void function recordRecentlyVisited() {
		for( var datasource in _getConfiguredDatasources() ) {
			if ( recordRecentlyVisitedForDatasource( datasource ) ) {
				break;
			}
		}
	}

	public boolean function recordRecentlyVisitedForDatasource( required string datasource ) {
		var coldbox = $getColdbox();
		var recentlyVisitedHandler = "admin.launcher.datasource.#datasource#.recordRecentlyVisited";

		if ( coldbox.handlerExists( recentlyVisitedHandler ) ) {
			var recentlyVisitedData = coldbox.runEvent( event=recentlyVisitedHandler, private=true, prepostExempt=true );
			if ( IsStruct( local.recentlyVisitedData ?: "" ) && recentlyVisitedData.count() ) {
				_saveRecentlyVisited( arguments.datasource, recentlyVisitedData )
				return true;
			}
		}

		return false;
	}

	private void function _saveRecentlyVisited( required string datasource, required struct data ) {
		var dao      = _getDao();
		var userId   = $getAdminLoggedInUserId();

		if ( !userId.len() ) {
			return;
		}
		var serializedData = SerializeJson( arguments.data );
		var dataHash       = Hash( serializedData );

		dao.deleteData( filter={
			  datasource = arguments.datasource
			, data_hash  = dataHash
			, user       = userId
		} );

		var recentlyVisited = getRecentlyVisited( rendered=false );
		while( recentlyVisited.len() >= _getMaxRecentlyVisitedItems() ) {
			dao.deleteData( filter={
				  datasource  = recentlyVisited[ recentlyVisited.len() ].datasource
				, data_hash   = recentlyVisited[ recentlyVisited.len() ].dataHash
				, user        = userId
			} );
			recentlyVisited.deleteAt( recentlyVisited.len() );
		}

		dao.insertData( {
			  datasource = arguments.datasource
			, user       = userId
			, data_hash  = dataHash
			, data       = serializedData
		} );
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS
	private any function _getDao() {
		return _dao;
	}
	private void function _setDao( required any dao ) {
		_dao = arguments.dao;
	}

	private array function _getConfiguredObjectDatasources() {
		return _configuredObjectDatasources;
	}
	private void function _setConfiguredObjectDatasources( required array configuredObjectDatasources ) {
		_configuredObjectDatasources = arguments.configuredObjectDatasources;
		for( var i=1; i<=_configuredObjectDatasources.len(); i++ ) {
			if ( !IsSimpleValue( _configuredObjectDatasources[ i ] ) ) {
				_configuredObjectDatasources[ i ] = _configuredObjectDatasources[ i ].id ?: "";
			}
		}
	}

	private numeric function _getMaxRecentlyVisitedItems() {
		return _maxRecentlyVisitedItems;
	}
	private void function _setMaxRecentlyVisitedItems( required numeric maxRecentlyVisitedItems ) {
		_maxRecentlyVisitedItems = arguments.maxRecentlyVisitedItems;
	}

	private array function _getConfiguredDatasources() {
		return _configuredDatasources;
	}
	private void function _setConfiguredDatasources( required array configuredDatasources ) {
		_configuredDatasources = arguments.configuredDatasources;
	}

}
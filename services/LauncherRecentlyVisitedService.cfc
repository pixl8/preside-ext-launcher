/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @dao.inject                         presidecms:object:launcher_recently_visited
	 * @sqlRunner.inject                   sqlRunner
	 * @configuredDatasources.inject       coldbox:setting:launcher.datasources
	 * @configuredObjectDatasources.inject coldbox:setting:launcher.objectDatasources
	 * @maxRecentlyVisitedItems.inject     coldbox:setting:launcher.maxRecentlyVisitedItems
	 *
	 */
	public any function init(
		  required any     dao
		, required any     sqlRunner
		, required array   configuredDatasources
		, required array   configuredObjectDatasources
		, required numeric maxRecentlyVisitedItems
	) {
		_setDao( arguments.dao );
		_setSqlRunner( arguments.sqlRunner );
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
			, maxrows = _getMaxRecentlyVisitedItems()
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
		var userId = $getAdminLoggedInUserId();

		if ( Len( userId ) ) {
			thread id="recordlauncheractivity-#CreateUUId()#" userId=userId {
				for( var datasource in _getConfiguredDatasources() ) {
					if ( recordRecentlyVisitedForDatasource( datasource, attributes.userId ) ) {
						break;
					}
				}
			}
		}
	}

	public boolean function recordRecentlyVisitedForDatasource( required string datasource, required string userId ) {
		var coldbox = $getColdbox();
		var recentlyVisitedHandler = "admin.launcher.datasource.#datasource#.recordRecentlyVisited";

		if ( coldbox.handlerExists( recentlyVisitedHandler ) ) {
			var recentlyVisitedData = coldbox.runEvent( event=recentlyVisitedHandler, private=true, prepostExempt=true );
			if ( IsStruct( local.recentlyVisitedData ?: "" ) && recentlyVisitedData.count() ) {
				_saveRecentlyVisited( arguments.datasource, recentlyVisitedData, arguments.userId )
				return true;
			}
		}

		return false;
	}

	private void function _saveRecentlyVisited( required string datasource, required struct data, required string userId ) {
		var dao            = _getDao();
		var serializedData = SerializeJson( arguments.data );
		var dataHash       = Hash( serializedData );
		var filter         = {
			  datasource = arguments.datasource
			, data_hash  = dataHash
			, user       = arguments.userId
		};

		var updated = dao.updateData( filter=filter, data={ datecreated=Now() } );
		if ( updated > 0 ) {
			return;
		}

		try {
			dao.insertData( {
				  datasource = arguments.datasource
				, user       = arguments.userId
				, data_hash  = dataHash
				, data       = serializedData
			} );
		} catch( database e ) { /* race conditions could happen here, not really a problem, just ignore */ }
	}

	public boolean function cleanupExpired( logger ) {
		var maxPerUser = _getMaxRecentlyVisitedItems();

		arguments.logger?.info( "Cleaning up recently visited items for launcher..." );
		arguments.logger?.info( ">> Maximum of #maxPerUser# launcher history items per user" );

		var result = _getSqlRunner().runSql(
			  dsn        = _getDao().getDsn()
			, returnType = "info"
			, params     = [ { name="maxVisitedItems", type="int", value=maxPerUser } ]
			, sql        = "
				DELETE lrv FROM pobj_launcher_recently_visited lrv
				INNER JOIN (
					SELECT
						user,
						datasource,
						data_hash,
						ROW_NUMBER() OVER( PARTITION BY user ORDER BY datecreated DESC ) AS history_index
					FROM
						pobj_launcher_recently_visited
				) lrv_ranked
				ON  lrv_ranked.user = lrv.user
				AND lrv_ranked.datasource = lrv.datasource
				AND lrv_ranked.data_hash = lrv.data_hash
				WHERE history_index > :maxVisitedItems"
		);

		arguments.logger?.info( ">> #Val( result.recordCount ?: 0 )# launcher history items deleted" );
		arguments.logger?.info( "Finished cleaning launcher history." );

		return true;
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS
	private any function _getDao() {
		return _dao;
	}
	private void function _setDao( required any dao ) {
		_dao = arguments.dao;
	}

	private any function _getSqlRunner() {
		return _sqlRunner;
	}
	private void function _setSqlRunner( required any sqlRunner ) {
		_sqlRunner = arguments.sqlRunner;
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
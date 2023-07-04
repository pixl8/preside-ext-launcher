/**
 * @versioned      false
 * @nolabel        true
 * @noid           true
 * @nodatemodified true
 */
component {
	property name="user" relationship="many-to-one" relatedto="security_user" required=true uniqueindexes="uservisit|1" indexes="user" ondelete="cascade";
	property name="datasource" type="string" dbtype="varchar" maxlength=100 required=true uniqueindexes="uservisit|2";
	property name="data_hash"  type="string" dbtype="varchar" maxlength=100 required=true uniqueindexes="uservisit|3";
	property name="data"       type="string" dbtype="text" required=true;
}
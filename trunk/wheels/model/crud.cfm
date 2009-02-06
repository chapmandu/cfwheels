<cffunction name="findByKey" returntype="any" access="public" output="false" hint="Fetches the requested record and returns it as an object. Throws an error if no record is found.">
	<cfargument name="key" type="any" required="true" hint="Primary key value(s) of record to fetch. Separate with comma if passing in multiple primary key values.">
	<cfargument name="select" type="string" required="false" default="" hint="See documentation for `findAll`">
	<cfargument name="cache" type="any" required="false" default="" hint="See documentation for `findAll`">
	<cfargument name="reload" type="boolean" required="false" default="#application.settings.get.reload#" hint="See documentation for `findAll`">
	<cfargument name="parameterize" type="any" required="false" default="#application.settings.get.parameterize#" hint="See documentation for `findAll`">
	<cfargument name="$create" type="boolean" required="false" default="true">
	<cfargument name="$softDeleteCheck" type="boolean" required="false" default="true">
	<cfscript>
		var returnValue = "";
		arguments.where = $keyWhereString(values=arguments.key);
		StructDelete(arguments, "key");
		returnValue = findOne(argumentCollection=arguments);
	</cfscript>
	<cfreturn returnValue>
</cffunction>

<cffunction name="findOne" returntype="any" access="public" output="false" hint="Fetches the first record found based on the `WHERE` and `ORDER BY` clauses and returns it as an object. Throws an error if no record is found.">
	<cfargument name="where" type="string" required="false" default="" hint="See documentation for `findAll`">
	<cfargument name="order" type="string" required="false" default="" hint="See documentation for `findAll`">
	<cfargument name="select" type="string" required="false" default="" hint="See documentation for `findAll`">
	<cfargument name="cache" type="any" required="false" default="" hint="See documentation for `findAll`">
	<cfargument name="reload" type="boolean" required="false" default="#application.settings.findOne.reload#" hint="See documentation for `findAll`">
	<cfargument name="parameterize" type="any" required="false" default="#application.settings.findOne.parameterize#" hint="See documentation for `findAll`">
	<cfargument name="$create" type="boolean" required="false" default="true">
	<cfargument name="$softDeleteCheck" type="boolean" required="false" default="true">
	<cfscript>
		var loc = {};
		loc.create = arguments.$create;
		arguments.maxRows = 1;
		StructDelete(arguments, "$create");
		loc.query = findAll(argumentCollection=arguments);
		if (loc.create)
		{
			if (loc.query.recordCount IS NOT 0)
				loc.returnValue = $createInstance(properties=loc.query, persisted=true);
			else
				$throw(type="Wheels.RecordNotFound", message="The requested record could not be found in the database.", extendedInfo="Make sure that the record exists in the database or catch this error in your code.");
		}
		else
		{
			loc.returnValue = loc.query;
		}
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="findAll" returntype="any" access="public" output="false" hint="Returns the records matching the arguments as a `cfquery` result set. If you don't specify table names in the `select`, `where` and `order` arguments Wheels will guess what column you intended to get back and prepend the table name to your supplied column names. If you don't specify the `select` argument it will default to get all columns.">
	<cfargument name="where" type="string" required="false" default="" hint="String to use in `WHERE` clause of query">
	<cfargument name="order" type="string" required="false" default="" hint="String to use in `ORDER BY` clause of query">
	<cfargument name="select" type="string" required="false" default="" hint="String to use in `SELECT` clause of query">
	<cfargument name="include" type="string" required="false" default="" hint="Associations that should be included">
	<cfargument name="maxRows" type="numeric" required="false" default="-1" hint="Maximum number of records to retrieve">
	<cfargument name="page" type="numeric" required="false" default=0 hint="Page to get records for in pagination">
	<cfargument name="perPage" type="numeric" required="false" default=10 hint="Records per page in pagination">
	<cfargument name="count" type="numeric" required="false" default=0 hint="Total records in pagination (when not supplied Wheels will do a `COUNT` query to get this value)">
	<cfargument name="handle" type="string" required="false" default="query" hint="Handle to use for the query in pagination">
	<cfargument name="cache" type="any" required="false" default="" hint="Minutes to cache the query for">
	<cfargument name="reload" type="boolean" required="false" default="#application.settings.findAll.reload#" hint="Set to `true` to force Wheels to fetch a new object from the database even though an identical query has been run in the same request">
	<cfargument name="parameterize" type="any" required="false" default="#application.settings.findAll.parameterize#" hint="Set to `true` to use `cfqueryparam` on all columns or pass in a list of property names to use `cfqueryparam` on those only">
	<cfargument name="$limit" type="numeric" required="false" default=0>
	<cfargument name="$offset" type="numeric" required="false" default=0>
	<cfargument name="$softDeleteCheck" type="boolean" required="false" default="true">
	<cfscript>
		var loc = {};

		// count records and get primary keys for pagination
		if (arguments.page)
		{
			if (!Len(arguments.order))
				$throw(type="Wheels.InvalidPagination", message="Cannot use pagination without order.", extendedInfo="Specify what property to order by using the 'order' argument to 'findAll'.");
			if (Len(arguments.include))
				loc.distinct = true;
			else
				loc.distinct = false;
			if (arguments.count GT 0)
				loc.totalRecords = arguments.count;
			else
				loc.totalRecords = this.count(distinct=loc.distinct, where=arguments.where, include=arguments.include, reload=arguments.reload, cache=arguments.cache);
			loc.currentPage = arguments.page;
			if (loc.totalRecords IS 0)
				loc.totalPages = 0;
			else
				loc.totalPages = Ceiling(loc.totalRecords/arguments.perPage);
			loc.limit = arguments.perPage;
			loc.offset = (arguments.perPage * arguments.page) - arguments.perPage;
			if ((loc.limit + loc.offset) GT loc.totalRecords)
				loc.limit = loc.totalRecords - loc.offset;
			loc.values = findAll($limit=loc.limit, $offset=loc.offset, select=variables.wheels.class.keys, where=arguments.where, order=arguments.order, include=arguments.include, reload=arguments.reload, cache=arguments.cache);
			if (!loc.values.recordCount)
			{
				loc.returnValue = QueryNew("");
			}
			else
			{
				arguments.where = "";
				loc.iEnd = ListLen(variables.wheels.class.keys);
				for (loc.i=1; loc.i LTE loc.iEnd; loc.i=loc.i+1)
				{
					loc.property = ListGetAt(variables.wheels.class.keys, loc.i);
					loc.list = Evaluate("QuotedValueList(loc.values.#loc.property#)");
					arguments.where = ListAppend(arguments.where, "#variables.wheels.class.tableName#.#loc.property# IN (#loc.list#)", Chr(7));
				}
				arguments.where = Replace(arguments.where, Chr(7), " AND ", "all");
				arguments.$softDeleteCheck = false;
			}
			// store pagination info in the request scope so all pagination methods can access it
			request.wheels[arguments.handle] = {};
			request.wheels[arguments.handle].currentPage = loc.currentPage;
			request.wheels[arguments.handle].totalPages = loc.totalPages;
			request.wheels[arguments.handle].totalRecords = loc.totalRecords;
		}

		if (!StructKeyExists(loc, "returnValue"))
		{
			// make the where clause generic for use in caching
			loc.originalWhere = arguments.where;
			arguments.where = REReplace(arguments.where, variables.wheels.class.whereRegex, "\1?\8" , "all");

			// get info from cache when available, otherwise create the generic select, from, where and order by clause
			loc.queryShellKey = variables.wheels.class.name & $hashStruct(arguments);
			loc.sql = $getFromCache(loc.queryShellKey, "sql", "internal");
			if (!IsArray(loc.sql))
			{
				loc.sql = [];
				loc.sql = $addSelectClause(sql=loc.sql, select=arguments.select, include=arguments.include);
				loc.sql = $addFromClause(sql=loc.sql, include=arguments.include);
				loc.sql = $addWhereClause(sql=loc.sql, where=loc.originalWhere, include=arguments.include, $softDeleteCheck=arguments.$softDeleteCheck);
				loc.sql = $addOrderByClause(sql=loc.sql, order=arguments.order, include=arguments.include);
				$addToCache(loc.queryShellKey, loc.sql, 86400, "sql", "internal");
			}

			// add where clause parameters to the generic sql info
			loc.sql = $addWhereClauseParameters(sql=loc.sql, where=loc.originalWhere);

			// return existing query result if it has been run already in current request, otherwise pass off the sql array to the query
			loc.queryKey = "wheels" & variables.wheels.class.name & $hashStruct(arguments) & loc.originalWhere;
			if (!arguments.reload && StructKeyExists(request, loc.queryKey))
			{
				loc.findAll = request[loc.queryKey];
			}
			else
			{
				loc.finderArgs = {};
				loc.finderArgs.sql = loc.sql;
				loc.finderArgs.maxRows = arguments.maxRows;
				loc.finderArgs.parameterize = arguments.parameterize;
				loc.finderArgs.limit = arguments.$limit;
				loc.finderArgs.offset = arguments.$offset;
				if (Len(arguments.cache) && application.settings.environment IS "production")
				{
					if (IsBoolean(arguments.cache) && arguments.cache)
						loc.finderArgs.cachedWithin = CreateTimeSpan(0,0,application.settings.defaultCacheTime,0);
					else if (IsNumeric(arguments.cache))
						loc.finderArgs.cachedWithin = CreateTimeSpan(0,0,arguments.cache,0);
				}
				loc.findAll = application.wheels.adapter.query(argumentCollection=loc.finderArgs);
				request[loc.queryKey] = loc.findAll; // <- store in request cache so we never run the exact same query twice in the same request
			}
			loc.returnValue = loc.findAll.query;
		}
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="exists" returntype="boolean" access="public" output="false" hint="Checks if a record exists in the table. You can pass in a primary key value or a string to the `WHERE` clause.">
	<cfargument name="key" type="any" required="false" default="" hint="See documentation for `findByKey`">
	<cfargument name="where" type="string" required="false" default="" hint="See documentation for `findAll`">
	<cfargument name="reload" type="boolean" required="false" default="#application.settings.exists.reload#" hint="See documentation for `findAll`">
	<cfargument name="parameterize" type="any" required="false" default="#application.settings.exists.parameterize#" hint="See documentation for `findAll`">
	<cfscript>
		var loc = {};
		if (application.settings.environment != "production")
			if (!Len(arguments.key) && !Len(arguments.where))
				$throw(type="Wheels", message="Incorrect Arguments", extendedInfo="You have to pass in either 'key' or 'where'.");
		if (Len(arguments.where))
			loc.returnValue = findOne(where=arguments.where, reload=arguments.reload, $create=false).recordCount == 1;
		else
			loc.returnValue = findByKey(key=arguments.key, reload=arguments.reload, $create=false).recordCount == 1;
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="updateByKey" returntype="boolean" access="public" output="false" hint="Finds the record with the supplied key and saves it (if the validation permits it) with the supplied properties or named arguments. Property names and values can be passed in either using named arguments or as a struct to the properties argument. Returns true if the save was successful, false otherwise.">
	<cfargument name="key" type="any" required="true" hint="See documentation for `findByKey`">
	<cfargument name="properties" type="struct" required="false" default="#StructNew()#" hint="See documentation for `new`">
	<cfscript>
		var returnValue = "";
		arguments.where = $keyWhereString(values=arguments.key);
		StructDelete(arguments, "key");
		returnValue = updateOne(argumentCollection=arguments);
	</cfscript>
	<cfreturn returnValue>
</cffunction>

<cffunction name="updateOne" returntype="boolean" access="public" output="false" hint="Gets an object based on conditions and updates it with the supplied properties.">
	<cfargument name="where" type="string" required="false" default="" hint="See documentation for `findAll`">
	<cfargument name="order" type="string" required="false" default="" hint="See documentation for `findAll`">
	<cfargument name="properties" type="struct" required="false" default="#StructNew()#" hint="See documentation for `new`">
	<cfscript>
		var loc = {};
		loc.object = findOne(where=arguments.where, order=arguments.order);
		StructDelete(arguments, "where");
		StructDelete(arguments, "order");
		if (IsObject(loc.object))
			loc.returnValue = loc.object.update(argumentCollection=arguments);
		else
			loc.returnValue = false;
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="updateAll" returntype="numeric" access="public" output="false" hint="Updates all properties for the records that match the where argument. Property names and values can be passed in either using named arguments or as a struct to the properties argument. By default objects will not be instantiated and therefore callbacks and validations are not invoked. You can change this behavior by passing in instantiate=true. Returns the number of records that were updated.">
	<cfargument name="where" type="string" required="false" default="" hint="See documentation for `findAll`">
	<cfargument name="include" type="string" required="false" default="" hint="See documentation for `findAll`">
	<cfargument name="properties" type="struct" required="false" default="#StructNew()#" hint="See documentation for `new`">
	<cfargument name="parameterize" type="any" required="false" default="#application.settings.updateAll.parameterize#" hint="See documentation for `findAll`">
	<cfargument name="instantiate" type="boolean" required="false" default="#application.settings.updateAll.instantiate#" hint="Whether or not to instantiate the object(s) before the update">
	<cfargument name="$softDeleteCheck" type="boolean" required="false" default="true">
	<cfscript>
		var loc = {};
		loc.namedArgs = "where,include,properties,parameterize,instantiate,$softDeleteCheck";
		for (loc.key in arguments)
		{
			if (!ListFindNoCase(loc.namedArgs, loc.key))
				arguments.properties[loc.key] = arguments[loc.key];
		}
		if (arguments.instantiate)
		{
    		// find and instantiate each object and call its update function
			loc.records = findAll(select=variables.wheels.class.propertyList, where=arguments.where, include=arguments.include, parameterize=arguments.parameterize, $softDeleteCheck=arguments.$softDeleteCheck);
			loc.iEnd = loc.records.recordCount;
			loc.returnValue = 0;
			for (loc.i=1; loc.i LTE loc.iEnd; loc.i=loc.i+1)
			{
				loc.object = $createInstance(properties=loc.records, row=loc.i, persisted=true);
				if (loc.object.update(properties=arguments.properties, parameterize=arguments.parameterize))
					loc.returnValue = loc.returnValue + 1;
			}
		}
		else
		{
			// do a regular update query
			loc.sql = [];
			ArrayAppend(loc.sql, "UPDATE #variables.wheels.class.tableName# SET");
			loc.pos = 0;
			for (loc.key in arguments.properties)
			{
				loc.pos = loc.pos + 1;
				ArrayAppend(loc.sql, "#variables.wheels.class.properties[loc.key].column# = ");
				loc.param = {value=arguments.properties[loc.key], type=variables.wheels.class.properties[loc.key].type};
				ArrayAppend(loc.sql, loc.param);
				if (StructCount(arguments.properties) GT loc.pos)
					ArrayAppend(loc.sql, ",");
			}
			loc.sql = $addWhereClause(sql=loc.sql, where=arguments.where, include=arguments.include, $softDeleteCheck=arguments.$softDeleteCheck);
			loc.sql = $addWhereClauseParameters(sql=loc.sql, where=arguments.where);
			loc.upd = application.wheels.adapter.query(sql=loc.sql, parameterize=arguments.parameterize);
			loc.returnValue = loc.upd.result.recordCount;
		}
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="deleteByKey" returntype="boolean" access="public" output="false" hint="Finds the record with the supplied key and deletes it. Returns true on successful deletion of the row, false otherwise.">
	<cfargument name="key" type="any" required="true" hint="See documentation for `findByKey`">
	<cfscript>
		var loc = {};
		loc.where = $keyWhereString(values=arguments.key);
		loc.returnValue = deleteOne(where=loc.where);
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="deleteOne" returntype="boolean" access="public" output="false" hint="Gets an object based on conditions and deletes it.">
	<cfargument name="where" type="string" required="false" default="" hint="See documentation for `findAll`">
	<cfargument name="order" type="string" required="false" default="" hint="See documentation for `findAll`">
	<cfscript>
		var loc = {};
		loc.object = findOne(where=arguments.where, order=arguments.order);
		if (IsObject(loc.object))
			loc.returnValue = loc.object.delete();
		else
			loc.returnValue = false;
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="deleteAll" returntype="numeric" access="public" output="false" hint="Deletes all records that match the where argument. By default objects will not be instantiated and therefore callbacks and validations are not invoked. You can change this behavior by passing in instantiate=true. Returns the number of records that were deleted.">
	<cfargument name="where" type="string" required="false" default="" hint="See documentation for `findAll`">
	<cfargument name="include" type="string" required="false" default="" hint="See documentation for `findAll`">
	<cfargument name="parameterize" type="any" required="false" default="#application.settings.deleteAll.parameterize#" hint="See documentation for `findAll`">
	<cfargument name="instantiate" type="boolean" required="false" default="#application.settings.deleteAll.instantiate#" hint="Whether or not to instantiate the object(s) before deletion">
	<cfargument name="$softDeleteCheck" type="boolean" required="false" default="true">
	<cfscript>
		var loc = {};
		if (arguments.instantiate)
		{
    		// find and instantiate each object and call its delete function
			loc.records = findAll(select=variables.wheels.class.propertyList, where=arguments.where, include=arguments.include, parameterize=arguments.parameterize, $softDeleteCheck=arguments.$softDeleteCheck);
			loc.iEnd = loc.records.recordCount;
			loc.returnValue = 0;
			for (loc.i=1; loc.i LTE loc.iEnd; loc.i=loc.i+1)
			{
				loc.object = $createInstance(properties=loc.records, row=loc.i, persisted=true);
				if (loc.object.delete(parameterize=arguments.parameterize))
					loc.returnValue = loc.returnValue + 1;
			}
		}
		else
		{
			// do a regular delete query
			loc.sql = [];
			loc.sql = $addDeleteClause(sql=loc.sql);
			loc.sql = $addWhereClause(sql=loc.sql, where=arguments.where, include=arguments.include, $softDeleteCheck=arguments.$softDeleteCheck);
			loc.sql = $addWhereClauseParameters(sql=loc.sql, where=arguments.where);
			loc.del = application.wheels.adapter.query(sql=loc.sql, parameterize=arguments.parameterize);
			loc.returnValue = loc.del.result.recordCount;
		}
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="save" returntype="boolean" access="public" output="false" hint="Saves the object if it passes validation and callbacks. Returns `true` if the object was saved successfully to the database.">
	<cfargument name="parameterize" type="any" required="false" default="#application.settings.save.parameterize#" hint="See documentation for `findAll`">
	<cfscript>
		var returnValue = false;
		clearErrors();
		if ($callback("beforeValidation"))
		{
			if ($isNew())
			{
				if ($callback("beforeValidationOnCreate") && $validate("onCreate") && $callback("beforeValidation") && $validate("onSave") && $callback("afterValidation") && $callback("beforeSave") && $callback("beforeCreate") && $create(parameterize=arguments.parameterize) && $callback("afterCreate") && $callback("afterSave"))
					returnValue = true;
			}
			else
			{
				if ($callback("beforeValidationOnUpdate") && $validate("onUpdate") && $callback("beforeValidation") && $validate("onSave") && $callback("afterValidation") && $callback("beforeSave") && $callback("beforeUpdate") && $update(parameterize=arguments.parameterize) && $callback("afterUpdate") && $callback("afterSave"))
					returnValue = true;
			}
		}
	</cfscript>
	<cfreturn returnValue>
</cffunction>

<cffunction name="update" returntype="boolean" access="public" output="false" hint="Updates the object with the supplied properties and saves it to the database. Returns true if the object was saved successfully to the database and false otherwise.">
	<cfargument name="properties" type="struct" required="false" default="#StructNew()#" hint="See documentation for `new`">
	<cfargument name="parameterize" type="any" required="false" default="#application.settings.update.parameterize#" hint="See documentation for `findAll`">
	<cfscript>
		var loc = {};
		for (loc.key in arguments)
			if (loc.key != "properties" && loc.key != "parameterize")
				arguments.properties[loc.key] = arguments[loc.key];
		for (loc.key in arguments.properties)
			this[loc.key] = arguments.properties[loc.key];
		loc.returnValue = save(parameterize=arguments.parameterize);
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="delete" returntype="boolean" access="public" output="false" hint="Deletes the object which means the row is deleted from the database (unless prevented by a `beforeDelete` callback). Returns true on successful deletion of the row, false otherwise.">
	<cfargument name="parameterize" type="any" required="false" default="#application.settings.delete.parameterize#" hint="See documentation for `findAll`">
	<cfscript>
		var loc = {};
		loc.proceed = true;
		for (loc.i=1; loc.i LTE ArrayLen(variables.wheels.class.callbacks.beforeDelete); loc.i=loc.i+1)
       	{
        	loc.proceed = $invoke(method=variables.wheels.class.callbacks.beforeDelete[loc.i]);
            if (StructKeyExists(loc, "proceed") && !loc.proceed)
            	break;
		}
		if (loc.proceed)
		{
        	loc.sql = [];
        	loc.sql = $addDeleteClause(sql=loc.sql);
            loc.sql = $addKeyWhereClause(sql=loc.sql);
            loc.del = application.wheels.adapter.query(sql=loc.sql, parameterize=arguments.parameterize);
            loc.proceed = true;
			for (loc.i=1; loc.i LTE ArrayLen(variables.wheels.class.callbacks.afterDelete); loc.i=loc.i+1)
            {
            	loc.proceed = $invoke(method=variables.wheels.class.callbacks.afterDelete[loc.i]);
                if (StructKeyExists(loc, "proceed") && !loc.proceed)
                	break;
			}
 			if (loc.proceed)
            	loc.returnValue = true;
			else
            	loc.returnValue = false;
		}
        else
        {
        	loc.returnValue = false;
		}
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="new" returntype="any" access="public" output="false" hint="Creates a new object based on supplied properties and returns it. The object is not saved to the database, it only exists in memory. Property names and values can be passed in either using named arguments or as a struct to the `properties` argument.">
	<cfargument name="properties" type="struct" required="false" default="#StructNew()#" hint="Properties for the object">
	<cfscript>
		var loc = {};
		for (loc.key in arguments)
			if (loc.key != "properties")
				arguments.properties[loc.key] = arguments[loc.key];
		loc.returnValue = $createInstance(properties=arguments.properties, persisted=false);
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="create" returntype="any" access="public" output="false" hint="Creates a new object, saves it to the database (if the validation permits it) and returns it. If the validation fails, the unsaved object (with errors added to it) is still returned. Property names and values can be passed in either using named arguments or as a struct to the `properties` argument.">
	<cfargument name="properties" type="struct" required="false" default="#StructNew()#" hint="See documentation for `new`">
	<cfscript>
		var returnValue = "";
		returnValue = new(argumentCollection=arguments);
		returnValue.save();
	</cfscript>
	<cfreturn returnValue>
</cffunction>

<cffunction name="changedProperties" returntype="string" access="public" output="false" hint="Returns a list of the object properties that have been changed but not yet saved to the database.">
	<cfscript>
		var loc = {};
		loc.returnValue = "";
		for (loc.key in variables.wheels.class.properties)
			if (hasChanged(loc.key))
				loc.returnValue = ListAppend(loc.returnValue, loc.key);
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="allChanges" returntype="struct" access="public" output="false" hint="Returns a struct detailing all changes that have been made on the object but not yet saved to the database.">
	<cfscript>
		var loc = {};
		loc.returnValue = {};
		if (hasChanged())
		{
			loc.changedProperties = changedProperties();
			for (loc.i=1; loc.i LTE ListLen(loc.changedProperties); loc.i=loc.i+1)
			{
				loc.item = ListGetAt(loc.changedProperties, loc.i);
				loc.returnValue[loc.item] = {};
				loc.returnValue[loc.item].changedFrom = $changedFrom(loc.item);
				loc.returnValue[loc.item].changedTo = this[loc.item];
			}
		}
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="hasChanged" returntype="boolean" access="public" output="false" hint="Returns 'true' if the specified object property (or any if none was passed in) have been changed but not yet saved to the database.">
	<cfargument name="property" type="string" required="false" default="" hint="Name of property to check for change">
	<cfscript>
		var loc = {};
		loc.returnValue = false;
		for (loc.key in variables.wheels.class.properties)
			if (!StructKeyExists(this, loc.key) || !StructKeyExists(variables.$persistedProperties, loc.key) || this[loc.key] IS NOT variables.$persistedProperties[loc.key] && (Len(arguments.property) IS 0 || loc.key IS arguments.property))
				loc.returnValue = true;
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="reload" returntype="void" access="public" output="false">
	<cfscript>
		var loc = {};
		loc.query = findByKey(key=$primaryKeyValues(), reload=true, $create=false);
		loc.iEnd = ListLen(variables.wheels.class.propertyList);
		for (loc.i=1; loc.i LTE loc.iEnd; loc.i=loc.i+1)
		{
			loc.property = ListGetAt(variables.wheels.class.propertyList, loc.i);
			this[loc.property] = loc.query[loc.property][1];
		}
	</cfscript>
</cffunction>

<cffunction name="$primaryKeyValues" returntype="string" access="public" output="false">
	<cfscript>
		var loc = {};
		loc.returnValue = "";
		loc.iEnd = ListLen(variables.wheels.class.keys);
		for (loc.i=1; loc.i LTE loc.iEnd; loc.i=loc.i+1)
		{
			loc.returnValue = ListAppend(loc.returnValue, this[ListGetAt(variables.wheels.class.keys, loc.i)]);
		}		
		</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="$addSelectClause" returntype="array" access="public" output="false">
	<cfargument name="sql" type="array" required="true">
	<cfargument name="select" type="string" required="true">
	<cfargument name="include" type="string" required="true">
	<cfscript>
		var loc = {};

		// setup an array containing class info for current class and all the ones that should be included
		loc.classes = [];
		if (Len(arguments.include))
			loc.classes = $expandedAssociations(include=arguments.include);
		ArrayPrepend(loc.classes, variables.wheels.class);

		// add properties to select if the developer did not specify any
		if (!Len(arguments.select))
		{
			loc.iEnd = ArrayLen(loc.classes);
			for (loc.i=1; loc.i LTE loc.iEnd; loc.i=loc.i+1)
			{
				loc.classData = loc.classes[loc.i];
				loc.jEnd = ListLen(loc.classData.propertyList);
				for (loc.j=1; loc.j LTE loc.jEnd; loc.j=loc.j+1)
				{
					loc.jItem = Trim(ListGetAt(loc.classData.propertyList, loc.j));
					if (!ListFind(arguments.select, loc.jItem))
						arguments.select = ListAppend(arguments.select, loc.jItem);
				}
			}
		}

		// now let's go through the properties and map them to the database
		loc.select = "";
		loc.iEnd = ListLen(arguments.select);
		for (loc.i=1; loc.i LTE loc.iEnd; loc.i=loc.i+1)
		{
			loc.iItem = Trim(ListGetAt(arguments.select, loc.i));
			if (loc.iItem Does Not Contain "." && loc.iItem Does Not Contain " AS ")
			{
				loc.jEnd = ArrayLen(loc.classes);
				for (loc.j=1; loc.j LTE loc.jEnd; loc.j=loc.j+1)
				{
					loc.classData = loc.classes[loc.j];
					if (ListFindNoCase(loc.classData.propertyList, loc.iItem))
					{
						loc.toAppend = loc.classData.tableName & ".";
						if (ListFind(loc.classData.columnList, loc.iItem))
							loc.toAppend = loc.toAppend & loc.iItem;
						else
							loc.toAppend = loc.toAppend & loc.classData.properties[loc.iItem].column & " AS " & loc.iItem;
						break;
					}
				}
				loc.select = ListAppend(loc.select, loc.toAppend);
			}
			else
			{
				loc.select = ListAppend(loc.select, loc.iItem);
			}
		}
		loc.select = "SELECT " & loc.select;
		ArrayAppend(arguments.sql, loc.select);
	</cfscript>
	<cfreturn arguments.sql>
</cffunction>

<cffunction name="$addFromClause" returntype="array" access="public" output="false">
	<cfargument name="sql" type="array" required="true">
	<cfargument name="include" type="string" required="true">
	<cfscript>
		var loc = {};
		loc.from = "FROM " & variables.wheels.class.tableName;
		if (Len(arguments.include))
		{
			// setup an array containing class info for current class and all the ones that should be included
			loc.classes = [];
			if (Len(arguments.include))
				loc.classes = $expandedAssociations(include=arguments.include);
			ArrayPrepend(loc.classes, variables.wheels.class);
			loc.iEnd = ArrayLen(loc.classes);
			for (loc.i=1; loc.i LTE loc.iEnd; loc.i=loc.i+1)
			{
				loc.classData = loc.classes[loc.i];
				if (StructKeyExists(loc.classData, "join"))
					loc.from = ListAppend(loc.from, loc.classData.join, " ");
			}
		}
		ArrayAppend(arguments.sql, loc.from);
	</cfscript>
	<cfreturn arguments.sql>
</cffunction>

<cffunction name="$addWhereClause" returntype="array" access="public" output="false">
	<cfargument name="sql" type="array" required="true">
	<cfargument name="where" type="string" required="true">
	<cfargument name="include" type="string" required="true">
	<cfargument name="$softDeleteCheck" type="boolean" required="true">
	<cfscript>
		var loc = {};
		if (Len(arguments.where))
		{
			// make the where clause generic
			arguments.where = REReplace(arguments.where, variables.wheels.class.whereRegex, "\1?\8" , "all");

			// setup an array containing class info for current class and all the ones that should be included
			loc.classes = [];
			if (Len(arguments.include))
				loc.classes = $expandedAssociations(include=arguments.include);
			ArrayPrepend(loc.classes, variables.wheels.class);
			ArrayAppend(arguments.sql, "WHERE");
			if (arguments.$softDeleteCheck && variables.wheels.class.softDeletion)
				ArrayAppend(arguments.sql, " (");
			loc.regex = "((=|<>|<|>|<=|>=|!=|!<|!>| LIKE) ?)(''|'.+?'()|([0-9]|\.)+()|\([0-9]+(,[0-9]+)*\))(($|\)| (AND|OR)))";
			loc.paramedWhere = REReplace(arguments.where, loc.regex, "\1?\8" , "all");
			loc.params = ArrayNew(1);
			loc.where = ReplaceList(loc.paramedWhere, "AND,OR", "#chr(7)#AND,#chr(7)#OR");
			for (loc.i=1; loc.i LTE ListLen(loc.where, Chr(7)); loc.i=loc.i+1)
			{
				loc.element = Replace(ListGetAt(loc.where, loc.i, Chr(7)), Chr(7), "", "one");
				if (Find("(", loc.element) && Find(")", loc.element))
					loc.elementDataPart = SpanExcluding(Reverse(SpanExcluding(Reverse(loc.element), "(")), ")");
				else if (Find("(", loc.element))
					loc.elementDataPart = Reverse(SpanExcluding(Reverse(loc.element), "("));
				else if (Find(")", loc.element))
					loc.elementDataPart = SpanExcluding(loc.element, ")");
				else
					loc.elementDataPart = loc.element;
				loc.elementDataPart = Trim(ReplaceList(loc.elementDataPart, "AND,OR", ""));
				loc.param = {};


				loc.temp = REFind("^([^ ]*) ?(=|<>|<|>|<=|>=|!=|!<|!>| LIKE)", loc.elementDataPart, 1, true);
				if (ArrayLen(loc.temp.len) GT 1)
				{
					loc.where = Replace(loc.where, loc.element, Replace(loc.element, loc.elementDataPart, "?", "one"));
					loc.param.property = Mid(loc.elementDataPart, loc.temp.pos[2], loc.temp.len[2]);
					loc.jEnd = ArrayLen(loc.classes);
					for (loc.j=1; loc.j LTE loc.jEnd; loc.j=loc.j+1)
					{
						loc.classData = loc.classes[loc.j];
						if ((loc.param.property Contains "." && ListFirst(loc.param.property, ".") IS loc.classData.tableName || loc.param.property Does Not Contain ".") && ListFindNoCase(loc.classData.propertyList, ListLast(loc.param.property, ".")))
						{
							loc.param.type = loc.classData.properties[ListLast(loc.param.property, ".")].type;
							loc.param.column = loc.classData.tableName & "." & loc.classData.properties[ListLast(loc.param.property, ".")].column;
							break;
						}
					}
					loc.temp = REFind("^[^ ]* ?(=|<>|<|>|<=|>=|!=|!<|!>| LIKE)", loc.elementDataPart, 1, true);
					loc.param.operator = Trim(Mid(loc.elementDataPart, loc.temp.pos[2], loc.temp.len[2]));
					ArrayAppend(loc.params, loc.param);
				}
			}
			loc.where = ReplaceList(loc.where, "#Chr(7)#AND,#Chr(7)#OR", "AND,OR");

			// add to sql array
			loc.where = " #loc.where# ";
			loc.iEnd = ListLen(loc.where, "?");
			for (loc.i=1; loc.i LTE loc.iEnd; loc.i=loc.i+1)
			{
				loc.item = ListGetAt(loc.where, loc.i, "?");
				if (Len(Trim(loc.item)))
					ArrayAppend(arguments.sql, loc.item);
				if (loc.i LT ListLen(loc.where, "?"))
				{
					loc.column = loc.params[loc.i].column;
					ArrayAppend(arguments.sql, "#PreserveSingleQuotes(loc.column)#	#loc.params[loc.i].operator#");
					if (application.settings.environment IS NOT "production" && !StructKeyExists(loc.params[loc.i], "type"))
							$throw(type="Wheels", message="Column Not Found", extendedInfo="Wheels looked for a column named '#loc.column#' but couldn't find it.");
					loc.param = {property=loc.params[loc.i].property, column=loc.params[loc.i].column, type=loc.params[loc.i].type};
					ArrayAppend(arguments.sql, loc.param);
				}
			}
		}

		/// add soft delete sql
		if (arguments.$softDeleteCheck && variables.wheels.class.softDeletion)
		{
			if (Len(arguments.where))
				ArrayAppend(arguments.sql, ") AND (");
			else
				ArrayAppend(arguments.sql, "WHERE ");
			ArrayAppend(arguments.sql, "#variables.wheels.class.tableName#.#variables.wheels.class.softDeleteColumn# IS NULL");
			if (Len(arguments.where))
				ArrayAppend(arguments.sql, ")");
		}
	</cfscript>
	<cfreturn arguments.sql>
</cffunction>

<cffunction name="$addWhereClauseParameters" returntype="array" access="public" output="false">
	<cfargument name="sql" type="array" required="true">
	<cfargument name="where" type="string" required="true">
	<cfscript>
		var loc = {};
		if (Len(arguments.where))
		{
			loc.start = 1;
			loc.originalValues = [];
			while (!StructKeyExists(loc, "temp") || ArrayLen(loc.temp.len) GT 1)
			{
				loc.temp = REFind(variables.wheels.class.whereRegex, arguments.where, loc.start, true);
				if (ArrayLen(loc.temp.len) GT 1)
				{
					loc.start = loc.temp.pos[4] + loc.temp.len[4];
					ArrayAppend(loc.originalValues, ReplaceList(Chr(7) & Mid(arguments.where, loc.temp.pos[4], loc.temp.len[4]) & Chr(7), "#Chr(7)#(,)#Chr(7)#,#Chr(7)#','#Chr(7)#,#Chr(7)#"",""#Chr(7)#,#Chr(7)#", ",,,,,,"));
				}
			}

			loc.pos = ArrayLen(loc.originalValues);
			loc.iEnd = ArrayLen(arguments.sql);
			for (loc.i=loc.iEnd; loc.i GT 0; loc.i--)
			{
				if (IsStruct(arguments.sql[loc.i]) && loc.pos GT 0)
				{
					arguments.sql[loc.i].value = loc.originalValues[loc.pos];
					loc.pos--;
				}
			}
		}
	</cfscript>
	<cfreturn arguments.sql>
</cffunction>

<cffunction name="$addOrderByClause" returntype="array" access="public" output="false">
	<cfargument name="sql" type="array" required="true">
	<cfargument name="order" type="string" required="true">
	<cfargument name="include" type="string" required="true">
	<cfscript>
		var loc = {};
		if (Len(arguments.order))
		{
			if (arguments.order IS "random")
			{
				loc.order = application.wheels.adapter.randomOrder();
			}
			else
			{
				// setup an array containing class info for current class and all the ones that should be included
				loc.classes = [];
				if (Len(arguments.include))
					loc.classes = $expandedAssociations(include=arguments.include);
				ArrayPrepend(loc.classes, variables.wheels.class);

				loc.order = "";
				loc.iEnd = ListLen(arguments.order);
				for (loc.i=1; loc.i LTE loc.iEnd; loc.i=loc.i+1)
				{
					loc.iItem = Trim(ListGetAt(arguments.order, loc.i));
					if (loc.iItem Does Not Contain " ASC" && loc.iItem Does Not Contain " DESC")
						loc.iItem = loc.iItem & " ASC";
					if (loc.iItem Contains ".")
					{
						loc.order = ListAppend(loc.order, loc.iItem);
					}
					else
					{
						loc.property = ListLast(SpanExcluding(loc.iItem, " "), ".");
						loc.toAdd = variables.wheels.class.tableName & "." & loc.iItem;
						loc.jEnd = ArrayLen(loc.classes);
						for (loc.j=1; loc.j LTE loc.jEnd; loc.j=loc.j+1)
						{
							loc.classData = loc.classes[loc.j];
							loc.toAdd = loc.classData.tableName & "." & loc.iItem;
							if (ListFindNoCase(loc.classData.propertyList, loc.property) && !ListContainsNoCase(loc.order, SpanExcluding(loc.toAdd, " ")))
							{
								loc.order = ListAppend(loc.order, loc.toAdd);
								break;
							}
						}
					}
				}
			}
			loc.order = "ORDER BY " & loc.order;
			ArrayAppend(arguments.sql, loc.order);
		}
	</cfscript>
	<cfreturn arguments.sql>
</cffunction>

<cffunction name="$expandedAssociations" returntype="array" access="public" output="false">
	<cfargument name="include" type="string" required="true">
	<cfscript>
		var loc = {};
		loc.returnValue = [];

		// add the current class name so that the levels list start at the lowest level
		loc.levels = variables.wheels.class.name;

		// count the included associations
		loc.iEnd = ListLen(Replace(arguments.include, "(", ",", "all"));

		// clean up spaces in list and add a comma at the end to indicate end of string
		loc.include = Replace(arguments.include, " ", "", "all") & ",";

		loc.pos = 1;
		for (loc.i=1; loc.i LTE loc.iEnd; loc.i=loc.i+1)
		{
			// look for the next delimiter in the string and set it
			loc.delimPos = FindOneOf("(),", loc.include, loc.pos);
			loc.delimChar = Mid(loc.include, loc.delimPos, 1);

			// set current association name and set new position to start search in the next loop
			loc.name = Mid(loc.include, loc.pos, loc.delimPos-loc.pos);
			loc.pos = REFindNoCase("[a-z]", loc.include, loc.delimPos);

			// create a reference to current class in include string and get its association info
			loc.class = model(ListLast(loc.levels));
			loc.classAssociations = loc.class.$classData().associations;

			// infer class name and foreign key from association name unless developer specified it already
			if (!Len(loc.classAssociations[loc.name].class))
			{
				if (loc.classAssociations[loc.name].type IS "belongsTo")
				{
					loc.classAssociations[loc.name].class = loc.name;
				}
				else
				{
					loc.classAssociations[loc.name].class = singularize(loc.name);
				}
			}

			// create a reference to the associated class
			loc.associatedClass = model(loc.classAssociations[loc.name].class);

			if (!Len(loc.classAssociations[loc.name].foreignKey))
			{
				if (loc.classAssociations[loc.name].type IS "belongsTo")
				{
					loc.classAssociations[loc.name].foreignKey = loc.associatedClass.$classData().name & Replace(loc.associatedClass.$classData().keys, ",", ",#loc.associatedClass.$classData().name#", "all");
				}
				else
				{
					loc.classAssociations[loc.name].foreignKey = loc.class.$classData().name & Replace(loc.class.$classData().keys, ",", ",#loc.class.$classData().name#", "all");
				}
			}

			loc.classAssociations[loc.name].tableName = loc.associatedClass.$classData().tableName;
			loc.classAssociations[loc.name].propertyList = loc.associatedClass.$classData().propertyList;
			loc.classAssociations[loc.name].columnList = loc.associatedClass.$classData().columnList;
			loc.classAssociations[loc.name].properties = loc.associatedClass.$classData().properties;

			// create the join string
			if (loc.classAssociations[loc.name].type IS "belongsTo")
			{
				loc.classAssociations[loc.name].join = "INNER JOIN #loc.classAssociations[loc.name].tableName# ON ";
				loc.jEnd = ListLen(loc.classAssociations[loc.name].foreignKey);
				loc.toAppend = "";
				for (loc.j=1; loc.j LTE loc.jEnd; loc.j=loc.j+1)
				{
					loc.toAppend = ListAppend(loc.toAppend, "#loc.class.$classData().tableName#.#loc.class.$classData().properties[ListGetAt(loc.classAssociations[loc.name].foreignKey, loc.j)].column# = #loc.classAssociations[loc.name].tableName#.#loc.associatedClass.$classData().properties[ListGetAt(loc.associatedClass.$classData().keys, loc.j)].column#");
				}
				loc.classAssociations[loc.name].join = loc.classAssociations[loc.name].join & Replace(loc.toAppend, ",", " AND ", "all");
			}
			else
			{
				loc.classAssociations[loc.name].join = "LEFT OUTER JOIN #loc.classAssociations[loc.name].tableName# ON ";
				loc.jEnd = ListLen(loc.classAssociations[loc.name].foreignKey);
				loc.toAppend = "";
				for (loc.j=1; loc.j LTE loc.jEnd; loc.j=loc.j+1)
				{
					loc.toAppend = ListAppend(loc.toAppend, "#loc.class.$classData().tableName#.#loc.class.$classData().properties[ListGetAt(loc.class.$classData().keys, loc.j)].column# = #loc.classAssociations[loc.name].tableName#.#loc.associatedClass.$classData().properties[ListGetAt(loc.classAssociations[loc.name].foreignKey, loc.j)].column#");
				}
				loc.classAssociations[loc.name].join = loc.classAssociations[loc.name].join & Replace(loc.toAppend, ",", " AND ", "all");
			}

			// go up or down one level in the association tree
			if (loc.delimChar IS "(")
				loc.levels = ListAppend(loc.levels, loc.classAssociations[loc.name].class);
			else if (loc.delimChar IS ")")
				loc.levels = ListDeleteAt(loc.levels, ListLen(loc.levels));

			// add info to the array that we will return
			ArrayAppend(loc.returnValue, loc.classAssociations[loc.name]);

		}
		</cfscript>
		<cfreturn loc.returnValue>
</cffunction>

<cffunction name="$create" returntype="boolean" access="public" output="false">
	<cfscript>
		var loc = {};
		if (variables.wheels.class.timeStampingOnCreate)
			this[variables.wheels.class.timeStampOnCreateColumn] = Now();
		loc.sql = [];
		loc.sql2 = [];
		ArrayAppend(loc.sql, "INSERT INTO	#variables.wheels.class.tableName# (");
		ArrayAppend(loc.sql2, " VALUES (");
		for (loc.key in variables.wheels.class.properties)
		{
			if (StructKeyExists(this, loc.key))
			{
				ArrayAppend(loc.sql, variables.wheels.class.properties[loc.key].column);
				ArrayAppend(loc.sql, ",");
				loc.param = {value=this[loc.key], type=variables.wheels.class.properties[loc.key].type, scale=variables.wheels.class.properties[loc.key].scale, list=false, null=this[loc.key] IS ""};
				ArrayAppend(loc.sql2, loc.param);
				ArrayAppend(loc.sql2, ",");
			}
		}
		ArrayDeleteAt(loc.sql, ArrayLen(loc.sql));
		ArrayDeleteAt(loc.sql2, ArrayLen(loc.sql2));
		ArrayAppend(loc.sql, ")");
		ArrayAppend(loc.sql2, ")");
		loc.len = ArrayLen(loc.sql);
		for (loc.i=1; loc.i LTE loc.len; loc.i=loc.i+1)
			ArrayAppend(loc.sql, loc.sql2[loc.i]);
		loc.ins = application.wheels.adapter.query(sql=loc.sql, parameterize=arguments.parameterize);
		loc.generatedKey = application.wheels.adapter.generatedKey();
		if (StructKeyExists(loc.ins.result, loc.generatedKey))
			this[ListGetAt(variables.wheels.class.keys, 1)] = loc.ins.result[loc.generatedKey];
		$updatePersistedProperties();
		loc.returnValue = true;
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="$update" returntype="boolean" access="public" output="false">
	<cfscript>
		var loc = {};
		if (hasChanged())
		{
			if (variables.wheels.class.timeStampingOnUpdate)
				this[variables.wheels.class.timeStampOnUpdateColumn] = Now();
			loc.sql = [];
			ArrayAppend(loc.sql, "UPDATE #variables.wheels.class.tableName# SET ");
			for (loc.key in variables.wheels.class.properties)
			{
				if (StructKeyExists(this, loc.key) && (!StructKeyExists(variables.$persistedProperties, loc.key) || this[loc.key] IS NOT variables.$persistedProperties[loc.key]))
				{
					ArrayAppend(loc.sql, "#variables.wheels.class.properties[loc.key].column# = ");
					loc.param = {value=this[loc.key], type=variables.wheels.class.properties[loc.key].type, scale=variables.wheels.class.properties[loc.key].scale, list=false, null=this[loc.key] IS ""};
					ArrayAppend(loc.sql, loc.param);
					ArrayAppend(loc.sql, ",");
				}
			}
			ArrayDeleteAt(loc.sql, ArrayLen(loc.sql));
			loc.sql = $addKeyWhereClause(sql=loc.sql);
			loc.upd = application.wheels.adapter.query(sql=loc.sql, parameterize=arguments.parameterize);
			$updatePersistedProperties();
		}
		loc.returnValue = true;
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="$createInstance" returntype="any" access="public" output="false">
	<cfargument name="properties" type="any" required="true">
	<cfargument name="persisted" type="boolean" required="true">
	<cfargument name="row" type="numeric" required="false" default="1">
	<cfset var loc = {}>
	<cfset loc.fileName = capitalize(variables.wheels.class.name)>
	<cfif NOT ListFindNoCase(application.wheels.existingModelFiles, variables.wheels.class.name)>
		<cfset loc.fileName = "Model">
	</cfif>
	<cfset loc.rootObject = "ModelObject">
	<cfinclude template="../../root.cfm">
	<cfreturn loc.rootObject>
</cffunction>

<cffunction name="$initObject" returntype="any" access="public" output="false">
	<cfargument name="name" type="string" required="true">
	<cfargument name="properties" type="any" required="true">
	<cfargument name="persisted" type="boolean" required="true">
	<cfargument name="row" type="numeric" required="false" default="1">
	<cfscript>
		var loc = {};
		variables.wheels = {};
		variables.wheels.errors = [];
		// copy class variables from the object in the application scope
		variables.wheels.class = $namedReadLock(name="classLock", object=application.wheels.models[arguments.name], method="$classData");
		// setup object properties in the this scope
		if (IsQuery(arguments.properties) && arguments.properties.recordCount IS NOT 0)
		{
			for (loc.i=1; loc.i LTE ListLen(arguments.properties.columnList); loc.i=loc.i+1)
			{
				this[ListGetAt(arguments.properties.columnList, loc.i)] = arguments.properties[ListGetAt(arguments.properties.columnList, loc.i)][arguments.row];
			}
		}
		else if (IsStruct(arguments.properties) && !StructIsEmpty(arguments.properties))
		{
			for (loc.key in arguments.properties)
				this[loc.key] = arguments.properties[loc.key];
		}
		if (arguments.persisted)
			$updatePersistedProperties();
	</cfscript>
	<cfreturn this>
</cffunction>

<cffunction name="$updatePersistedProperties" returntype="void" access="public" output="false">
	<cfscript>
		var loc = {};
		variables.$persistedProperties = {};
		for (loc.key in variables.wheels.class.properties)
			if (StructKeyExists(this, loc.key))
				variables.$persistedProperties[loc.key] = this[loc.key];
	</cfscript>
</cffunction>

<cffunction name="$isNew" returntype="boolean" access="public" output="false">
	<cfscript>
		var loc = {};
		// if no values have ever been saved to the database this object is new
		if (!StructKeyExists(variables, "$persistedProperties"))
			loc.returnValue = true;
		else
			loc.returnValue = false;
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="$changedFrom" returntype="string" access="public" output="false">
	<cfargument name="property" type="string" required="true">
	<cfscript>
		var loc = {};
		loc.returnValue = variables.$persistedProperties[arguments.property];
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="$addDeleteClause" returntype="array" access="public" output="false">
	<cfargument name="sql" type="array" required="true">
	<cfscript>
		var loc = {};
		if (variables.wheels.class.softDeletion)
		{
			ArrayAppend(arguments.sql, "UPDATE #variables.wheels.class.tableName# SET #variables.wheels.class.softDeleteColumn# = ");
			loc.param = {value=Now(), type="cf_sql_timestamp", list=false, null=false};
			ArrayAppend(arguments.sql, loc.param);
		}
		else
		{
			ArrayAppend(arguments.sql, "DELETE FROM #variables.wheels.class.tableName#");
		}
	</cfscript>
	<cfreturn arguments.sql>
</cffunction>

<cffunction name="$addKeyWhereClause" returntype="array" access="public" output="false">
	<cfargument name="sql" type="array" required="true">
	<cfscript>
		var loc = {};
		ArrayAppend(arguments.sql, " WHERE ");
		loc.iEnd = ListLen(variables.wheels.class.keys);
		for (loc.i=1; loc.i LTE loc.iEnd; loc.i=loc.i+1)
		{
			loc.property = ListGetAt(variables.wheels.class.keys, loc.i);
			ArrayAppend(arguments.sql, "#variables.wheels.class.properties[loc.property].column# = ");
			loc.param = {value=this[loc.property], type=variables.wheels.class.properties[loc.property].type, scale=variables.wheels.class.properties[loc.property].scale, list=false, null=false};
			ArrayAppend(arguments.sql, loc.param);
			if (loc.i LT loc.iEnd)
				ArrayAppend(arguments.sql, " AND ");
		}
	</cfscript>
	<cfreturn arguments.sql>
</cffunction>

<cffunction name="$keyWhereString" returntype="string" access="public" output="false">
	<cfargument name="properties" type="any" required="false" default="#variables.wheels.class.keys#">
	<cfargument name="values" type="any" required="false" default="">
	<cfargument name="keys" type="any" required="false" default="">
	<cfscript>
		var loc = {};
		loc.returnValue = "";
		loc.iEnd = ListLen(arguments.properties);
		for (loc.i=1; loc.i LTE loc.iEnd; loc.i=loc.i+1)
		{
			loc.property = Trim(ListGetAt(arguments.properties, loc.i));
			if (Len(arguments.values))
				loc.value = Trim(ListGetAt(arguments.values, loc.i));
			else if (Len(arguments.keys))
				loc.value = this[ListGetAt(arguments.keys, loc.i)];
			loc.toAppend = loc.property & "=";
			if (!IsNumeric(loc.value))
				loc.toAppend = loc.toAppend & "'";
			loc.toAppend = loc.toAppend & loc.value;
			if (!IsNumeric(loc.value))
				loc.toAppend = loc.toAppend & "'";
			loc.returnValue = ListAppend(loc.returnValue, loc.toAppend, " ");
			if (loc.i LT loc.iEnd)
				loc.returnValue = ListAppend(loc.returnValue, "AND", " ");
		}
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>
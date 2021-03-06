<cfcomponent extends="wheelsMapping.Test">

	<cffunction name="setup">
		<cfinclude template="setup.cfm">
	</cffunction>

	<cffunction name="teardown">
		<cfinclude template="teardown.cfm">
	</cffunction>

	<cffunction name="test_flashClear_valid">
		<cfset run_flashClear_valid()>
		<cfset loc.controller.$setFlashStorage("cookie")>
		<cfset run_flashClear_valid()>
	</cffunction>

	<cffunction name="run_flashClear_valid">
		<cfset loc.controller.flashInsert(success="Congrats!")>
		<cfset loc.controller.flashClear()>
		<cfset result = StructKeyList(loc.controller.flash())>
		<cfset assert(result IS '')>
	</cffunction>

</cfcomponent>

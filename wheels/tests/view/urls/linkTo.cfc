<cfcomponent extends="wheelsMapping.Test">

	<cffunction name="setup">
		<cfset loc.controller = controller(name="dummy")>
		<cfset oldURLRewriting = application.wheels.URLRewriting>
		<cfset application.wheels.URLRewriting = "On">
		<cfset oldScriptName = request.cgi.script_name>
		<cfset request.cgi.script_name = "/rewrite.cfm">
	</cffunction>

	<cffunction name="teardown">
		<cfset application.wheels.URLRewriting = oldURLRewriting>
		<cfset request.cgi.script_name = oldScriptName>
	</cffunction>

	<cffunction name="test_ampersand_and_equals_sign_encoding">
		<cfset loc.e = '<a href="#application.wheels.webpath#x/x?a=cats%26dogs%3Dtrouble&amp;b=1">x</a>'>
		<cfset loc.r = loc.controller.linkTo(text="x", controller="x", action="x", params="a=cats%26dogs%3Dtrouble&b=1")>
		<cfset assert(loc.e eq loc.r)>
	</cffunction>

	<cffunction name="test_controller_action_only">
		<cfset loc.e = '<a href="#application.wheels.webpath#account/logout">Log Out</a>'>
		<cfset loc.r = loc.controller.linkTo(text="Log Out", controller="account", action="logout")>
		<cfset assert(loc.e eq loc.r)>
	</cffunction>

	<cffunction name="test_confirm_is_escaped">
		<cfset loc.e = '<a href="#application.wheels.webpath#" onclick="return confirm(''Mark as: \''Completed\''?'');">#application.wheels.webpath#</a>'>
		<cfset loc.r = loc.controller.linkTo(confirm="Mark as: 'Completed'?")>
		<cfset assert(loc.e eq loc.r)>
	</cffunction>

	<cffunction name="test_external_links">
		<cfset loc.e = '<a href="http://www.cfwheels.com">CFWheels</a>'>
		<cfset loc.r = loc.controller.linkTo(href="http://www.cfwheels.com", text="CFWheels")>
		<cfset assert(loc.e eq loc.r)>
	</cffunction>

</cfcomponent>
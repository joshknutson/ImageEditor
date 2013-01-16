<cfcomponent name="BoxBlurFilter">
<!---
	boxBlurFilter.cfc written by Rick Root (rick@webworksllc.com)
	
	Related Web Sites:
	- http://www.opensourcecf.com/imagecfc (home page)

	LICENSE
	-------
	Copyright (c) 2006, Rick Root <rick@webworksllc.com>
	All rights reserved.

	Redistribution and use in source and binary forms, with or 
	without modification, are permitted provided that the 
	following conditions are met:

	- Redistributions of source code must retain the above 
	  copyright notice, this list of conditions and the 
	  following disclaimer. 
	- Redistributions in binary form must reproduce the above 
	  copyright notice, this list of conditions and the 
	  following disclaimer in the documentation and/or other 
	  materials provided with the distribution. 
	- Neither the name of the Webworks, LLC. nor the names of 
	  its contributors may be used to endorse or promote products 
	  derived from this software without specific prior written 
	  permission. 

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND 
	CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
	INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
	MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
	SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
	HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
	OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--->


	<cfset variables.hRadius = 0>
	<cfset variables.vRadius = 0>
	<cfset variables.iterations = 1>

	<cfset variables.Math = createobject("java", "java.lang.Math")>
	<cfset variables.arrObj = createobject("java", "java.lang.reflect.Array")>
	<cfset variables.floatClass = createobject("java", "java.lang.Float").TYPE>
	<cfset variables.intClass = createobject("java", "java.lang.Integer").TYPE>

<cffunction name="init" access="public" output="false" return="this">
	<cfargument name="hradius" type="numeric" required="yes">
	<cfargument name="vradius" type="numeric" required="yes">
	<cfargument name="iterations" type="numeric" required="yes">
	<cfset setHRadius(arguments.hradius)>
	<cfset setVRadius(arguments.vradius)>
	<cfset setIterations(arguments.iterations)>
	<cfreturn this>	
</cffunction>

<cffunction name="filter" access="public" output="false" returnType="any">
	<cfargument name="src" required="yes" type="any"><!--- BufferedImage --->
	
	<cfscript>
		var width = src.getWidth();
		var height = src.getHeight();

		var dst = createObject("java","java.awt.image.BufferedImage").init(src.getWidth(), src.getHeight(), src.getType());

		var inPixels = variables.arrObj.newInstance(variables.intClass, javacast("int",width*height));
		var outPixels = variables.arrObj.newInstance(variables.intClass, javacast("int",width*height));
		var resultPixels = variables.arrObj.newInstance(variables.intClass, javacast("int",width*height));

		inPixels = src.getRGB( 0, 0, javacast("int",width), javacast("int",height), inPixels, 0, javacast("int",width) );

        for (i = 0; i lt iterations; i=i+1 ) 
		{
			outPixels = boxBlur( inPixels, width, height, hRadius );
			inPixels  = boxBlur( outPixels, height, width, vRadius );
        }
		dst.setRGB( 0, 0, javacast("int",width), javacast("int",height), inPixels, 0, javacast("int",width) );
		return dst;
	</cfscript>
</cffunction>

<cffunction name="boxBlur" access="public" output="false" returnType="any">
	<cfargument name="inPixels" type="any" required="yes">
	<cfargument name="width" type="numeric" required="yes">
	<cfargument name="height" type="numeric" required="yes">
	<cfargument name="radius" type="numeric" required="yes">
	
	<cfscript>
		var out = variables.arrObj.newInstance(variables.intClass, javacast("int",width*height));
		var outIndex = 0;
		var inIndex = 0;
		var ta = 0;
		var tr = 0;
		var tg = 0;
		var tb = 0;
		var outa = 0;
		var outr = 0;
		var outg = 0;
		var outb = 0;
		var i = 0;
		var x = 0;
		var y = 0;
		var rgb = 0;
		var rgbRight = 0;
		var rgbLeft = 0;
		var offsetLeft = 0;
		var offsetRight = 0;
		
        for ( y = 0; y lt height; y=y+1 ) 
		{
			outIndex = y;

			for ( x = 0; x lt width; x=x+1 )
			{
				
				// clamp(num,min,max) forces a number to be between a certain   
				// range
				// which pixels to look at:
				offsetRight = clamp(x+radius,0,width-1);
				offsetLeft = clamp(x-radius,0,width-1);
				
				// get the ARGB value for each pixel
				rgbRight = arrObj.get(inPixels, javacast("int",inIndex+offsetRight));
				rgbLeft = arrObj.get(inPixels, javacast("int",inIndex+offsetLeft));
				
				ta = ( bitAnd(BitSHRN(rgbRight,24),255) + bitAnd(BitSHRN(rgbLeft,24),255) )/2;
				tr = ( bitAnd(BitSHRN(rgbRight,16),255) + bitAnd(BitSHRN(rgbLeft,16),255) )/2;
				tg = ( bitAnd(BitSHRN(rgbRight,8),255) + bitAnd(BitSHRN(rgbLeft,8),255) )/2;
				tb = ( bitAnd(rgbRight,255) + bitAnd(rgbLeft,255) )/2;

				rgb = bitOr(bitOr(bitOr(BitSHLN(ta,24),BitSHLN(tr,16)),BitSHLN(tg,8)),tb);

				arrObj.setInt(out, javacast("int",outIndex), javacast("int",rgb));
				
				// I don't really understand this but it works.  I think
				// it's because a box blur requires TWO passes ...
				outIndex = outIndex + height;
			}

            inIndex = inIndex + width;
        }
		return out;
	</cfscript>
        
</cffunction>


<cffunction name="setHRadius" access="public" output="false" returnType="void">
	<cfargument name="hRadius" type="numeric" required="yes">
	<cfscript>
		variables.hRadius = javacast("int",arguments.hRadius);
	</cfscript>
</cffunction>

<cffunction name="getHRadius" access="public" output="false" returnType="numeric">
	<cfreturn variables.hRadius>
</cffunction>

<cffunction name="setVRadius" access="public" output="false" returnType="void">
	<cfargument name="vRadius" type="numeric" required="yes">
	<cfscript>
		variables.vRadius = javacast("int",arguments.vRadius);
	</cfscript>
</cffunction>

<cffunction name="getVRadius" access="public" output="false" returnType="numeric">
	<cfreturn variables.vRadius>
</cffunction>

<cffunction name="setIterations" access="public" output="false" returnType="void">
	<cfargument name="iterations" type="numeric" required="yes">
	<cfscript>
		variables.iterations = javacast("int",arguments.iterations);
	</cfscript>
</cffunction>

<cffunction name="getIterations" access="public" output="false" returnType="numeric">
	<cfreturn variables.iterations>
</cffunction>

<cffunction name="clamp" access="private" output="false" returnType="numeric">
	<cfargument name="val" type="numeric" required="yes">
	<cfargument name="min" type="numeric" required="no" default="0">
	<cfargument name="max" type="numeric" required="no" default="255">
	
	<cfif val lt min>
		<cfreturn javacast("int",min)>
	<cfelseif val gt max>
		<cfreturn javacast("int",max)>
	<cfelse>
		<cfreturn javacast("int",val)>
	</cfif>
</cffunction>

</cfcomponent>
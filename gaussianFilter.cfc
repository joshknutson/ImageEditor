<cfcomponent name="GaussianFilter">
<!---
	gaussianFilter.cfc written by Rick Root (rick@webworksllc.com)
	
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

	<cfset variables.radius = javacast("float",0)>
	<cfset kernel = createObject("java","java.awt.image.Kernel")>

	<cfset variables.Math = createobject("java", "java.lang.Math")>
	<cfset variables.arrObj = createobject("java", "java.lang.reflect.Array")>
	<cfset variables.floatClass = createobject("java", "java.lang.Float").TYPE>
	<cfset variables.intClass = createobject("java", "java.lang.Integer").TYPE>

<cffunction name="init" access="public" output="false" return="this">
	<cfargument name="radius" type="numeric" required="yes">
	<cfset setRadius(arguments.radius)>
	<cfreturn this>	
</cffunction>

<cffunction name="setRadius" access="public" output="false" returnType="void">
	<cfargument name="radius" type="numeric" required="yes">
	<cfscript>
		variables.radius = javacast("float",radius);
		variables.kernel = makeKernel(variables.radius);
	</cfscript>
</cffunction>

<cffunction name="getRadius" access="public" output="false" returnType="numeric">
	<cfreturn variables.radius>
</cffunction>

<cffunction name="filter" access="public" output="false" returnType="any">
	<cfargument name="src" required="yes" type="any"><!--- BufferedImage --->

	<cfscript>
		var width = src.getWidth();
		var height = src.getHeight();
	
		var alpha = "no";
		
		var dst = createObject("java","java.awt.image.BufferedImage").init(src.getWidth(), src.getHeight(), src.getType());
	
		var inPixels = variables.arrObj.newInstance(variables.intClass, javacast("int",width*height));
		var outPixels = variables.arrObj.newInstance(variables.intClass, javacast("int",width*height));
	
		inPixels = src.getRGB( 0, 0, javacast("int",width), javacast("int",height), inPixels, 0, javacast("int",width) );
	
		outPixels = convolveAndTranspose(variables.kernel, inPixels, width, height);
		inPixels = convolveAndTranspose(variables.kernel, outPixels, height, width);
	
		dst.setRGB( 0, 0, javacast("int",width), javacast("int",height), inPixels, 0, javacast("int",width) );
		return dst;
	</cfscript>
</cffunction>

<cffunction name="convolveAndTranspose" access="public" output="false" returnType="any">
	<cfargument name="kernel" type="any" required="yes">
	<cfargument name="inPixels" type="any" required="yes">
	<cfargument name="width" type="numeric" required="yes">
	<cfargument name="height" type="numeric" required="yes">
	
	<cfscript>
		var matrix = kernel.getKernelData( javacast("null","") );
		var cols = kernel.getWidth();
		var cols2 = javacast("int",cols/2);
		var outPixels = variables.arrObj.newInstance(variables.intClass, javacast("int",width*height));
		var y = 0;
		var pxNum = 0;
		var ioffset = 0;
		var x = 0;
		var noffset = 0;
		var col = 0;
		var moffset = 0;
		var f = 0;
		var r = 0;
		var g = 0;
		var b = 0;
		var a = 0;
		var ia = 0;
		var ir = 0;
		var ig = 0;
		var ib = 0;
		var count = 0;
		var newRGB = 0;
		
		var alpha = true;  // could be an arg
		
		for (y=0; y lt height; y=y+1) {
			index = y;
			ioffset = y*width;
			for (x=0; x lt width; x=x+1) {
				r = 0;
				g = 0;
				b = 0;
				a = 0;
				moffset = cols2;
				for (col = 0-cols2; col lte cols2; col=col+1) {
					f = variables.arrObj.get(matrix, javacast("int",moffset+col));
					if (f neq 0) 
					{
						ix = x+col;
						if ( ix lt 0 ) 
						{
							ix = 0;
						} else if ( ix gte width) {
							ix = width-1;
						}
						rgb = variables.arrObj.get(inPixels,javacast("int",ioffset+ix));
						a = a + f * bitAnd(BitSHRN(rgb,24),255);
						r = r + f * bitAnd(BitSHRN(rgb,16),255);
						g = g + f * bitAnd(BitSHRN(rgb,8),255);
						b = b + f * bitAnd(rgb,255);
					}
				}
				if (alpha) {
					ia = clamp(a+0.5,0,255);
				} else {
					ia = 255;
				}
				ir = clamp(r+0.5,0,255);
				ig = clamp(g+0.5,0,255);
				ib = clamp(b+0.5,0,255);
				newRGB = bitOr(bitOr(bitOr(BitSHLN(ia,24),BitSHLN(ir,16)),BitSHLN(ig,8)),ib);
				variables.arrObj.setInt(outPixels, javacast("int",index), javacast("int",newRGB));
				index = index + height;
			}
		}
		return outPixels;
	</cfscript>
</cffunction>

<cffunction name="makeKernel" access="public" output="false" returnType="any">
	<cfargument name="radius" type="numeric" required="yes">

	<cfscript>
		var row = 0;
		var i = 0;
		var distance = javacast("float",0);
		var r = javacast("int", Ceiling(radius));
		var rows = javacast("int", r*2+1);
		var matrix = variables.arrObj.newInstance(variables.floatClass, rows);

		var sigma = javacast("float",radius/3);
		var sigma22 = javacast("float",2*sigma*sigma);
		var sigmaPi2 = javacast("float",2*variables.Math.PI*sigma);
		var sqrtSigmaPi2 = javacast("float", sqr(sigmaPi2));
		var radius2 = javacast("float",radius*radius);
		var total = javacast("float",0);
		var index = 0;

		for (row = 0-r; row lte r; row=row+1) 
		{
			distance = row*row;
			if (distance gt radius2)
			{
				arrObj.setFloat(matrix, javacast("int",index), javacast("float",0));
			} else {
				tempvar1 = exp((0-distance)/sigma22) / sqrtSigmaPi2;
				tempvar2 = javacast("float", tempvar1);
				arrObj.setFloat(matrix, javacast("int",index), tempvar2);
			}
			total = total + arrObj.get(matrix, javacast("int",index));
			index = index + 1;
		}
		for ( i = 0; i lt rows; i=i+1)
		{
			// matrix[i] = matrix[i] / total;
			arrObj.setFloat(matrix, javacast("int",i), javacast("float", arrObj.get(matrix, javacast("int",i)) / total) );
		}
		retVal = createObject("java","java.awt.image.Kernel");
		retVal.init(rows, 1, matrix);
		return retVal;
	</cfscript>
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
<#
The MIT License (MIT)

Copyright (c) 2014 Jim Christopher

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

function new-parameterTransform 
{
	[cmdletbinding()]
	param( 
		[Parameter(Mandatory=$true,Position=0)]
		[string] $name,
		
		[Parameter(Mandatory=$true, Position=1)]
		[scriptblock] $script
	)
	
add-Type -TypeDefinition @"
using System;
using System.ComponentModel;
using System.Management.Automation;
using System.Collections.ObjectModel;

[AttributeUsage(AttributeTargets.Field | AttributeTargets.Property)]
public class ${name}Attribute : ArgumentTransformationAttribute {
   private ScriptBlock _scriptblock;
   private string _noOutputMessage = "Transform Script had no output.";

   public ${name}Attribute() {
      this.Script = ScriptBlock.Create( @"
	  	$($script.ToString() -replace '"','""' )
" );
   }
   public override string ToString() {
      return Script.ToString();
   }

   public override Object Transform( EngineIntrinsics engine, Object inputData) {
      try {
         Collection<PSObject> output =
            engine.InvokeCommand.InvokeScript( engine.SessionState, Script, inputData );
         
         if(output.Count > 1) {
            Object[] transformed = new Object[output.Count];
            for(int i =0; i < output.Count;i++) {
               transformed[i] = output[i].BaseObject;
            }
            return transformed;
         } else if(output.Count == 1) {
            return output[0].BaseObject;
         } else {
            throw new ArgumentTransformationMetadataException(NoOutputMessage);
         }
      } catch (ArgumentTransformationMetadataException) {
         throw;
      } catch (Exception e) {
         throw new ArgumentTransformationMetadataException(string.Format("Transform Script threw an exception ('{0}'). See `$Error[0].Exception.InnerException.InnerException for more details.",e.Message), e);
      }
   }
   
   public ScriptBlock Script {
      get { return _scriptblock; }
      set { _scriptblock = value; }
   }
   
   public string NoOutputMessage {
      get { return _noOutputMessage; }
      set { _noOutputMessage = value; }
   }  
}
"@
}

New-Alias -Name Transform -Value New-ParameterTransform;

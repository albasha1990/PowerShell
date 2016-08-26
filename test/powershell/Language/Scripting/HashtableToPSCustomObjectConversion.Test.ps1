Describe "Generics support" -Tags "CI" {

    Context 'New-Object cmdlet should accept empty hashtable or $null as Property argument' {
        
        try
        {
	        $a = new-object psobject -property $null
        }
        catch {            
            It 'Should not throw exception' { $false | Should be $true }
        }
        It '$a should not be $null' { $a | Should Not Be $null }
        It '$a Type' { ( $a -is [System.Management.Automation.PSObject]) | Should Be $true }
    }

    Context 'New-Object cmdlet should throw terminating errors when user specifies a non-existent property or tries to assign incompatible values' {
       
        try
        { 
            $source = @"
                        public class SampleClass6
                        {
                            public SampleClass6(int x)
                            {
                            	a = x;
                            }
                            
                            public SampleClass6()
                            {
                            }
                                                          
                            public int a;
                            public int b;
                        }
"@
             add-type -typedefinition $source
             $x = New-Object -TypeName SampleClass6 -Property @{aa=10;b=5}            
       }
       catch
       {             
            It '$_.Exception.GetType().Name' { $_.Exception.GetType().Name | Should Be 'InvalidOperationException' }
                
            It '$_.Exception.Message' { ($_.Exception.Message -like "*aa*") | Should Be $true }

            It '$_.FullyQualifiedErrorId' { $_.FullyQualifiedErrorId | Should Be 'InvalidOperationException,Microsoft.PowerShell.Commands.NewObjectCommand' }
        }
    }

    Context 'Hashtable conversion to PSCustomObject succeeds (Insertion Order is not retained)' {
       
       try
       {
           $x = [pscustomobject][hashtable]@{one=1;two=2}
       }
       catch {                
                It 'Should not throw exception' { $false | Should be $true }
       }
       It '$x is not $null' { $x | Should Not Be $null }
       It '$x type' { ( $x -is [System.Management.Automation.PSObject]) | Should Be $true }
   }
       

    Context 'Hashtable conversion to PSCustomObject retains insertion order of hashtable keys when passed a hashliteral' {
       
       try
       {
           $x = [pscustomobject]@{one=1;two=2}
       }
       catch {                
                It 'Should not throw exception' { $false | Should be $true }
       }
       It '$x is not $null' { $x | Should Not Be $null } 
       It '$x type' { ( $x -is [System.Management.Automation.PSObject]) | Should Be $true}
       
       $p = 0
       # Checks if the first property is One
       $x.psobject.Properties | foreach-object  `
                                {               
                                    if ($p -eq 0)  
                                    {               
                                        $p++; 
                                        It '$_.Name' { $_.Name | Should Be 'one' }
                                     }
                                }
    }
       

    Context 'Hashtable(Stored in a variable) conversion to  PSCustomObject succeeds (Insertion Order is not retained)' {
           
       try
       {
	       $ht = @{one=1;two=2}
           $x = [pscustomobject]$ht
       }
       catch {                
                It 'should not throw exception' { $false | Should be $true }
       }
       It '$x is not $null' { $x | Should Not Be $null }
       It '$x type' { ( $x -is [System.Management.Automation.PSObject]) | Should Be $true }
   }


    Context 'Conversion from PSCustomObject to hashtable should fail' {
           
           $failed = $true
           try
           {
	           $x = [hashtable][pscustomobject]@{one=1;two=2}
               $failed = $false
           }
           catch
           {
                It '$_.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId' { $_.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId | Should Be 'InvalidCastConstructorException' }
           }
           It 'Expect an exception is thrown' { $failed | Should be $true }
       }
       
       
    Context 'Conversion of Ordered hashtable to PSCustomObject should succeed' {
      
       try
       {
           $x = [pscustomobject][ordered]@{one=1;two=2}
       }
       catch {
                It 'should not throw exception' { $false | Should be $true }
       }
       It '$x is not $null' { $x | Should Not Be $null }
       It '$x type' { ( $x -is [System.Management.Automation.PSObject]) | Should Be $true }
       
       $p = 0
       # Checks if the first property is One
       $x.psobject.Properties | foreach-object  `
                                {               
                                    if ($p -eq 0)  
                                    {               
                                        $p++; 
                                        It 'Name' { $_.Name | Should Be 'one' }
                                     }
                                }
    }
       

    Context 'Creating an object of an existing type from hashtable should succeed' {
       
       try
       { 
          $source = @"
                        public class SampleClass1
                        {                                                       
                            public SampleClass1(int x)
                            {
                            	a = x;
                            }
                            
                            public SampleClass1()
                            {
                            }
                                                          
                            public int a;
                            public int b;
                        }
"@
                 add-type -typedefinition $source
                 $x = [SampleClass1]@{a=10;b=5}            
       }
       catch {
                It 'should not throw exception' { $false | Should be $true }
       }
       It '$x is not $null' { $x | Should Not Be $null }
       It '$x.a' { $x.a | Should Be '10' }
   }
       

    Context 'Creating an object of an existing type from hashtable should throw error when setting non-existent properties' {
      
       $failed = $true
       try
       { 
          $source = @"
                        public class SampleClass2
                        {
                            public SampleClass2(int x)
                            {
                            	a = x;
                            }
                            
                            public SampleClass2()
                            {
                            }
                                                          
                            public int a;
                            public int b;
                        }
"@
                 add-type -typedefinition $source
                 $x = [SampleClass2]@{blah=10;b=5 }
                 $failed = $false
       }
       catch
       {
           #Write-host $caught.Exception.InnerException.ErrorRecord
           It '$_.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId' { $_.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId | Should Be 'ObjectCreationError' }
       }
       It 'Expect an exception is thrown' { $failed | Should be $true }
    }


    Context 'Creating an object of an existing type from hashtable should throw error when setting incompatible values for properties' {
       
       $failed = $true
       try
       { 
          $source = @"
                        public class SampleClass3
                        {
                            public SampleClass3(int x)
                            {
                            	a = x;
                            }
                            
                            public SampleClass3()
                            {
                            }
                                                          
                            public int a;
                            public int b;
                        }
"@
                 add-type -typedefinition $source
                 $x = [SampleClass3]@{a="foo";b=5}
                 $failed = $false
       }
       catch
       {           
           It '$_.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId' { $_.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId | Should Be 'ObjectCreationError' }
       }
       It 'Expect an exception is thrown' { $failed | Should be $true }
    }

    #known issue created 
    It 'Creating an object of an existing type from hashtable should call the constructor taking a hashtable if such a constructor exists in the type' -skip:$IsCoreCLR {
              
       try
       { 
          $source = @"
                        public class SampleClass5
                        {                                                       
                            public SampleClass5(int x)
                            {
                            	a = x;
                            }
                            
                            public SampleClass5(System.Collections.Hashtable h)   
                            {
		                          a = 100;
		                          b = 200;
                            }
                            
                            public SampleClass5()
                            {
                            }
                                                          
                            public int a;
                            public int b;
                        }
"@
                 add-type -typedefinition $source
                 $x = [SampleClass5]@{a=10;b=5}
            
       }
       catch {                
                $false | Should be $true
       }
       $x | Should Not Be $null
       $x.a | Should Be '100'
    }


    It 'Add a new type name to PSTypeNames property' {

	    $obj = [PSCustomObject] @{pstypename = 'Mytype'}
	    $obj.PSTypeNames[0] | Should Be 'Mytype'
    }

    Context 'Add an existing type name to PSTypeNames property' {

	    $obj = [PSCustomObject] @{pstypename = 'System.Object'}
	    It '$obj.PSTypeNames.Count' { $obj.PSTypeNames.Count | Should Be 3 }
	    It '$obj.PSTypeNames[0] type' { $obj.PSTypeNames[0] | Should Be 'System.Object' }
    }
}
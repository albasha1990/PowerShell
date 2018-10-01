# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
Describe "Import-Csv DRT Unit Tests" -Tags "CI" {
    BeforeAll {
        $fileToGenerate = Join-Path $TestDrive -ChildPath "importCSVTest.csv"
        $psObject = [pscustomobject]@{ "First" = "1"; "Second" = "2" }
    }

    It "Test import-csv with a delimiter parameter" {
        $delimiter = ';'
        $psObject | Export-Csv -Path $fileToGenerate -Delimiter $delimiter
        $returnObject = Import-Csv -Path $fileToGenerate -Delimiter $delimiter
        $returnObject.First | Should -Be 1
        $returnObject.Second | Should -Be 2
    }

    It "Test import-csv with UseCulture parameter" {
        $psObject | Export-Csv -Path $fileToGenerate -UseCulture
        $returnObject = Import-Csv -Path $fileToGenerate -UseCulture
        $returnObject.First | Should -Be 1
        $returnObject.Second | Should -Be 2
    }
}

Describe "Import-Csv Quote Delimiter" -Tags "CI" {
    BeforeAll {
        $TestImportCsvQuoteDelimiter_EmptyValue = Join-Path -Path (Join-Path $PSScriptRoot -ChildPath assets) -ChildPath TestImportCsvQuoteDelimiter_EmptyValue.csv
        $TestImportCsvQuoteDelimiter_QuoteWithValue = Join-Path -Path (Join-Path $PSScriptRoot -ChildPath assets) -ChildPath TestImportCsvQuoteDelimiter_QuoteWithValue.csv
        $TestImportCsvQuoteDelimiter_QuoteCommaDelimiter = Join-Path -Path (Join-Path $PSScriptRoot -ChildPath assets) -ChildPath TestImportCsvQuoteDelimiter_QuoteCommaDelimiter.csv
    }
	
    

    It "Should handle qoute delimiter with empty value" {
        $ExpectedHeader = "a1,H1,a3"
        $returnObject = Import-Csv -Path $TestImportCsvQuoteDelimiter_EmptyValue -Delimiter '"'
        $actualHeader = $returnObject[0].psobject.Properties.name -join ','
        $actualHeader | Should -Be $ExpectedHeader
    }

    It "Should handle quote delimiter with non-empty value" {
        $ExpectedHeader = "a1,a2,a3"
        $returnObject = Import-Csv -Path $TestImportCsvQuoteDelimiter_QuoteWithValue -Delimiter '"'
        $actualHeader = $returnObject[0].psobject.Properties.name -join ','
        $actualHeader | Should -Be $ExpectedHeader        
    }

    It "Should handle quoted values with non-quote delimiter" {
        $ExpectedHeader = "a1,a2,a3"
        $returnObject = Import-Csv -Path $TestImportCsvQuoteDelimiter_QuoteCommaDelimiter -Delimiter ','
        $actualHeader = $returnObject[0].psobject.Properties.name -join ','
        $actualHeader | Should -Be $ExpectedHeader
    }
    
}

Describe "Import-Csv File Format Tests" -Tags "CI" {
    BeforeAll {
        # The file is w/o header
        $TestImportCsv_NoHeader = Join-Path -Path (Join-Path $PSScriptRoot -ChildPath assets) -ChildPath TestImportCsv_NoHeader.csv
        # The file is with header
        $TestImportCsv_WithHeader = Join-Path -Path (Join-Path $PSScriptRoot -ChildPath assets) -ChildPath TestImportCsv_WithHeader.csv
        # The file is W3C Extended Log File Format
        $TestImportCsv_W3C_ELF = Join-Path -Path (Join-Path $PSScriptRoot -ChildPath assets) -ChildPath TestImportCsv_W3C_ELF.csv

        $testCSVfiles = $TestImportCsv_NoHeader, $TestImportCsv_WithHeader, $TestImportCsv_W3C_ELF
        $orginalHeader = "Column1","Column2","Column 3"
        $customHeader = "test1","test2","test3"
    }
    # Test set is the same for all file formats
    foreach ($testCsv in $testCSVfiles) {
       $FileName = (dir $testCsv).Name
        Context "Next test file: $FileName" {
            BeforeAll {
                $CustomHeaderParams = @{Header = $customHeader; Delimiter = ","}
                if ($FileName -eq "TestImportCsv_NoHeader.csv") {
                    # The file does not have header
                    # (w/o Delimiter here we get throw (bug?))
                    $HeaderParams = @{Header = $orginalHeader; Delimiter = ","}
                } else {
                    # The files have header
                    $HeaderParams = @{Delimiter = ","}
                }

            }

            It "Should be able to import all fields" {
                $actual = Import-Csv -Path $testCsv @HeaderParams
                $actualfields = $actual[0].psobject.Properties.Name
                $actualfields | Should -Be $orginalHeader
            }

            It "Should be able to import all fields with custom header" {
                $actual = Import-Csv -Path $testCsv @CustomHeaderParams
                $actualfields = $actual[0].psobject.Properties.Name
                $actualfields | Should -Be $customHeader
            }

            It "Should be able to import correct values" {
                $actual = Import-Csv -Path $testCsv @HeaderParams
                $actual.count         | Should -Be 4
                $actual[0].'Column1'  | Should -BeExactly "data1"
                $actual[0].'Column2'  | Should -BeExactly "1"
                $actual[0].'Column 3' | Should -BeExactly "A"
            }

        }
    }
}

Describe "Import-Csv #Type Tests" -Tags "CI" {
    BeforeAll {
        $testfile = Join-Path $TestDrive -ChildPath "testfile.csv"
        Remove-Item -Path $testfile -Force -ErrorAction SilentlyContinue
        $processlist = (Get-Process)[0..1]
        $processlist | Export-Csv -Path $testfile -Force -IncludeTypeInformation
        $expectedProcessTypes = "System.Diagnostics.Process","CSV:System.Diagnostics.Process"
    }

    It "Test import-csv import Object" {
        $importObjectList = Import-Csv -Path $testfile
        $processlist.Count | Should -Be $importObjectList.Count

        $importTypes = $importObjectList[0].psobject.TypeNames
        $importTypes.Count | Should -Be $expectedProcessTypes.Count
        $importTypes[0] | Should -Be $expectedProcessTypes[0]
        $importTypes[1] | Should -Be $expectedProcessTypes[1]
    }
}

Describe "Import-Csv with different newlines" -Tags "CI" {
    It "Test import-csv with '<name>' newline" -TestCases @(
        @{ name = "CR"; newline = "`r" }
        @{ name = "LF"; newline = "`n" }
        @{ name = "CRLF"; newline = "`r`n" }
        ) {
        param($newline)
        $csvFile = Join-Path $TestDrive -ChildPath $((New-Guid).Guid)
        $delimiter = ','
        "h1,h2,h3$($newline)11,12,13$($newline)21,22,23$($newline)" | Out-File -FilePath $csvFile
        $returnObject = Import-Csv -Path $csvFile -Delimiter $delimiter
        $returnObject.Count | Should -Be 2
        $returnObject[0].h1 | Should -Be 11
        $returnObject[0].h2 | Should -Be 12
        $returnObject[0].h3 | Should -Be 13
        $returnObject[1].h1 | Should -Be 21
        $returnObject[1].h2 | Should -Be 22
        $returnObject[1].h3 | Should -Be 23
    }
}

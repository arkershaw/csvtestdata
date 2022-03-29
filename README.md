# csvtestdata

Generate CSV test data.

Populates blank values in existing rows and appends new rows to a CSV file. Data types to generate are specified using a simple extra header line.

# Build

`ocamllex csv.mll`
Then for native code use:
`ocamlopt -o csv.exe str.cmxa csv.ml`
For bytecode use:
`ocamlc -o csv.exe str.cma csv.ml`

# Data Definition

Next you will need to describe the data you wish to generate. This is done by creating a blank file and inserting a row in CSV format describing the data in each column. Alternatively, this row can be added to the top of an existing CSV file. The definition row is in CSV format and specifies what values each field should contain. For example, the following would result in a list of first names, last names and ages (between one and a hundred):

`Name,Name,Integer 1-100`

See the test.csv file for a full example. The full list of data types supported is:

- `ID [seed]-[increment]`: Generates sequential integer values starting at seed and increasing by increment.
- `Name`: Generates a string of 3-10 characters with the first character in upper case.
- `Address`: A string resembling a house number and random street name.
- `Postcode`: A string resembling a UK postal code.
- `Email`: A random address and domain plus a choice from a predefined list of top level domains.
- `Word [min]-[max]`: A string of required length with the initial character in upper case
- `Integer [min]-[max]`: A whole number in the specified range (inclusive).
- `Decimal [min]-[max] [decimal places]`: A decimal number in the specified range (inclusive) rounded to the required decimal places. Min and max value should both be decimal numbers.
- `Literal [value]`: Places the supplied value directly into the column.
- `Date yyyy-mm-dd yyyy-mm-dd`: A random date in the specified range, in ISO format with the time set to midnight.
- `Option [separator] [values]`: A choice from the provided values, delimited by the separator.

# Usage

Once you have the compiled program and created your CSV file, execute the program like this:

`./csv.exe -p -a 2 -o output.csv test.csv`

The final parameter is the name of the input file. The available options are:

- -p: This option causes blank values in any existing rows to be populated according to the header row.
- -a: This specifies the number of rows that should be appended to the end of the file.
- -o: The name of the output file. If left blank, ".out" will be appended to the name of the input file.

A new file will be created with the specified name. Any rows from the input file will be output first, with missing values populated if the appropriate parameter is used. The required number of rows will be generated and appended to the end of the file. If an exising CSV file is used and it contains a column header row, this will be copied to the output file. The custom header row containing the data definitions will not be included in the output file, however, so it is ready for use.

# bash-lib
<!-- TODO enable testing and codecov.
[![Build Status](https://travis-ci.org/pkrog/bash-testthat.svg?branch=master)](https://travis-ci.org/pkrog/bash-testthat)
[![codecov](https://codecov.io/gh/pkrog/bash-testthat/branch/master/graph/badge.svg?token=4QNHAHECYQ)](https://codecov.io/gh/pkrog/bash-testthat)
-->

A bash library to ease script development.
The library is divided in module files to be loaded using the `source` command.
Public functions and variables are all prefixed with a namespace in order to
avoid collisions with your own script.

## str

## argparse

## os

## logging

## testthat

The `testthat` library is a test library for testing bash functions and programs.

When inside a test script, you have first to define context:
```bash
tt_context "My context"
```
The text of the context will be printed on the screen.

Then you call `tt_test_that` for each test function you have written:
```bash
tt_test_that "myFct is working correctly" test_myFct
```

Inside your `test_myFct` function, you call assertions:
```bash
function test_myFct {
   tt_expect_num_eq 1 2 || return 1
}
```

Do not forget to append ` || return 1` to the assertion call, otherwise no
error will be reported in case of failure.

### Script

The `testthat` library (`testthat.sh` file) comes along a script (`testthat`)
designed to help you write tests for a command line program, written in any
language, or to test bash functions.

In particular, the framework provides functions for testing CSV files that you
use as inputs or outputs of your program.

The `testthat` script can be run on individual test scripts or folders
containing test scripts.  You can even specify a mix of them on the command
line:
```sh
testthat myfirst_script.sh myfolderA mysecond_script.sh myfolderB
```

Running individual scripts is done by listing the script paths on the command line:
```sh
testthat myfirst_script.sh mysecond_script.sh my/other/script.sh
```
The scripts will be run in the specified order.

If you put your test scripts inside a single folder (called here `test`) you
call `testthat` on that folder:
```sh
testthat test
```

Only the scripts named `test-*.sh` will be run by `testthat`.
The scripts will be run in **alphabetical order**.

The default exact regular expression used by `testthat` is:
`[Tt][Ee][Ss][Tt][-._].*\.sh`.
Thus you have a little flexibility in naming your test files by default.
If this is not sufficient, you can still redefine this pattern by using the
`-f` command line argument.
The pattern format must be a POSIX extended regular expression as required by
the `=~` comparison operator provided by the `[[` bash command.

### Writing a test script

A test scripts is composed of functions in which assertions (i.e.: the tests)
are written.
The functions are called individually with some description message that will
be printed in case of failure.

Here is a full example:
```sh
function test_someStuff {
	tt_expect_num_eq 1 2 || return 1
}

tt_context "Running some test for an example"
tt_test_that "Some stuff is running correctly." test_someStuff
```
The `tt_context` call define a title for the tests that will follow. It will be
printed in the output.
The `tt_test_that` function calls the test function `test_someStuff` and in
case of failure will display the message specified.
Inside the `test_someStuff` function you have to call assertions in order to
test code.

In this example we use the assertion `tt_expect_num_eq` (all assertions start
with `tt_expect_` as a prefix), which tests the equality of two numeric
numbers.
In our case the two numbers `1` and `2` will lead to a failure of the test.
But, please, note that in order to activate the failure it is **compulsory** to
append ` || return 1` to the assertion call, otherwise no failure will be
reported.

Each assertion will either lead to the printing of a dot (`.`) character in
case of success or another character in case of failure.
At the end of tests, each character printed to indicate a failure will again be
printed along with the message provided to the `tt_test_that` call and the call
stack.

For a full list of assertions, see the chapter about *Assertions*.

### Assertions

Assertions start all with the prefix `tt_expect_` and their call need to be
followed by ` || return 1` in order to report a failure.
Some assertions take a custom message to be displayed in case of failure.

#### Success/failure assertions

`tt_expect_success` tests the success of a command.

| Argument | Description |
|  :---:   | :---        |
|     *    | Command.    |

Example:
```sh
tt_expect_success my_command arg1 arg2 || return 1
```

`tt_expect_success_in_n_tries` tests that a command succeeds before n tries.

| Argument | Description |
|  :---:   | :---        |
|    1     | Number of tries.    |
|    *     | Command.    |

Example:
```sh
tt_expect_success_in_n_tries 3 my_command arg1 || return 1
```

`tt_expect_failure` tests the failure of a command.

| Argument | Description |
|  :---:   | :---        |
|     *    | Command.    |

Example:
```sh
tt_expect_failure my_command arg1 arg2 || return 1
```

`tt_expect_status` tests that a command fails and return a precise status value.

| Argument | Description |
|  :---:   | :---        |
|     1    | Expected status number. |
|     *    | Command.    |

Example:
```sh
tt_expect_status 4 my_command arg1 arg2 || return 1
```

`tt_expect_exit` tests the failure of a command by running the command inside
a subshell. Thus you can test a call to a function that call the `exit`
command.

| Argument | Description |
|  :---:   | :---        |
|     *    | Command.    |

Example:
```sh
tt_expect_exit my_command arg1 arg2 || return 1
```

`tt_expect_exit_status` tests that a command fails and return a precise status
value by running the command inside a subshell. Thus you can test a call to a
function that call the `exit` command.

| Argument | Description |
|  :---:   | :---        |
|     1    | Expected status number. |
|     *    | Command.    |

Example:
```sh
tt_expect_exit_status 0 my_command arg1 arg2 || return 1
```

#### Output assertions

`tt_expect_empty_output` tests if a command output nothing on stdout.

| Argument | Description |
|  :---:   | :---        |
|     *    | Command.    |

Example:
```sh
tt_expect_empty_output my_command arg1 arg2 || return 1
```

`tt_expect_non_empty_output` tests if a command output something on stdout.

| Argument | Description |
|  :---:   | :---        |
|     *    | Command.    |

Example:
```sh
tt_expect_non_empty_output my_command arg1 arg2 || return 1
```

`tt_expect_output_eq` tests if the output of a command is equals to a value.
The output is stripped from carriage returns before comparison.

| Argument | Description |
|  :---:   | :---        |
|     1    | Expected output as a string.    |
|     *    | Command.    |

Example:
```sh
tt_expect_output_eq "Expected Output" my_command arg1 arg2 || return 1
```

`tt_expect_output_ne` tests if the output of a command is equals to a value.
The output is stripped from carriage returns before comparison.

| Argument | Description |
|  :---:   | :---        |
|     1    | Expected output as a string.    |
|     *    | Command.    |

Example:
```sh
tt_expect_output_ne "Expected Output" my_command arg1 arg2 || return 1
```

`tt_expect_output_esc_eq` tests if the output of a command is equals to a
value.  Carriage returns are preserved.

| Argument | Description |
|  :---:   | :---        |
|     1    | Expected output as a string for echo command with trailing newline disabled and backslash escapes enabled. |
|     *    | Command.    |
                           
Example:
```sh
tt_expect_output_esc_eq "Expected Output" my_command arg1 arg2 || return 1
```

`tt_expect_output_esc_ne` tests if the output of a command is different from a
value.  Carriage returns are preserved.

| Argument | Description |
|  :---:   | :---        |
|     1    | Expected output as a string for echo command with trailing newline disabled and backslash escapes enabled. |
|     *    | Command.    |
                           
Example:
```sh
tt_expect_output_esc_ne "Expected Output" my_command arg1 arg2 || return 1
```

`tt_expect_output_nlines_eq` tests if a command output exactly n lines of text
on stdout.

| Argument | Description |
|  :---:   | :---        |
|     1    | Expected number of lines. |
|     *    | Command.    |
                           
Example:
```sh
tt_expect_output_nlines_eq 3 my_command arg1 arg2 || return 1
```

`tt_expect_output_nlines_ge` tests if a command output n lines or more of text
on stdout.

| Argument | Description                       |
|  :---:   | :---                              |
|     1    | Expected minimum number of lines. |
|     *    | Command.                          |

Example:
```sh
tt_expect_output_nlines_ge 3 my_command arg1 arg2 || return 1
```

`tt_expect_output_re` tests if the output of a command matches a regular
expression. The output is stripped from carriage returns before comparison.

| Argument | Description         |
|  :---:   | :---                |
|     1    | Regular expression. |
|     *    | Command.            |

Example:
```sh
tt_expect_output_re "A.*B" my_command arg1 arg2 || return 1
```

#### String assertions

`tt_expect_str_null` tests if a string is empty.

| Argument | Description         |
|  :---:   | :---                |
|     1    | String.             |
|     2    | Message (optional). |

Example:
```sh
tt_expect_str_null $s "My Msg." || return 1
```

`tt_expect_str_not_null` tests if a string is not empty.

| Argument | Description         |
|  :---:   | :---                |
|     1    | String.             |
|     2    | Message (optional). |

Example:
```sh
tt_expect_str_not_null $s "My Msg." || return 1
```

`tt_expect_str_eq` tests if two strings are equal.

| Argument | Description         |
|  :---:   | :---                |
|     1    | First string.       |
|     2    | Second string.      |
|     3    | Message (optional). |

Example:
```sh
tt_expect_str_eq $s "abc" "My Msg." || return 1
```

`tt_expect_str_ne` tests if two strings are different.

| Argument | Description         |
|  :---:   | :---                |
|     1    | First string.       |
|     2    | Second string.      |
|     3    | Message (optional). |

Example:
```sh
tt_expect_str_ne $s "abc" "My Msg." || return 1
```

`tt_expect_str_re` tests if a string matches an ERE.

| Argument | Description         |
|  :---:   | :---                |
|     1    | String.             |
|     2    | Pattern as an ERE.  |
|     3    | Message (optional). |

Example:
```sh
tt_expect_str_re $s "^[a-zA-Z]+-[0-9]+$" "My Msg" || return 1
```

#### Numerical assertions

`tt_expect_num_eq` tests the equality of two integers.

| Argument | Description         |
|  :---:   | :---                |
|     1    | First integer.      |
|     2    | Second integer.     |
|     3    | Message (optional). |

Example:
```sh
tt_expect_num_eq $n 2 "My Msg." || return 1
```

`tt_expect_num_ne` tests that two integers are different.

| Argument | Description         |
|  :---:   | :---                |
|     1    | First integer.      |
|     2    | Second integer.     |
|     3    | Message (optional). |

Example:
```sh
tt_expect_num_ne $$n 2 "My Msg." || return 1
```

`tt_expect_num_le` tests that an integer is lower or equal than another.

| Argument | Description         |
|  :---:   | :---                |
|     1    | First integer.      |
|     2    | Second integer.     |
|     3    | Message (optional). |

Example:
```sh
tt_expect_num_le $$n 5 "My Msg" || return 1
```

`tt_expect_num_gt` tests that an integer is strictly greater than another.

| Argument | Description         |
|  :---:   | :---                |
|     1    | First integer.      |
|     2    | Second integer.     |
|     3    | Message (optional). |

Example:
```sh
tt_expect_num_gt $$n 5 "My Msg" || return 1
```

#### Environment assertions

`tt_expect_def_env_var` tests if an environment variable is defined and not
empty.

| Argument | Description                        |
|  :---:   | :---                               |
|     1    | Name of the environement variable. |
|     2    | Message (optional).                |

Example:
```sh
tt_expect_def_env_var MY_VAR "My Msg" || return 1
```

#### File system assertions

`tt_expect_file` tests if file exists.

| Argument | Description         |
|  :---:   | :---                |
|     1    | File.               |
|     2    | Message (optional). |

Example:
```sh
tt_expect_folder "myFile" "My Msg" || return 1
```

`tt_expect_folder` tests if folder exists.

| Argument | Description         |
|  :---:   | :---                |
|     1    | Folder.             |
|     2    | Message (optional). |

Example:
```sh
tt_expect_folder "myFolder" "My Msg" || return 1
```

`tt_expect_symlink` tests if a symbolic link exists and points to a certain
location.

| Argument | Description                        |
|  :---:   | :---                               |
|     1    | Symbolic link path.                |
|     2    | The path to which the link points. |
|     3    | Message (optional).                |

Example:
```sh
tt_expect_symlink "/my/sym/link" "/the/file/to/which/it/points"
```

`tt_expect_no_path` tests if nothing exists (no file, no folder) at the
specified path.

| Argument | Description         |
|  :---:   | :---                |
|     1    | Path.               |
|     2    | Message (optional). |

Example:
```sh
tt_expect_no_path "myFolder" "My Msg" || return 1
```

`tt_expect_same_folders` tests if two folders have the same content, using
`diff` command.

| Argument | Description         |
|  :---:   | :---                |
|     1    | First folder.       |
|     2    | Second folder.      |

Example:
```sh
tt_expect_same_folders "folderA" "folderB" || return 1
```

`tt_expect_files_in_folder` tests if files matching a pattern exist inside a
folder.

| Argument | Description              |
|  :---:   | :---                     |
|     1    | Folder.                  |
|     2    | Files pattern as an ERE. |
|     3    | Message (optional).      |

Example:
```sh
tt_expect_files_in_folder "myFolder" "^.*\.txt$" "My Msg" || return 1
```

`tt_expect_other_files_in_folder` tests if a folder contains files not matching
a pattern.

| Argument | Description              |
|  :---:   | :---                     |
|     1    | Folder.                  |
|     2    | Files pattern as an ERE. |
|     3    | Message (optional).      |

Example:
```sh
tt_expect_other_files_in_folder "myFolder" "^.*\.txt$" "My Msg" || return 1
```

`tt_expect_no_other_files_in_folder` tests if a folder contains files matching
a pattern, and no other files.

| Argument | Description              |
|  :---:   | :---                     |
|     1    | Folder.                  |
|     2    | Files pattern as an ERE. |
|     3    | Message (optional).      |

Example:
```sh
tt_expect_no_other_files_in_folder "myFolder" "^.*\.txt$" "My Msg" || return 1
```

`tt_expect_files_in_tree` tests if files matching a pattern exist inside a tree
structure.

| Argument | Description                            |
|  :---:   | :---                                   |
|     1    | Folder in which to search recursively. |
|     2    | Files pattern as an ERE.               |
|     3    | Message (optional).                    |

Example:
```sh
tt_expect_files_in_tree "myFolder" "^.*\.txt$" "My Msg" || return 1
```

`tt_expect_other_files_in_tree` tests if files not matching a pattern exist
inside a tree structure, and no other files.

| Argument | Description                            |
|  :---:   | :---                                   |
|     1    | Folder in which to search recursively. |
|     2    | Files pattern as an ERE.               |
|     3    | Message (optional).                    |

Example:
```sh
tt_expect_other_files_in_tree "myFolder" "^.*\.txt$" "My Msg" || return 1
```

`tt_expect_no_other_files_in_tree` tests if files matching a pattern exist
inside a tree structure, and no other files.

| Argument | Description                            |
|  :---:   | :---                                   |
|     1    | Folder in which to search recursively. |
|     2    | Files pattern as an ERE.               |
|     3    | Message (optional).                    |

Example:
```sh
tt_expect_no_other_files_in_tree "myFolder" "^.*\.txt$" "My Msg" || return 1
```

`tt_expect_folder_is_writable` tests files can be created or modified inside a
folder.

| Argument | Description         |
|  :---:   | :---                |
|     1    | Path to the folder. |
|     2    | Message (optional). |

Example:
```sh
tt_expect_folder_is_writable "myFolder" "My Msg" || return 1
```

#### File assertions

`tt_expect_same_files` tests if two files are identical.

| Argument | Description |
|  :---:   | :---        |
|     1    | First file  |
|     2    | Second file |

Example:
```sh
tt_expect_same_files "myFile1" "myFile2" || return 1
```

`tt_expect_empty_file` tests if a file exists and is empty.

| Argument | Description         |
|  :---:   | :---                |
|     1    | File                |
|     2    | Message (optional). |

Example:
```sh
tt_expect_empty_file "myFile" || return 1
```

`tt_expect_non_empty_file` tests if a file exists and is not empty.

| Argument | Description         |
|  :---:   | :---                |
|     1    | File                |
|     2    | Message (optional). |

Example:
```sh
tt_expect_non_empty_file "myFile" || return 1
```

`tt_expect_no_duplicated_row` tests if a file contains no duplicated rows.

| Argument | Description         |
|  :---:   | :---                |
|     1    | File                |

Example:
```sh
tt_expect_no_duplicated_row "myFile" || return 1
```

`tt_expect_same_number_of_rows` tests if two files contain the same number of
lines.

| Argument | Description |
|  :---:   | :---        |
|     1    | First file  |
|     2    | Second file |

Example:
```sh
tt_expect_same_number_of_rows "myFile1" "myFile2" || return 1
```

#### CSV assertions

`tt_expect_csv_has_columns` tests if a CSV file contains a set of columns.
Second argument is the separator character used in the CSV.

| Argument | Description                                |
|  :---:   | :---                                       |
|     1    | File                                       |
|     2    | CSV separator character.                   |
|     3    | Expected column names separated by spaces. |

Example:
```sh
tt_expect_csv_has_columns "myfile.csv" "," "col1 col2 col3" || return 1
```

`tt_expect_csv_not_has_columns` tests if a CSV file does not contain a set of
columns.

| Argument | Description                       |
|  :---:   | :---                              |
|     1    | File                              |
|     2    | CSV separator character.          |
|     3    | Column names separated by spaces. |

Example:
```sh
tt_expect_csv_not_has_columns "myfile.csv" "," "col1 col2 col3" || return 1
```

`tt_expect_csv_identical_col_values` tests if two CSV files contain the same
column with the same values.

| Argument | Description              |
|  :---:   | :---                     |
|     1    | Column name.             |
|     2    | First file.              |
|     3    | Second file.             |
|     4    | CSV separator character. |

Example:
```sh
tt_expect_csv_identical_col_values "myCol" "myFile1" "myFile2" ";" || return 1
```

`tt_expect_csv_float_col_equals` tests if all the values of a CSV file column
are close to a float value.

| Argument | Description    |
|  :---:   | :---           |
|     1    | File.          |
|     2    | CSV separator. |
|     3    | Column name.   |
|     4    | Float value.   |
|     5    | Tolerance.     |

Example:
```sh
tt_expect_csv_float_col_equals "myFile" "," "myCol" 10.01 0.01 || return 1
```

`tt_expect_csv_same_col_names` tests if two CSV files contain the same column
names.

| Argument | Description                                                                                          |
|  :---:   | :---                                                                                                 |
|     1    | First file.                                                                                          |
|     2    | Second file.                                                                                         |
|     3    | CSV separator.                                                                                       |
|     4    | The number of columns on which to make the comparison. If unset all columns will be used (optional). |
|     5    | If set to 1, then double quotes will be removed from column names before comparison (optional).      |

Example:
```sh
tt_expect_csv_same_col_names "myFile1" "myFile2" ";" 8 1 || return 1
```

## Glossary

| Term  | Description |
| :---: | :---        |
| ERE   |  Extended Regular Expression. |

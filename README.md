# bash-lib

## str

## argparse

## os

## logging

## testthat

`testthat` library is a test library for testing bash functions and programs.

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

### Assertions

   Assertions start all with the prefix "expect_" and need to be followed by
   " || return 1" in order to report a failure.
   Some assertions take a custom message to be displayed in case of failure.

Success/failure assertions:

   expect_success   Test the success of a command.
                    Arguments: command.
                    Example:
                       expect_success my_command || return 1
                       expect_success my_command arg1 arg2 || return 1

   expect_success_in_n_tries
                    Test that a command succeeds before n tries.
                    Arg. 1: Number of tries.
                    Remaining arguments: command.
                    Example:
                       expect_success_in_n_tries 3 my_command || return 1
                       expect_success_in_n_tries 3 my_command arg1 || return 1

   expect_failure   Test the failure of a command.
                    Arguments: command.
                    Example:
                       expect_failure my_command || return 1
                       expect_failure my_command arg1 arg2 || return 1

   expect_status    Test that a command fails and return a precise status value.
                    Arg. 1: Expected status number.
                    Remaining arguments: command.
                    Example:
                       expect_status 0 my_command || return 1
                       expect_status 4 my_command || return 1
                       expect_status 4 my_command arg1 arg2 || return 1

   expect_exit      Test the failure of a command by running the command inside
                    a subshell. Thus you can test a call to a function that
                    call the \`exit\` command.
                    Arguments: command.
                    Example:
                       expect_exit my_command || return 1
                       expect_exit my_command arg1 arg2 || return 1

   expect_exit_status
                    Test that a command fails and return a precise status value
                    by running the command inside a subshell. Thus you can test
                    a call to a function that call the \`exit\` command.
                    Arg. 1: Expected status number.
                    Remaining arguments: command.
                    Example:
                       expect_exit_status 2 my_command || return 1
                       expect_exit_status 0 my_command arg1 arg2 || return 1

Output assertions:

   expect_empty_output
                    Test if a command output nothing on stdout.
                    Arguments: command.
                    Example:
                       expect_empty_output my_command arg1 arg2 || return 1

   expect_non_empty_output
                    Test if a command output something on stdout.
                    Arguments: command.
                    Example:
                       expect_non_empty_output my_command arg1 arg2 || return 1

   expect_output_eq Test if the output of a command is equals to a value. The
                    output is stripped from carriage returns before comparison.
                    Arg. 1: Expected output as a string.
                    Remaining arguments: command.
                    Example:
                       expect_output_eq "Expected Output" my_command arg1 arg2 || return 1

   expect_output_ne Test if the output of a command is equals to a value. The
                    output is stripped from carriage returns before comparison.
                    Arg. 1: Expected output as a string.
                    Remaining arguments: command.
                    Example:
                       expect_output_ne "Expected Output" my_command arg1 arg2 || return 1

   expect_output_esc_eq
                    Test if the output of a command is equals to a value.
                    Carriage returns are preserved.
                    Arg. 1: Expected output as a string for echo command with
                            trailing newline disabled and backslash escapes
                            enabled.
                    Remaining arguments: command.
                    Example:
                       expect_output_esc_eq "Expected Output" my_command arg1 arg2 || return 1

   expect_output_esc_ne
                    Test if the output of a command is different from a value.
                    Carriage returns are preserved.
                    Arg. 1: Expected output as a string for echo command with
                            trailing newline disabled and backslash escapes
                            enabled.
                    Remaining arguments: command.
                    Example:
                       expect_output_esc_ne "Expected Output" my_command arg1 arg2 || return 1

   expect_output_nlines_eq
                    Test if a command output exactly n lines of text on stdout.
                    Arg. 1: Expected number of lines.
                    Remaining arguments: command.
                    Example:
                       expect_output_nlines_eq 3 my_command arg1 arg2 || return 1

   expect_output_nlines_ge
                    Test if a command output n lines or more of text on stdout.
                    Arg. 1: Expected minimum number of lines.
                    Remaining arguments: command.
                    Example:
                       expect_output_nlines_ge 3 my_command arg1 arg2 || return 1

   expect_output_re Test if the output of a command matches a regular
                    expression. The output is stripped from carriage returns
                    before comparison.
                    Arg. 1: Regular expression.
                    Remaining arguments: command.
                    Example:
                       expect_output_re "A.*B" my_command arg1 arg2 || return 1

String assertions:

   expect_str_null  Test if a string is empty.
                    Arg. 1: String.
                    Arg. 2: Message (optional).
                    Example:
                       expect_str_null $$s || return 1
                       expect_str_null $$s "My Msg." || return 1

   expect_str_not_null
                    Test if a string is not empty.
                    Arg. 1: String.
                    Arg. 2: Message (optional).
                    Example:
                       expect_str_not_null $$s || return 1
                       expect_str_not_null $$s "My Msg." || return 1

   expect_str_eq    Test if two strings are equal.
                    Arg. 1: First string.
                    Arg. 2: Second string.
                    Arg. 3: Message (optional).
                    Example:
                       expect_str_eq $$s "abc" || return 1
                       expect_str_eq $$s "abc" "My Msg." || return 1

   expect_str_ne    Test if two strings are different.
                    Arg. 1: First string.
                    Arg. 2: Second string.
                    Arg. 3: Message (optional).
                    Example:
                       expect_str_ne $$s "abc" || return 1
                       expect_str_ne $$s "abc" "My Msg." || return 1

   expect_str_re    Test if a string matches an ERE.
                    Arg. 1: String.
                    Arg. 2: Pattern as an ERE.
                    Arg. 3: Message (optional).
                    Example:
                       expect_str_re $$s "^[a-zA-Z]+-[0-9]+$" || return 1
                       expect_str_re $$s "^[a-zA-Z]+-[0-9]+$" "My Msg" || return 1

Numeric assertions:

   expect_num_eq    Test the equality of two integers.
                    Arg. 1: First integer.
                    Arg. 2: Second integer.
                    Arg. 3: Message (optional).
                    Example:
                       expect_num_eq $$n 2 || return 1
                       expect_num_eq $$n 2 "My Msg." || return 1

   expect_num_ne    Test that two integers are different.
                    Arg. 1: First integer.
                    Arg. 2: Second integer.
                    Arg. 3: Message (optional).
                    Example:
                       expect_num_ne $$n 2 || return 1
                       expect_num_ne $$n 2 "My Msg." || return 1

   expect_num_le    Test that an integer is lower or equal than another.
                    Arg. 1: First integer.
                    Arg. 2: Second integer.
                    Arg. 3: Message (optional).
                    Example:
                       expect_num_le $$n 5 || return 1
                       expect_num_le $$n 5 "My Msg" || return 1

   expect_num_gt    Test that an integer is strictly greater than another.
                    Arg. 1: First integer.
                    Arg. 2: Second integer.
                    Arg. 3: Message (optional).
                    Example:
                       expect_num_gt $$n 5 || return 1
                       expect_num_gt $$n 5 "My Msg" || return 1

Environment assertions:

   expect_def_env_var
                    Test if an environment variable is defined and not empty.
                    Arg. 1: Name of the environement variable.
                    Arg. 2: Message (optional).
                    Example:
                       expect_def_env_var MY_VAR || return 1
                       expect_def_env_var MY_VAR "My Msg" || return 1

File system assertions:

   expect_file      Test if file exists.
                    Arg. 1: File.
                    Arg. 2: Message (optional).
                    Example:
                       expect_folder "myFile" || return 1
                       expect_folder "myFile" "My Msg" || return 1

   expect_folder    Test if folder exists.
                    Arg. 1: Folder.
                    Arg. 2: Message (optional).
                    Example:
                       expect_folder "myFolder" || return 1
                       expect_folder "myFolder" "My Msg" || return 1

   expect_symlink   Test if a symbolic link exists and points to a certain
                    location.
                    Arg. 1: Symbolic link path.
                    Arg. 2: The path to which the link points.
                    Arg. 3: Message (optional).
                    Example:
                      expect_symlink "/my/sym/link" "/the/file/to/which/it/points"

   expect_no_path   Test if nothing exists (no file, no folder) at the
                    specified path.
                    Arg. 1: Path.
                    Arg. 2: Message (optional).
                    Example:
                       expect_no_path "myFolder" || return 1
                       expect_no_path "myFolder" "My Msg" || return 1

   expect_same_folders
                    Test if two folders have the same content, using "diff"
                    command.
                    Arg. 1: First folder.
                    Arg. 2: Second folder.
                    Example:
                       expect_same_folders "folderA" "folderB" || return 1

   expect_files_in_folder
                    Test if files matching a pattern exist inside a folder.
                    Arg. 1: Folder.
                    Arg. 2: Files pattern as an ERE.
                    Arg. 3: Message (optional).
                    Example:
                       expect_files_in_folder "myFolder" "^.*\.txt$" || return 1
                       expect_files_in_folder "myFolder" "^.*\.txt$" "My Msg" || return 1

   expect_other_files_in_folder
                    Test if a folder contains files not matching a pattern.
                    Arg. 1: Folder.
                    Arg. 2: Files pattern as an ERE.
                    Arg. 3: Message (optional).
                    Example:
                       expect_other_files_in_folder "myFolder" "^.*\.txt$" || return 1
                       expect_other_files_in_folder "myFolder" "^.*\.txt$" "My Msg" || return 1

   expect_no_other_files_in_folder
                    Test if a folder contains files matching a pattern, and no
                    other files.
                    Arg. 1: Folder.
                    Arg. 2: Files pattern as an ERE.
                    Arg. 3: Message (optional).
                    Example:
                       expect_no_other_files_in_folder "myFolder" "^.*\.txt$" || return 1
                       expect_no_other_files_in_folder "myFolder" "^.*\.txt$" "My Msg" || return 1

   expect_files_in_tree
                    Test if files matching a pattern exist inside a tree structure.
                    Arg. 1: Folder in which to search recursively.
                    Arg. 2: Files pattern as an ERE.
                    Arg. 3: Message (optional).
                    Example:
                       expect_files_in_tree "myFolder" "^.*\.txt$" || return 1
                       expect_files_in_tree "myFolder" "^.*\.txt$" "My Msg" || return 1

   expect_other_files_in_tree
                    Test if files not matching a pattern exist inside a tree
                    structure, and no other files.
                    Arg. 1: Folder in which to search recursively.
                    Arg. 2: Files pattern as an ERE.
                    Arg. 3: Message (optional).
                    Example:
                       expect_other_files_in_tree "myFolder" "^.*\.txt$" || return 1
                       expect_other_files_in_tree "myFolder" "^.*\.txt$" "My Msg" || return 1

   expect_no_other_files_in_tree
                    Test if files matching a pattern exist inside a tree
                    structure, and no other files.
                    Arg. 1: Folder in which to search recursively.
                    Arg. 2: Files pattern as an ERE.
                    Arg. 3: Message (optional).
                    Example:
                       expect_no_other_files_in_tree "myFolder" "^.*\.txt$" || return 1
                       expect_no_other_files_in_tree "myFolder" "^.*\.txt$" "My Msg" || return 1

   expect_folder_is_writable
                    Test files can be created or modified inside a folder.
                    Arg. 1: Path to the folder.
                    Arg. 3: Message (optional).
                    Example:
                       expect_folder_is_writable "myFolder" "My Msg" || return 1

File assertions:

   expect_same_files
                    Test if two files are identical.
                    Arg. 1: File 1.
                    Arg. 2: File 2.
                    Example:
                       expect_same_files "myFile1" "myFile2" || return 1

   expect_empty_file
                    Test if a file exists and is empty.
                    Arg. 1: File.
                    Arg. 2: Message (optional).
                    Example:
                       expect_empty_file "myFile" || return 1

   expect_non_empty_file
                    Test if a file exists and is not empty.
                    Arg. 1: File.
                    Arg. 2: Message (optional).
                    Example:
                       expect_non_empty_file "myFile" || return 1

   expect_no_duplicated_row
                    Test if a file contains no duplicated rows.
                    Arg. 1: File.
                    Example:
                       expect_no_duplicated_row "myFile" || return 1

   expect_same_number_of_rows
                    Test if two files contain the same number of lines.
                    Arg. 1: File 1.
                    Arg. 2: File 2.
                    Example:
                       expect_same_number_of_rows "myFile1" "myFile2" || return 1

CSV assertions:

   expect_csv_has_columns
                    Test if a CSV file contains a set of columns. Second
                    argument is the separator character used in the CSV.
                    Arg. 1: File.
                    Arg. 2: CSV separator character.
                    Arg. 3: Expected column names separated by spaces.
                    Example:
                       expect_csv_has_columns "myfile.csv" "," "col1 col2 col3" || return 1

   expect_csv_not_has_columns
                    Test if a CSV file does not contain a set of columns.
                    Arg. 1: File.
                    Arg. 2: CSV separator character.
                    Arg. 3: Column names separated by spaces.
                    Example:
                       expect_csv_not_has_columns "myfile.csv" "," "col1 col2 col3" || return 1

   expect_csv_identical_col_values
                    Test if two CSV files contain the same column with the same
                    values.
                    Arg. 1: Column name.
                    Arg. 2: File 1.
                    Arg. 3: File 2.
                    Arg. 4: CSV separator character.
                    Example:
                       expect_csv_identical_col_values "myCol" "myFile1" "myFile2" ";" || return 1

   expect_csv_float_col_equals
                    Test if all the values of a CSV file column are close to a float value.
                    Arg. 1: File.
                    Arg. 2: CSV separator.
                    Arg. 3: Column name.
                    Arg. 4: Float value.
                    Arg. 5: Tolerance.
                    Example:
                       expect_csv_float_col_equals "myFile" "," "myCol" 10.01 0.01 || return 1

   expect_csv_same_col_names
                    Test if two CSV files contain the same column names.
                    Arg. 1: File 1.
                    Arg. 2: File 2.
                    Arg. 3: CSV separator.
                    Arg. 4: The number of columns on which to make the
                            comparison. If unset all columns will be used
                            (optional).
                    Arg. 5: If set to 1, then double quotes will be removed
                            from column names before comparison (optional).
                    Example:
                       expect_csv_same_col_names "myFile1" "myFile2" ";" || return 1
                       expect_csv_same_col_names "myFile1" "myFile2" ";" 8 || return 1
                       expect_csv_same_col_names "myFile1" "myFile2" ";" 8 1 || return 1

GLOSSARY

   ERE      Extended Regular Expression.

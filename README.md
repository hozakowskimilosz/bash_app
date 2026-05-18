# CSV Statistics Calculator

## Overview
This is a Bash script that processes CSV files to calculate the Minimum, Maximum, and Average values for all numeric columns. It utilizes `awk` for fast and efficient data processing. The script automatically detects and ignores columns containing non-numeric text, ensuring safe and accurate mathematical operations.

## Features
* **Automatic Data Validation:** Identifies and processes only numeric columns; safely ignores text or mixed-data columns.
* **Flexible Input:** Accepts multiple CSV files as arguments or reads directly from standard input (stdin) if no files are provided.
* **Customizable Output:** Saves the processed data (original rows + calculated statistics) to a new file. The default postfix is `.mod`, but it can be customized.
* **Toggleable Statistics:** Allows users to selectively disable the calculation of MIN, MAX, or AVG via command-line flags.

## Usage
`bash
./zadanie.sh [OPTIONS] [FILES...]
`

### Options
* `-h` : Display the help message and exit.
* `-p <postfix>` : Define a custom postfix for the output file (default: `.mod`).
* `--no-min` : Disable the calculation of Minimum values.
* `--no-max` : Disable the calculation of Maximum values.
* `--no-avg` : Disable the calculation of Average values.

## Examples

**1. Process a single file with default settings:**
`bash
./zadanie.sh data.csv
`
*(Output will be saved as `data.csv.mod`)*

**2. Process multiple files and change the output postfix:**
`bash
./zadanie.sh -p _results.csv data1.csv data2.csv
`
*(Outputs will be saved as `data1.csv_results.csv` and `data2.csv_results.csv`)*

**3. Calculate only the Average (disable min and max):**
`bash
./zadanie.sh --no-min --no-max data.csv
`

**4. Read from Standard Input (stdin):**
`bash
cat data.csv | ./zadanie.sh
`

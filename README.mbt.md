# NyaCSV

> Parse CSV files in MoonBit with a small, focused API.

[![Build Status](https://img.shields.io/github/actions/workflow/status/moonbit-community/NyaCSV/ci.yml)](https://github.com/moonbit-community/NyaCSV/actions)
[![License](https://img.shields.io/github/license/moonbit-community/NyaCSV)](LICENSE)
[![codecov](https://codecov.io/gh/moonbit-community/NyaCSV/branch/main/graph/badge.svg)](https://codecov.io/gh/moonbit-community/NyaCSV)

NyaCSV parses CSV data from strings, buffers, and bytes. It supports custom delimiters, quoted fields, multiline fields, optional whitespace trimming, header extraction, generated headers, and formatted output.

## Features

- **Multiple input sources**: parse CSV from `String`, `Buffer`, or `Bytes`.
- **Configurable parsing**: set delimiter, quote character, whitespace trimming, empty-line handling, and multiline quoted fields.
- **Header handling**: use the first row as headers or generate column names.
- **Simple accessors**: read headers, rows, and shape through public methods.
- **Formatted output**: render a table through the `Show` implementation.

## Quick Start

```mbt check
///|
test "readme/quick_start" {
  let data =
    #|Name,Age,Favorite Toy
    #|Mittens,3,Ball of yarn
    #|Whiskers,5,Laser pointer
    #|
  let csv = CSV::parse_string(data)
  let (rows, columns) = csv.shape()
  assert_eq(rows, 2)
  assert_eq(columns, 3)
  assert_eq(csv.header()[0], "Name")
  assert_eq(csv.header()[2], "Favorite Toy")
  assert_eq(csv.data()[0][0], "Mittens")
  assert_eq(csv.data()[1][2], "Laser pointer")
}
```

## Installation

Add NyaCSV to your MoonBit project with `moon add moonbit-community/NyaCSV`.

## Usage Examples

### Parsing CSV with Custom Options

```mbt check
///|
test "readme/custom_options" {
  let data =
    #|Name;Description;Adopted
    #|Simba;"Playful orange tabby
    #|Loves treats";Yes
    #|
  let csv = CSV::parse_string(data, options={
    delimiter: ';',
    allow_newlines_in_quotes: true,
    quote_char: '"',
    skip_empty_lines: true,
    trim_spaces: true,
  })
  assert_eq(csv.header()[0], "Name")
  assert_eq(csv.header()[1], "Description")
  assert_eq(csv.data()[0][0], "Simba")
  let description =
    #|Playful orange tabby
    #|Loves treats
  assert_eq(csv.data()[0][1], description)
  assert_eq(csv.data()[0][2], "Yes")
}
```

### Creating CSV Data

```mbt check
///|
test "readme/create_from_array" {
  let data : Array[Array[String]] = [
    ["Name", "Age"],
    ["Luna", "2"],
    ["Oliver", "1"],
  ]
  let csv = CSV::from_array(data)
  assert_eq(csv.header().length(), 2)
  assert_eq(csv.data().length(), 2)
  assert_eq(csv.header()[0], "Name")
  assert_eq(csv.data()[0][0], "Luna")
  let expected =
    #|Name,Age
    #|Luna,2
    #|Oliver,1
    #|
  assert_eq(csv.to_string(), expected)
}
```

### Working with 2D Arrays

```mbt check
///|
test "readme/array_input" {
  let shelter_data : Array[Array[String]] = [
    ["Name", "Age", "Color", "Adopted"],
    ["Luna", "2", "Black", "Yes"],
    ["Oliver", "1", "Tabby", "No"],
    ["Bella", "4", "Calico", "Yes"],
  ]
  let csv = CSV::from_array(shelter_data)
  let (rows, columns) = csv.shape()
  assert_eq(rows, 3)
  assert_eq(columns, 4)
  assert_eq(csv.data()[2][0], "Bella")
  assert_eq(csv.data()[2][3], "Yes")
}
```

### Generated Headers

```mbt check
///|
test "readme/generated_headers" {
  let data : Array[Array[String]] = [
    ["Alice", "30", "Wonderland"],
    ["Bob", "25", "Builderland"],
  ]
  let csv = CSV::from_array(data, has_header=false, generate_headers=true)
  assert_eq(csv.header()[0], "column1")
  assert_eq(csv.header()[1], "column2")
  assert_eq(csv.header()[2], "column3")
  assert_eq(csv.data()[1][0], "Bob")
}
```

## API Reference

### `CSV`

`CSV` is the parsed CSV value. Its fields are private; use `header()`, `data()`, `shape()`, `to_string()`, and `output(logger)` to work with it.

### `CSVOptions`

`CSVOptions` controls parsing:

- `delimiter : Char`
- `allow_newlines_in_quotes : Bool`
- `quote_char : Char`
- `skip_empty_lines : Bool`
- `trim_spaces : Bool`

### Parsing Methods

- `CSV::parse_string(data : String, options? : CSVOptions) -> CSV`
- `CSV::parse_buffer(data : Buffer, options? : CSVOptions) -> CSV`
- `CSV::parse_bytes(data : Bytes, options? : CSVOptions) -> CSV`

### Creation Methods

- `CSV::new() -> CSV`
- `CSV::from_array(data : Array[Array[String]], has_header? : Bool, generate_headers? : Bool) -> CSV`

## Advanced Examples

### Formatted Table Output

```mbt check
///|
test "readme/formatted_table_output" {
  let data =
    #|Breed,Origin,Size,Temperament
    #|Siamese,Thailand,Medium,"Vocal, Active"
    #|Maine Coon,USA,Large,"Gentle, Playful"
    #|Ragdoll,USA,Large,"Calm, Affectionate"
    #|
  let csv = CSV::parse_string(data)
  let logger = @buffer.new()
  csv.output(logger)
  let table = logger.contents().to_unchecked_string()
  assert_true(table.contains("Breed"))
  assert_true(table.contains("Maine Coon"))
  assert_true(table.contains("Gentle, Playful"))
}
```

### Handling Multiline Fields

```mbt check
///|
test "readme/multiline_fields" {
  let data =
    #|Name,Bio
    #|Lucy,"Lucy is curious.
    #|She loves exploring."
    #|Max,"Max is quiet.
    #|He sleeps often."
    #|
  let csv = CSV::parse_string(data)
  assert_eq(csv.header()[1], "Bio")
  let lucy_bio =
    #|Lucy is curious.
    #|She loves exploring.
  let max_bio =
    #|Max is quiet.
    #|He sleeps often.
  assert_eq(csv.data()[0][1], lucy_bio)
  assert_eq(csv.data()[1][1], max_bio)
}
```

## Contribution

Contributions are welcome. Please open issues and pull requests on GitHub.

## License

Apache-2.0

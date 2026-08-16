///|
/// Represents configuration options for CSV parsing operations.
///
/// Parameters:
///
/// * `delimiter` : Character used to separate fields in the CSV data (typically
/// a comma ',').
/// * `allow_newlines_in_quotes` : Boolean flag indicating whether newline
/// characters are allowed within quoted fields.
/// * `quote_char` : Character used for quoting fields that contain special
/// characters (typically a double quote '"').
/// * `skip_empty_lines` : Boolean flag indicating whether empty lines in the
/// input should be ignored.
/// * `trim_spaces` : Boolean flag indicating whether leading and trailing
/// whitespace should be removed from fields.
///
pub(all) struct CSVOptions {
  delimiter : Char
  allow_newlines_in_quotes : Bool
  quote_char : Char
  skip_empty_lines : Bool
  trim_spaces : Bool
}

///|
priv trait CSVReader {
  fn read_char(Self) -> Char?
  fn peek_char(Self) -> Char?
  fn is_eof(Self) -> Bool
}

///|
priv struct StringReader {
  source : String
  mut pos : Int
}

///|
impl CSVReader for StringReader with fn read_char(self) -> Char? {
  if self.pos < self.source.length() {
    let ch = Int::unsafe_to_char(self.source.code_unit_at(self.pos).to_int())
    self.pos += 1
    Some(ch)
  } else {
    None
  }
}

///|
test "StringReader::read_char/normal_case" {
  let reader : StringReader = { source: "Hello, World!", pos: 0 }
  assert_true(reader.read_char() is Some('H'))
  assert_true(reader.read_char() is Some('e'))
  assert_true(reader.read_char() is Some('l'))
}

///|
test "StringReader::read_char/empty_string" {
  let reader : StringReader = { source: "", pos: 0 }
  assert_true(reader.read_char() is None)
}

///|
test "StringReader::read_char/past_end_of_string" {
  let reader : StringReader = { source: "Hello", pos: 5 } // 'pos' is set to the length of the string
  assert_true(reader.read_char() is None)
}

///|
impl CSVReader for StringReader with fn peek_char(self) -> Char? {
  if self.pos < self.source.length() {
    Some(Int::unsafe_to_char(self.source.code_unit_at(self.pos).to_int()))
  } else {
    None
  }
}

///|
test "StringReader::peek_char/normal_case" {
  let reader : StringReader = { source: "Hello, World!", pos: 0 }
  assert_true(reader.peek_char() is Some('H'))
  reader.pos = 7
  assert_true(reader.peek_char() is Some('W'))
}

///|
test "StringReader::peek_char/empty_string" {
  let reader : StringReader = { source: "", pos: 0 }
  assert_true(reader.peek_char() is None)
}

///|
test "StringReader::peek_char/at_end_of_string" {
  let reader : StringReader = { source: "Hello", pos: 5 } // 'pos' is set to the length of the string
  assert_true(reader.peek_char() is None)
}

///|
impl CSVReader for StringReader with fn is_eof(self) -> Bool {
  self.pos >= self.source.length()
}

///|
extend StringReader with CSVReader::{read_char, peek_char}

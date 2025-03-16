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
pub struct CSVOptions {
  delimiter : Char
  allow_newlines_in_quotes : Bool
  quote_char : Char
  skip_empty_lines : Bool
  trim_spaces : Bool
}

///|
priv trait CSVReader {
  read_char(Self) -> Char?
  peek_char(Self) -> Char?
  is_eof(Self) -> Bool
}

///|
priv struct StringReader {
  source : String
  mut pos : Int
}

///|
impl CSVReader for StringReader with read_char(self) -> Char? {
  if self.pos < self.source.length() {
    let ch = self.source[self.pos]
    self.pos += 1
    Some(ch)
  } else {
    None
  }
}

///|
impl CSVReader for StringReader with peek_char(self) -> Char? {
  if self.pos < self.source.length() {
    Some(self.source[self.pos])
  } else {
    None
  }
}

///|
impl CSVReader for StringReader with is_eof(self) -> Bool {
  self.pos >= self.source.length()
}

///|
priv struct BufferReader {
  bytes : Bytes
  mut pos : Int
}

///|
impl CSVReader for BufferReader with read_char(self) -> Char? {
  if self.pos >= self.bytes.length() {
    return None
  }
  if self.pos + 1 >= self.bytes.length() {
    return None
  }
  let first_unit = self.bytes.to_unchecked_string(offset=self.pos, length=2)[0]
  let first_code = first_unit.to_int()
  if first_code >= 0xD800 && first_code <= 0xDBFF {
    if self.pos + 3 >= self.bytes.length() {
      self.pos += 2
      return Some('�')
    }
    let second_unit = self.bytes.to_unchecked_string(
        offset=self.pos + 2,
        length=2,
      )[0]
    let second_code = second_unit.to_int()
    if second_code >= 0xDC00 && second_code <= 0xDFFF {
      let code = self.bytes.to_unchecked_string(offset=self.pos, length=4)[0]
      self.pos += 4
      return Some(code)
    }
    self.pos += 2
    return Some('�')
  }
  self.pos += 2
  return Some(first_unit)
}

///|
impl CSVReader for BufferReader with peek_char(self) -> Char? {
  let pos = self.pos
  if pos >= self.bytes.length() {
    return None
  }
  if pos + 1 >= self.bytes.length() {
    return None
  }
  let first_unit = self.bytes.to_unchecked_string(offset=pos, length=2)[0]
  let first_code = first_unit.to_int()
  if first_code >= 0xD800 && first_code <= 0xDBFF {
    if pos + 3 >= self.bytes.length() {
      return Some('�')
    }
    let second_unit = self.bytes.to_unchecked_string(offset=pos + 2, length=2)[0]
    let second_code = second_unit.to_int()
    if second_code >= 0xDC00 && second_code <= 0xDFFF {
      let code = self.bytes.to_unchecked_string(offset=pos, length=4)[0]
      return Some(code)
    }
    return Some('�')
  }
  return Some(first_unit)
}

///|
impl CSVReader for BufferReader with is_eof(self) -> Bool {
  self.pos >= self.bytes.length()
}

///|
priv struct BytesReader {
  source : Bytes
  mut pos : Int
}

///|
impl CSVReader for BytesReader with read_char(self) -> Char? {
  if self.pos >= self.source.length() {
    return None
  }
  if self.pos + 1 >= self.source.length() {
    return None
  }
  let first_unit = self.source.to_unchecked_string(offset=self.pos, length=2)[0]
  let first_code = first_unit.to_int()
  if first_code >= 0xD800 && first_code <= 0xDBFF {
    if self.pos + 3 >= self.source.length() {
      self.pos += 2
      return Some('�')
    }
    let second_unit = self.source.to_unchecked_string(
        offset=self.pos + 2,
        length=2,
      )[0]
    let second_code = second_unit.to_int()
    if second_code >= 0xDC00 && second_code <= 0xDFFF {
      let code = self.source.to_unchecked_string(offset=self.pos, length=4)[0]
      self.pos += 4
      return Some(code)
    }
    self.pos += 2
    return Some('�')
  }
  self.pos += 2
  return Some(first_unit)
}

///|
impl CSVReader for BytesReader with peek_char(self) -> Char? {
  let pos = self.pos
  if pos >= self.source.length() {
    return None
  }
  if pos + 1 >= self.source.length() {
    return None
  }
  let first_unit = self.source.to_unchecked_string(offset=pos, length=2)[0]
  let first_code = first_unit.to_int()
  if first_code >= 0xD800 && first_code <= 0xDBFF {
    if pos + 3 >= self.source.length() {
      return Some('�')
    }
    let second_unit = self.source.to_unchecked_string(offset=pos + 2, length=2)[0]
    let second_code = second_unit.to_int()
    if second_code >= 0xDC00 && second_code <= 0xDFFF {
      let code = self.source.to_unchecked_string(offset=pos, length=4)[0]
      return Some(code)
    }
    return Some('�')
  }
  return Some(first_unit)
}

///|
impl CSVReader for BytesReader with is_eof(self) -> Bool {
  self.pos >= self.source.length()
}

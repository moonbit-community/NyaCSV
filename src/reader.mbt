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
test "StringReader::read_char/normal_case" {
  let reader : StringReader = { source: "Hello, World!", pos: 0 }
  inspect!(reader.read_char(), content="Some('H')")
  inspect!(reader.read_char(), content="Some('e')")
  inspect!(reader.read_char(), content="Some('l')")
}

///|
test "StringReader::read_char/empty_string" {
  let reader : StringReader = { source: "", pos: 0 }
  inspect!(reader.read_char(), content="None")
}

///|
test "StringReader::read_char/past_end_of_string" {
  let reader : StringReader = { source: "Hello", pos: 5 } // 'pos' is set to the length of the string
  inspect!(reader.read_char(), content="None")
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
test "StringReader::peek_char/normal_case" {
  let reader : StringReader = { source: "Hello, World!", pos: 0 }
  inspect!(reader.peek_char(), content="Some('H')")
  reader.pos = 7
  inspect!(reader.peek_char(), content="Some('W')")
}

///|
test "StringReader::peek_char/empty_string" {
  let reader : StringReader = { source: "", pos: 0 }
  inspect!(reader.peek_char(), content="None")
}

///|
test "StringReader::peek_char/at_end_of_string" {
  let reader : StringReader = { source: "Hello", pos: 5 } // 'pos' is set to the length of the string
  inspect!(reader.peek_char(), content="None")
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
  // 读取第一个UTF-16代码单元（注意是小端序）
  let first_byte = self.bytes[self.pos]
  let second_byte = self.bytes[self.pos + 1]
  let first_code = (second_byte.to_int() << 8) | first_byte.to_int()

  // 检查是否是高代理项
  if first_code >= 0xD800 && first_code <= 0xDBFF {
    // 需要读取低代理项，确保有足够的字节
    if self.pos + 3 >= self.bytes.length() {
      self.pos += 2
      return Some('�')
    }

    // 读取第二个UTF-16代码单元（小端序）
    let third_byte = self.bytes[self.pos + 2]
    let fourth_byte = self.bytes[self.pos + 3]
    let second_code = (fourth_byte.to_int() << 8) | third_byte.to_int()

    // 检查是否是有效的低代理项
    if second_code >= 0xDC00 && second_code <= 0xDFFF {
      // 使用正确的方式解析完整的字符
      let code_point = (0x10000 + ((first_code - 0xD800) << 10)) |
        (second_code - 0xDC00)
      let ch = Char::from_int(code_point)
      self.pos += 4
      return Some(ch)
    }
    self.pos += 2
    return Some('�')
  }

  // 单个UTF-16代码单元
  let ch = Char::from_int(first_code)
  self.pos += 2
  return Some(ch)
}

///|
test "BufferReader::read_char/ascii" {
  let buffer = @buffer.new()
  buffer.write_string("AB") // Basic ASCII characters
  let reader = { bytes: buffer.contents(), pos: 0 }
  inspect!(reader.read_char(), content="Some('A')")
  inspect!(reader.read_char(), content="Some('B')")
  inspect!(reader.read_char(), content="None")
  inspect!(reader.read_char(), content="None")
}

///|
test "BufferReader::read_char/ascii_with_none" {
  let buffer = @buffer.new()
  buffer.write_string("AB") // Basic ASCII characters
  let reader = { bytes: buffer.contents(), pos: 0 }
  inspect!(reader.read_char(), content="Some('A')")
  inspect!(reader.read_char(), content="Some('B')")
  inspect!(reader.read_char(), content="None")
}

///|
test "BufferReader::read_char/utf16_surrogate" {
  let buffer = @buffer.new()
  buffer.write_bytes(Bytes::of_string("🌟")) // Valid surrogate pair
  let reader = { bytes: buffer.contents(), pos: 0 }
  inspect!(reader.read_char(), content="Some('🌟')")
  inspect!(reader.read_char(), content="None")
}

///|
test "BufferReader::read_char/single_byte_buffer" {
  let buffer = @buffer.new()
  buffer.write_byte(0x41) // 只写入一个字节 'A'
  let reader = { bytes: buffer.contents(), pos: 0 }
  inspect!(reader.read_char(), content="None") // 应返回None，因为UTF-16至少需要2个字节
}

///| 
test "BufferReader::read_char/invalid_sequence" {
  let buffer = @buffer.new() // Create a buffer with an incomplete surrogate pair 
  // 使用小端序写入高代理项 0xD802 (第一个字节是 0x02，第二个字节是 0xD8)
  buffer.write_byte(0x02)
  buffer.write_byte(0xD8)
  let reader = { bytes: buffer.contents(), pos: 0 }
  inspect!(reader.read_char(), content="Some('�')")
  inspect!(reader.read_char(), content="None")
}

///|
test "BufferReader::read_char/empty_buffer" {
  let bytes = Bytes::new(0)
  let reader : BufferReader = { bytes, pos: 0 }
  inspect!(reader.read_char(), content="None")
}

///|
test "BufferReader::read_char/single_character" {
  let bytes = Bytes::of_string("A")
  let reader : BufferReader = { bytes, pos: 0 }
  inspect!(reader.read_char(), content="Some('A')")
  inspect!(reader.read_char(), content="None")
}

///|
test "BufferReader::read_char/unicode_surrogate_pair" {
  let bytes = Bytes::of_string("\uD83D\uDE00")
  let reader : BufferReader = { bytes, pos: 0 }
  inspect!(reader.read_char(), content="Some('😀')")
  inspect!(reader.read_char(), content="None")
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

  // 读取第一个UTF-16代码单元（小端序）
  let first_byte = self.bytes[pos]
  let second_byte = self.bytes[pos + 1]
  let first_code = (second_byte.to_int() << 8) | first_byte.to_int()
  if first_code >= 0xD800 && first_code <= 0xDBFF {
    if pos + 3 >= self.bytes.length() {
      return Some('�')
    }

    // 读取第二个UTF-16代码单元（小端序）
    let third_byte = self.bytes[pos + 2]
    let fourth_byte = self.bytes[pos + 3]
    let second_code = (fourth_byte.to_int() << 8) | third_byte.to_int()
    if second_code >= 0xDC00 && second_code <= 0xDFFF {
      let code_point = (0x10000 + ((first_code - 0xD800) << 10)) |
        (second_code - 0xDC00)
      let ch = Char::from_int(code_point)
      return Some(ch)
    }
    return Some('�')
  }

  // 单个UTF-16代码单元
  let ch = Char::from_int(first_code)
  return Some(ch)
}

///|
test "BufferReader::peek_char/normal_case" {
  let buffer = @buffer.new()
  buffer.write_string("Hello")
  let reader = { bytes: buffer.contents(), pos: 0 }
  inspect!(reader.peek_char(), content="Some('H')")
}

///|
test "BufferReader::peek_char/empty_buffer" {
  let buffer = @buffer.new()
  let reader = { bytes: buffer.contents(), pos: 0 }
  inspect!(reader.peek_char(), content="None")
}

///|
test "BufferReader::peek_char/surrogate_pair" {
  let buffer = @buffer.new()
  buffer.write_bytes(Bytes::of_string("💖")) // Valid surrogate pair
  let reader = { bytes: buffer.contents(), pos: 0 }
  inspect!(reader.peek_char(), content="Some('💖')")
}

///|
test "BufferReader::peek_char/ascii_and_position" {
  let buffer = @buffer.new()
  buffer.write_string("ABC")
  let reader = { bytes: buffer.contents(), pos: 0 }
  inspect!(reader.peek_char(), content="Some('A')")
  // Position should not change after peek
  inspect!(reader.peek_char(), content="Some('A')")
  reader.pos = 2
  inspect!(reader.peek_char(), content="Some('B')")
}

///|
test "BufferReader::peek_char/surrogate_pairs" {
  let buffer = @buffer.new()
  buffer.write_string("A🌟B") // A + Surrogate Pair + B
  let reader = { bytes: buffer.contents(), pos: 0 }
  inspect!(reader.peek_char(), content="Some('A')")
  reader.pos = 2 // Position at start of surrogate pair
  inspect!(reader.peek_char(), content="Some('🌟')")
  reader.pos = 6 // Position after surrogate pair
  inspect!(reader.peek_char(), content="Some('B')")
}

///|
test "BufferReader::peek_char/incomplete_data" {
  let buffer = @buffer.new()
  // Write a single byte and a high surrogate without low surrogate
  buffer.write_byte(0x00)
  buffer.write_byte(0xD8) // High surrogate start
  let reader = { bytes: buffer.contents(), pos: 0 }
  inspect!(reader.peek_char(), content="Some('�')")
}

///|
test "BufferReader::peek_char/single_byte_buffer" {
  let buffer = @buffer.new()
  buffer.write_byte(0x41) // 只写入一个字节 'A'
  let reader = { bytes: buffer.contents(), pos: 0 }
  inspect!(reader.peek_char(), content="None") // 应返回None，因为UTF-16至少需要2个字节
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
  let first_byte = self.source[self.pos]
  let second_byte = self.source[self.pos + 1]
  let first_code = (second_byte.to_int() << 8) | first_byte.to_int()
  if first_code >= 0xD800 && first_code <= 0xDBFF {
    if self.pos + 3 >= self.source.length() {
      self.pos += 2
      return Some('�')
    }
    let third_byte = self.source[self.pos + 2]
    let fourth_byte = self.source[self.pos + 3]
    let second_code = (fourth_byte.to_int() << 8) | third_byte.to_int()
    if second_code >= 0xDC00 && second_code <= 0xDFFF {
      let code_point = (0x10000 + ((first_code - 0xD800) << 10)) |
        (second_code - 0xDC00)
      let ch = Char::from_int(code_point)
      self.pos += 4
      return Some(ch)
    }
    self.pos += 2
    return Some('�')
  }
  let ch = Char::from_int(first_code)
  self.pos += 2
  return Some(ch)
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
  let first_byte = self.source[pos]
  let second_byte = self.source[pos + 1]
  let first_code = (second_byte.to_int() << 8) | first_byte.to_int()
  if first_code >= 0xD800 && first_code <= 0xDBFF {
    if pos + 3 >= self.source.length() {
      return Some('�')
    }
    let third_byte = self.source[pos + 2]
    let fourth_byte = self.source[pos + 3]
    let second_code = (fourth_byte.to_int() << 8) | third_byte.to_int()
    if second_code >= 0xDC00 && second_code <= 0xDFFF {
      let code_point = (0x10000 + ((first_code - 0xD800) << 10)) |
        (second_code - 0xDC00)
      let ch = Char::from_int(code_point)
      return Some(ch)
    }
    return Some('�')
  }
  let ch = Char::from_int(first_code)
  return Some(ch)
}

///|
impl CSVReader for BytesReader with is_eof(self) -> Bool {
  self.pos >= self.source.length()
}

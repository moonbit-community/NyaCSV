///|
struct CSVOptions {
  /// 字段分隔符，默认为逗号
  delimiter : Char
  /// 是否允许换行符在引号内
  allow_newlines_in_quotes : Bool
  /// 引号字符
  quote_char : Char
  /// 是否跳过空行
  skip_empty_lines : Bool
  /// 是否忽略行尾空格
  trim_spaces : Bool
}

///|
trait CSVReader {
  read_char(Self) -> Char?
  peek_char(Self) -> Char?
  is_eof(Self) -> Bool
}

///|
struct StringReader {
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
struct BufferReader {
  mut pos : Int
  bytes : Bytes
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
struct BytesReader {
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
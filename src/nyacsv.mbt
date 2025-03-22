///|
/// Represents a CSV (Comma-Separated Values) data structure with headers and
/// rows.
///
/// Parameters:
///
/// * `headers` : An array of strings representing the column names in the CSV.
/// * `rows` : A two-dimensional array where each inner array represents a row of
/// data, with each element corresponding to a column defined in the headers.
///
struct CSV {
  headers : Array[String]
  rows : Array[Array[String]]
}

///|
pub fn CSV::header(self : CSV) -> Array[String] {
  self.headers
}

///|
pub fn CSV::data(self : CSV) -> Array[Array[String]] {
  self.rows
}

///|
pub impl Show for CSV with output(self, logger) -> Unit {
  if self.headers.is_empty() {
    logger.write_string("<Empty CSV>")
  } else {
    let column_widths : Array[Int] = Array::make(self.headers.length(), 0)

    // 计算表头宽度
    for i in 0..<self.headers.length() {
      column_widths[i] = self.headers[i].length()
    }

    // 计算所有行的最大宽度，并替换换行符
    for row in self.rows {
      for i in 0..<@math.minimum(row.length(), self.headers.length()) {
        // 处理字段中的换行符，计算适当的宽度
        let processed_value = row[i].replace(old="\n", new="\\n")
        column_widths[i] = @math.maximum(
          column_widths[i],
          processed_value.length(),
        )
      }
    }

    // 打印表头边框
    logger.write_string("+")
    for width in column_widths {
      logger.write_string("-".repeat(width + 2))
      logger.write_string("+")
    }
    logger.write_string("\n")

    // 打印表头
    logger.write_string("|")
    for i in 0..<self.headers.length() {
      let header = self.headers[i]
      let padding = " ".repeat(column_widths[i] - header.length())
      logger.write_string(" ")
      logger.write_string(header)
      logger.write_string(padding)
      logger.write_string(" |")
    }
    logger.write_string("\n")

    // 打印分隔线
    logger.write_string("+")
    for width in column_widths {
      logger.write_string("-".repeat(width + 2))
      logger.write_string("+")
    }
    logger.write_string("\n")

    // 打印数据行，替换换行符
    for row in self.rows {
      logger.write_string("|")
      for i in 0..<self.headers.length() {
        let raw_value = if i < row.length() { row[i] } else { "" }
        // 将字段内的换行符替换为可视化表示
        let value = raw_value.replace(old="\n", new="\\n")
        let padding = " ".repeat(column_widths[i] - value.length())
        logger.write_string(" ")
        logger.write_string(value)
        logger.write_string(padding)
        logger.write_string(" |")
      }
      logger.write_string("\n")
    }

    // 打印底部边框
    logger.write_string("+")
    for width in column_widths {
      logger.write_string("-".repeat(width + 2))
      logger.write_string("+")
    }
    logger.write_string("\n")
  }
}

///|
test "CSV::output/single_row_no_newline" {
  let csv = {
    headers: ["Name", "Age", "City"],
    rows: [["Alice", "30", "Wonderland"]],
  }
  let logger = @buffer.new()
  csv.output(logger)
  let expected =
    #|+-------+-----+------------+
    #|| Name  | Age | City       |
    #|+-------+-----+------------+
    #|| Alice | 30  | Wonderland |
    #|+-------+-----+------------+
    #|
  inspect!(logger.contents().to_unchecked_string(), content=expected)
}

///|
test "CSV::output/row_with_missing_fields" {
  // 创建一个CSV，其中第二行只有两个字段，少于表头数量
  let csv = {
    headers: ["Name", "Age", "City", "Country"],
    rows: [["Alice", "30", "Wonderland", "Fantasy"], ["Bob", "25"]],
  } // 故意只提供两个字段，少于表头数量
  let logger = @buffer.new()
  csv.output(logger)
  let expected =
    #|+-------+-----+------------+---------+
    #|| Name  | Age | City       | Country |
    #|+-------+-----+------------+---------+
    #|| Alice | 30  | Wonderland | Fantasy |
    #|| Bob   | 25  |            |         |
    #|+-------+-----+------------+---------+
    #|
  inspect!(logger.contents().to_unchecked_string(), content=expected)
}

///|
pub impl Show for CSV with to_string(self) -> String {
  let result = StringBuilder::new()

  // 添加表头
  for i = 0; i < self.headers.length(); i = i + 1 {
    if i > 0 {
      result.write_char(',')
    }
    result.write_string(self.headers[i])
  }
  result.write_char('\n')

  // 添加数据行
  for i = 0; i < self.rows.length(); i = i + 1 {
    let row = self.rows[i]
    for j = 0; j < row.length(); j = j + 1 {
      if j > 0 {
        result.write_char(',')
      }
      result.write_string(row[j])
    }
    result.write_char('\n')
  }
  result.to_string()
}

///|
test "CSV::to_string/single_header_no_rows" {
  let csv = { headers: ["Name"], rows: [] }
  inspect!(csv.to_string(), content="Name\n")
}

///|
test "CSV::to_string/headers_and_rows" {
  let csv = {
    headers: ["Name", "Age", "City"],
    rows: [["John", "25", "New York"], ["Jane", "30", "San Francisco"]],
  }
  let expected =
    #|Name,Age,City
    #|John,25,New York
    #|Jane,30,San Francisco
    #|
  inspect!(csv.to_string(), content=expected)
}

///|
/// Creates a new empty CSV structure with no headers and no rows.
///
/// Returns a new CSV instance with empty headers and rows arrays.
///
pub fn CSV::new() -> CSV {
  let headers : Array[String] = Array::new()
  let rows : Array[Array[String]] = Array::new()
  { headers, rows }
}

///|
test "CSV::new/basic" {
  let csv = CSV::new()
  inspect!(csv.headers, content="[]")
  inspect!(csv.rows, content="[]")
}

///|
pub fn CSV::from_array(
  data : Array[Array[String]],
  has_header~ : Bool = true,
  generate_headers~ : Bool = true
) -> CSV {
  if data.is_empty() {
    CSV::new()
  } else if has_header {
    let headers = data[0]
    let rows = data[1:data.length()].iter().collect()
    { headers, rows }
  } else if generate_headers {
    let column_count = data[0].length()
    let headers = Array::makei(column_count, fn(i) { "column\{i+1}" })
    { headers, rows: data }
  } else {
    let column_count = data[0].length()
    let headers = Array::make(column_count, "")
    { headers, rows: data }
  }
}

///|
/// Parses a CSV (Comma-Separated Values) string into a structured CSV object.
///
/// Parameters:
///
/// * `csv_string` : A string containing CSV data to be parsed.
/// * `options` : A configuration object of type `CSVOptions` that controls the
/// parsing behavior with the following fields:
///  * `delimiter` : The character used to separate fields (default: ',')
///  * `allow_newlines_in_quotes` : Whether to allow newlines within quoted
/// fields (default: true)
///  * `quote_char` : The character used for quoting fields (default: '"')
///  * `skip_empty_lines` : Whether to ignore empty lines in the input (default:
/// true)
///  * `trim_spaces` : Whether to remove leading and trailing whitespace from
/// fields (default: false)
///
/// Returns a `CSV` object containing the parsed data, with headers from the
/// first row and subsequent rows as data.
pub fn CSV::parse_string(
  data : String,
  options~ : CSVOptions = {
    delimiter: ',',
    allow_newlines_in_quotes: true,
    quote_char: '"',
    skip_empty_lines: true,
    trim_spaces: false,
  }
) -> CSV {
  let reader : StringReader = { source: data, pos: 0 }
  CSV::from_array(parse(reader, options~))
}

///|
test "CSV::parse_string/basic_with_quoted_field" {
  let data = "first,last,address,city,zip\nJohn,Doe,120 any st.,\"Anytown, WW\",08123"
  let csv = CSV::parse_string(data)
  inspect!(
    csv.headers,
    content="[\"first\", \"last\", \"address\", \"city\", \"zip\"]",
  )
  inspect!(
    csv.rows,
    content="[[\"John\", \"Doe\", \"120 any st.\", \"Anytown, WW\", \"08123\"]]",
  )

  // 验证引号字段正确解析
  assert_eq!(csv.rows[0][3], "Anytown, WW")
}

///|
test "CSV::parse_string/crlf_with_empty_fields" {
  let data = "a,b,c\r\n1,\"\",\"\"\r\n2,3,4"
  let csv = CSV::parse_string(data)
  inspect!(csv.headers, content="[\"a\", \"b\", \"c\"]")
  inspect!(csv.rows, content="[[\"1\", \"\", \"\"], [\"2\", \"3\", \"4\"]]")

  // 验证空引号字段正确解析为空字符串
  assert_eq!(csv.rows[0][1], "")
  assert_eq!(csv.rows[0][2], "")
}

///|
test "CSV::parse_string/quoted_with_internal_quotes" {
  let data = "a,b\n1,\"ha \"\"ha\"\" ha\"\n3,4\n"
  let csv = CSV::parse_string(data)
  inspect!(csv.headers, content="[\"a\", \"b\"]")
  inspect!(csv.rows, content="[[\"1\", \"ha \\\"ha\\\" ha\"], [\"3\", \"4\"]]")

  // 验证内部引号正确处理
  assert_eq!(csv.rows[0][1], "ha \"ha\" ha")
}

///|
test "CSV::parse_string/quoted_with_internal_quotes" {
  let data = "a,b\n1,\"ha \"\"ha\"\" ha\"\n3,4\n"
  let csv = CSV::parse_string(data)
  inspect!(csv.headers, content="[\"a\", \"b\"]")
  inspect!(csv.rows, content="[[\"1\", \"ha \\\"ha\\\" ha\"], [\"3\", \"4\"]]")

  // 验证内部引号正确处理
  assert_eq!(csv.rows[0][1], "ha \"ha\" ha")
}

///|
test "CSV::parse_string/json_in_field" {
  let data = "key,val\n1,\"{\"\"type\"\": \"\"Point\"\", \"\"coordinates\"\": [102.0, 0.5]}\"\n"
  let csv = CSV::parse_string(data)
  inspect!(csv.headers, content="[\"key\", \"val\"]")
  // 验证JSON字符串被正确解析
  assert_eq!(
    csv.rows[0][1],
    "{\"type\": \"Point\", \"coordinates\": [102.0, 0.5]}",
  )
}

///|
test "CSV::parse_string/special_characters" {
  let data = "Contact Phone Number,Location Coordinates,Cities,Counties\n2095257564,37�36'37.8\"N 121�2'17.9\"W,Modesto,Stanislaus"
  let csv = CSV::parse_string(data)
  inspect!(
    csv.headers,
    content="[\"Contact Phone Number\", \"Location Coordinates\", \"Cities\", \"Counties\"]",
  )
  // 验证特殊字符被正确处理
  assert_eq!(csv.rows[0][1], "37�36'37.8\"N 121�2'17.9\"W")
}

///|
test "CSV::parse_string/multiline_fields_crlf" {
  let data = "a,b,c\r\n1,2,3\r\n\"Once upon \r\na time\",5,6\r\n7,8,9\r\n"
  let csv = CSV::parse_string(data)
  inspect!(csv.headers, content="[\"a\", \"b\", \"c\"]")
  // 验证多行字段正确处理
  assert_eq!(csv.rows[1][0], "Once upon \r\na time")
}

///|
test "CSV::parse_string/multiline_fields_lf" {
  let data = "a,b,c\n1,2,3\n\"Once upon \na time\",5,6\n7,8,9\n"
  let csv = CSV::parse_string(data)
  inspect!(csv.headers, content="[\"a\", \"b\", \"c\"]")

  // 验证LF换行符的多行字段正确处理
  assert_eq!(csv.rows[1][0], "Once upon \na time")
}

///|
test "CSV::parse_string/simple_crlf" {
  let data = "a,b,c\r\n1,2,3\r\n"
  let csv = CSV::parse_string(data)
  inspect!(csv.headers, content="[\"a\", \"b\", \"c\"]")
  inspect!(csv.rows, content="[[\"1\", \"2\", \"3\"]]")
}

///|
test "CSV::parse_string/unicode_characters" {
  let data = "a,b,c\n1,2,3\n4,5,ʤ"
  let csv = CSV::parse_string(data)
  inspect!(csv.headers, content="[\"a\", \"b\", \"c\"]")
  inspect!(csv.rows, content="[[\"1\", \"2\", \"3\"], [\"4\", \"5\", \"ʤ\"]]")

  // 验证Unicode字符正确处理
  assert_eq!(csv.rows[1][2], "ʤ")
}

///|
test "CSV::parse_string/custom_delimiter" {
  let data = "first;last;address\nJohn;Doe;\"120 any st., Anytown\""
  let csv = CSV::parse_string(data, options={
    delimiter: ';',
    allow_newlines_in_quotes: true,
    quote_char: '"',
    skip_empty_lines: true,
    trim_spaces: false,
  })
  inspect!(csv.headers, content="[\"first\", \"last\", \"address\"]")
  inspect!(csv.rows, content="[[\"John\", \"Doe\", \"120 any st., Anytown\"]]")

  // 验证自定义分隔符正确工作
  assert_eq!(csv.rows[0][2], "120 any st., Anytown")
}

///|
/// Parses a buffer containing CSV data into a structured CSV object.
///
/// Parameters:
///
/// * `buffer` : A buffer containing the CSV data to be parsed.
/// * `options` : A configuration object of type `CSVOptions` that controls
/// parsing behavior with the following fields:
///  * `delimiter` : The character used to separate fields (default: ',')
///  * `allow_newlines_in_quotes` : Whether to allow newlines within quoted
/// fields (default: true)
///  * `quote_char` : The character used for quoting fields (default: '"')
///  * `skip_empty_lines` : Whether to ignore empty lines in the input (default:
/// true)
///  * `trim_spaces` : Whether to remove leading and trailing whitespace from
/// fields (default: false)
///
/// Returns a `CSV` object containing the parsed data, with headers from the
/// first row and subsequent rows as data.
pub fn CSV::parse_buffer(
  data : @moonbitlang/core/buffer.T,
  options~ : CSVOptions = {
    delimiter: ',',
    allow_newlines_in_quotes: true,
    quote_char: '"',
    skip_empty_lines: true,
    trim_spaces: false,
  }
) -> CSV {
  let reader : BufferReader = { bytes: data.contents(), pos: 0 }
  CSV::from_array(parse(reader, options~))
}

///|
/// Parses binary data containing CSV content into a structured CSV object.
///
/// Parameters:
///
/// * `data` : A sequence of bytes containing the CSV content to be parsed.
/// * `options` : A configuration object that controls parsing behavior with the
/// following fields:
///  * `delimiter` : The character used to separate fields (default: ',')
///  * `allow_newlines_in_quotes` : Whether to allow newlines within quoted
/// fields (default: true)
///  * `quote_char` : The character used for quoting fields (default: '"')
///  * `skip_empty_lines` : Whether to ignore empty lines in the input (default:
/// true)
///  * `trim_spaces` : Whether to remove leading and trailing whitespace from
/// fields (default: false)
///
/// Returns a `CSV` object containing the parsed data, with headers from the
/// first row and subsequent rows as data.
fn CSV::parse_bytes(
  data : Bytes,
  options~ : CSVOptions = {
    delimiter: ',',
    allow_newlines_in_quotes: true,
    quote_char: '"',
    skip_empty_lines: true,
    trim_spaces: false,
  }
) -> CSV {
  let reader : BytesReader = { source: data, pos: 0 }
  CSV::from_array(parse(reader, options~))
}

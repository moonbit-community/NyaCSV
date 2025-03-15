///|
struct CSV {
  headers : Array[String]
  rows : Array[Array[String]]
}


///|
impl Show for CSV with output(self, logger) -> Unit {
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
impl Show for CSV with to_string(self) -> String {
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
impl ToJson for CSV with to_json(self) -> Json {
  let result_array : Array[Json] = Array::new()
  for row in self.rows {
    let row_obj = Map::new()
    for i in 0..<@math.minimum(row.length(), self.headers.length()) {
      let header = self.headers[i]
      let value = row[i]
      row_obj[header] = String(value)
    }

    // 如果行的字段少于标题数，用 null 填充缺少的字段
    for i in row.length()..<self.headers.length() {
      let header = self.headers[i]
      row_obj[header] = Null
    }
    result_array.push(Object(row_obj))
  }
  Array(result_array)
}

///|
pub fn CSV::new() -> CSV {
  let headers : Array[String] = Array::new()
  let rows : Array[Array[String]] = Array::new()
  { headers, rows }
}

// ///|
// pub fn CSV::parse_string(input : String) -> CSV {
//   let parsed_data = parse_string(input)
//   let csv = CSV::new()
//   if parsed_data.length() > 0 {
//     for item in parsed_data[0] {
//       csv.headers.push(item)
//     }
//     if parsed_data.length() > 1 {
//       for i = 1; i < parsed_data.length(); i = i + 1 {
//         csv.rows.push(parsed_data[i])
//       }
//     }
//   }
//   csv
// }

///|
pub fn CSV::from_json(json : Json) -> Result[CSV, String] {
  match json {
    Json::Array(array) => {
      let csv = CSV::new()
      if array.is_empty() {
        return Ok(csv)
      }
      match array[0] {
        Json::Object(first_obj) => {
          for key in first_obj.keys() {
            csv.headers.push(key)
          }
          for item in array {
            match item {
              Json::Object(obj) => {
                let row : Array[String] = Array::make(csv.headers.length(), "")
                for i in 0..<csv.headers.length() {
                  let key = csv.headers[i]
                  if obj.contains(key) {
                    row[i] = obj[key].to_string()
                  }
                }
                csv.rows.push(row)
              }
              _ => return Err("JSON array contains non-object element")
            }
          }
          Ok(csv)
        }
        _ => Err("First element of JSON array is not an object")
      }
    }
    _ => Err("JSON is not an array")
  }
}

///|
// test {
//   let csv = CSV::parse_string(
//     "key,val\n1,\"{\"\"type\"\": \"\"Point\"\", \"\"coordinates\"\": [102.0, 0.5]}\"\n",
//   )
//   csv |> println
// }

// ///|
// test {
//   let csv = CSV::parse_string("a,b,c\n1,2,3\n4,5,ʤ")
//   csv |> println
// }

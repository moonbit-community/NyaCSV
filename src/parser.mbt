fn parse_csv(input : String) -> Array[Array[String]] {
  let rows : Array[Array[String]] = Array::new()
  let mut row = Array::make(0, "")
  let mut field = StringBuilder::new()
  let mut in_quotes = false
  let mut i = 0
  
  while i < input.length() {
    let ch = input[i]

    // 处理 Windows 格式换行的 \r
    if ch == '\r' {
      i += 1
      continue
    }

    if in_quotes {
      if ch == '"' {
        // 遇到引号，看下一个字符以判断转义或结束
        if i + 1 < input.length() && input[i + 1] == '"' {
          // 连续两个引号，表示数据中的一个引号
          field.write_char('"')
          i += 1 // 跳过转义的第二个引号
        } else {
          // 引号闭合，退出引号模式
          in_quotes = false
        }
      } else {
        // 引号内普通字符，加入当前字段
        field.write_char(ch)
      }
    } else {
      if ch == '"' {
        // 遇到引号，进入引号模式（开始读取引用字段）
        in_quotes = true
      } else if ch == ',' {
        // 遇到分隔符，当前字段结束
        row.push(field.to_string())
        field = StringBuilder::new() // 创建新的字段构建器
      } else if ch == '\n' {
        // 遇到换行且不在引号内，当前记录结束
        row.push(field.to_string())
        
        // 检查是否为有效行（非空或非最后一个换行符）
        if not(row.is_empty()) {
          rows.push(row)
        }
        
        // 重置用于下一行
        row = Array::make(0, "")
        field = StringBuilder::new()
      } else {
        // 普通字符，累积到当前字段
        field.write_char(ch)
      }
    }
    i += 1
  }

  // 循环结束后，加入最后的字段和行（如果有）
  if not(field.is_empty()) {
    row.push(field.to_string())
  }
  if not(row.is_empty()) {
    rows.push(row)
  }
  
  rows
}

test {
  parse_csv("a,b,c\n1,2,3\n4,5,ʤ") |> println
}

/// "first,last,address,city,zip\nJohn,Doe,120 any st.,\"Anytown, WW\",08123"
/// "a,b,c\r\n1,\"\",\"\"\r\n2,3,4"
/// "a,b,c\n1,\"\",\"\"\n2,3,4"
/// "a,b\n1,\"ha \"\"ha\"\" ha\"\n3,4\n"
/// "key,val\n1,\"{\"\"type\"\": \"\"Point\"\", \"\"coordinates\"\": [102.0, 0.5]}\"\n"
/// "Contact Phone Number,Location Coordinates,Cities,Counties\n2095257564,37�36'37.8\"N 121�2'17.9\"W,Modesto,Stanislaus"
/// "a,b,c\r\n1,2,3\r\n\"Once upon \r\na time\",5,6\r\n7,8,9\r\n"
/// "a,b,c\n1,2,3\n\"Once upon \na time\",5,6\n7,8,9\n"
/// "a,b\n1,\"ha \n\"\"ha\"\" \nha\"\n3,4\n"
/// "a,b,c\r\n1,2,3\r\n"
/// "a,b,c\n1,2,3\n"
/// "a,b,c\n1,2,3\n4,5,ʤ"
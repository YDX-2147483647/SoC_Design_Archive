# GPZDA

提取[GPZDA](https://docs.novatel.com/OEM7/Content/Logs/GPZDA.htm)格式的GPS信息。

```
$GPZDA,hhmmss.ss,dd,mm,yyyy,,*hh
```

> 注释里的“轮”指clock。

## `GpsReceiver`

```mermaid
stateDiagram-v2
    [*] --> Prefix
    note right of Prefix: 匹配"$GPZDA,"；<br>任何时候不匹配都回到它。
    
    Prefix --> UTC
    note left of UTC: hhmmss.ss
    UTC --> Day
    note left of Day: dd
    Day --> Month
    note right of Month: mm
    Month --> Year
    note left of Year: yyyy
    Year --> Locale
    note right of Locale: 只支持什么都没有的Locale
    Locale --> Check
    Check --> Output
    Output --> Prefix
```

## `Comparer`

这是异步的，匹配完成后的下一clock才有反馈。

```mermaid
stateDiagram-v2
    [*] --> Pending
    
    Pending --> Pending
    Pending --> Reject : 中道崩殂
    Pending --> Resolve : full match
    
    Reject --> Pending
    Reject --> Reject : 中道崩殂
    Resolve --> Pending
    Resolve --> Resolve : full match
```

### `ComparerSync`

类似`Comparer`，但匹配完成的那一个clock就会反馈。

不是FSM，要不然做不到即时。

```mermaid
flowchart LR
    subgraph input
        restart
        load
        data
    end
    
    prev[[prev_match_count]] --> prev_qr[prev_match_count_qr]
    restart --> prev_qr
    
    prev_qr --> is_match
    data --> is_match
    
    prev_qr --> match_count
    load --> match_count
    is_match --> match_count
    
    load -.-> prev
    is_match -.-> prev
    match_count -.-> prev
    data -.-> prev
    
    match_count --> resolve
    is_match --> reject
    load --> reject
    
    subgraph output
        resolve
        reject
    end
```

> 双线框代表`reg`，单线框代表`wire`；实线代表`=`，虚线代表`=>`。

